/*
 * Copyright (C) 2015 - Holy Lobster
 *
 * Nuntius is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * Nuntius is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Nuntius. If not, see <http://www.gnu.org/licenses/>.
 */

namespace Nuntius {

[DBus (name = "org.bluez.Device1")]
public interface BluezDeviceBus : Object {
    public abstract async void connect_profile(string UUID) throws DBusError, IOError;
    public abstract void disconnect_profile(string UUID) throws DBusError, IOError;

    public abstract string name { owned get; }
    public abstract bool paired { owned get; }
    public abstract string[] uuids { owned get; }
}

[DBus (name = "org.bluez.ProfileManager1")]
public interface BluezProfileManager : Object {
    public abstract void register_profile(ObjectPath profile, string uuid, HashTable<string, Variant> options) throws IOError;

    public abstract void unregister_profile(ObjectPath profile) throws IOError;
}

public class Connections : Object {
    private HashTable<string, Connection>? connections;

    construct {
        connections = new HashTable<string, Connection>(str_hash, str_equal);
    }

    public void add_connection(Connection connection) {
        connections.insert(connection.server_name, connection);
        connection.notify["connected"].connect(() => {
            if (!connection.connected) {
                connections.remove(connection.server_name);
                print("removed connection for device '%s'\n",
                      connection.server_name);
            }
        });

        connection.notification_posted.connect((notification) => {
            var app = GLib.Application.get_default();
            (app as Application).add_notification(notification);
        });

        connection.notification_removed.connect((id, package_name) => {
            var app = GLib.Application.get_default();
            (app as Application).mark_notification_read(id, package_name);
        });
    }

    public void remove_connection(string server_name) {
        var connection = connections.lookup(server_name);
        if (connection != null) {
            connections.remove(server_name);
        }
    }

    public bool is_connected() {
        return connections.size() > 0;
    }

    public bool get_connected(string server_name) {
        return connections.get(server_name) != null;
    }
}

[DBus (name = "org.bluez.Profile1")]
public class BluezProfile : Object {
    private Connections connections;

    public BluezProfile(Connections connections) {
        this.connections = connections;
    }

    public void release() {
        print("release method called\n");
    }

    public void new_connection(ObjectPath device, Socket socket, HashTable<string, Variant> fd_properties) {
        print("new_connection method called for device: %s\n", device);
        var connection = new Connection(device,
                                        SocketConnection.factory_create_connection(socket));

        connections.add_connection(connection);
    }

    public void request_disconnection(ObjectPath device) {
        print("request_disconnection method called for devices: %s\n", device);

        connections.remove_connection(device);
    }
}

public class Application : Gtk.Application {
    private Cancellable? cancellable;
    private Connections connections;
    private DBusObjectManager manager;
    private BluezProfileManager? profile_manager;
    private BluezProfile? profile;
    private uint connect_devices_id;
    private bool first_activation;
    private bool cert_created;
    private Window window;
    private List<NotificationApp> _notification_apps;
    private string connect_host;
    private TlsCertificate? cert;

    private const GLib.ActionEntry[] app_entries = {
        { "about", on_about_activate }
    };

    private const OptionEntry[] options = {
        {"connect", '\0', 0, OptionArg.STRING, null,
         N_("Connect to a specifi server"), null},
        {null}
    };

    public signal void notification_app_added(NotificationApp notification_app);

    public List<NotificationApp> notification_apps {
        get { return _notification_apps; }
    }

    public Application() {
        Object(application_id: "org.holylobster.nuntius",
               flags: ApplicationFlags.HANDLES_COMMAND_LINE);
        add_main_option_entries(options);
    }

    construct {
        cancellable = new Cancellable();
        cert_created = false;
        first_activation = true;
        _notification_apps = new List<NotificationApp>();
    }

    protected override void dispose() {
        if (cancellable != null) {
            cancellable.cancel();
            cancellable = null;
        }

        if (connect_devices_id != 0) {
            Source.remove(connect_devices_id);
            connect_devices_id = 0;
        }

        base.dispose();
    }

    protected override void startup() {
        base.startup();

        // Since it works as a daemon keep a hold forever on the primary instance
        hold();

        add_action_entries(app_entries, this);

        var css_provider = new Gtk.CssProvider();
        try {
            var file = File.new_for_uri("resource:///org/holylobster/nuntius/css/nuntius-style.css");
            css_provider.load_from_file(file);
        } catch (Error e) {
            warning("loading css: %s", e.message);
        }
        Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(),
                                                 css_provider,
                                                 Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        connections = new Connections();
        profile = new BluezProfile(connections);

        var profile_path = new ObjectPath(get_dbus_object_path() + "/Profile");

        try {
            var conn = Bus.get_sync(BusType.SYSTEM);
            conn.register_object(profile_path, profile);

            profile_manager = Bus.get_proxy_sync(BusType.SYSTEM, "org.bluez", "/org/bluez");
            print("obtained bluez profile manager\n");

            var options = new HashTable<string, Variant>(str_hash, str_equal);
            options.insert("Role", new Variant.string("client"));

            profile_manager.register_profile(profile_path, "00001101-0000-1000-8000-00805f9b34fb", options);
            print("profile registered\n");

            manager = new DBusObjectManagerClient.for_bus_sync(BusType.SYSTEM, DBusObjectManagerClientFlags.NONE,
                                                               "org.bluez", "/", null, null);
            print("obtained bluez proxy\n");

            handle_managed_objects.begin(true);

            // check interfaces added dynamically
            manager.interface_added.connect(interface_added);
            manager.interface_removed.connect(interface_removed);
        } catch (Error e) {
            warning("%s", e.message);
        }

        create_cert();
    }

    private void ensure_window() {
        if (window == null) {
            window = new Window(this);
            window.destroy.connect(() => {
                window = null;
            });
        }
    }

    private string? spawn_command(string[] args) {
        try {
            string[] spawn_args = args;
            string[] spawn_env = Environ.get ();
            string ls_stdout;
            string ls_stderr;
            int ls_status;

            Process.spawn_sync (".",
                                spawn_args,
                                spawn_env,
                                SpawnFlags.SEARCH_PATH,
                                null,
                                out ls_stdout,
                                out ls_stderr,
                                out ls_status);
            return ls_stdout;

        } catch (SpawnError e) {
            stdout.printf ("Error: %s\n", e.message);
            return null;
        }
    }

    private void create_cert() {
        var path_to_conf = GLib.Path.build_filename(GLib.Environment.get_user_config_dir(), "nuntius");
        var file = File.new_for_path (GLib.Path.build_filename(path_to_conf, "nuntius.pem"));
        if (!file.query_exists ()) {
            string[] spawn_args = {"./createcert.sh"};
            spawn_command(spawn_args);
            cert_created = true;
        }
        try {
            cert = new TlsCertificate.from_files (GLib.Path.build_filename(path_to_conf, "nuntius.pem"), GLib.Path.build_filename(path_to_conf, "nuntius.key"));
        } catch (Error e) {
            warning("Failed to load certificate: %s", e.message);
        }
    }

    private string get_fingerprint() {
        string path_to_pem = GLib.Path.build_filename(GLib.Environment.get_user_config_dir(), "nuntius/nuntius.pem");
        string[] spawn_args = {"openssl", "x509", "-in", path_to_pem, "-fingerprint", "-sha1"};
        string result = spawn_command(spawn_args); 
        string[] splitted = result.split("=");
        splitted = splitted[1].split("\n");
        string fingerprint = splitted[0];
        return fingerprint;
    }

    private string get_hostname() {
        string[] spawn_args = {"hostname"};
        string hostname = spawn_command(spawn_args); 
        return hostname;
    }

    private void show_qrcode() {
        var dialog = new Gtk.Dialog.with_buttons ("Certificate fingerprint",
                                       window,
                                       Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT,
                                       _("_OK"),
                                       Gtk.ResponseType.OK);
        dialog.border_width = 30;
        dialog.set_default_size(300, 300);
        dialog.destroy.connect(Gtk.main_quit);

        dialog.response.connect(i => {
            window.destroy();
        });

        var qr = new Nuntius.QRImage();
        qr.text = get_fingerprint() + "-" + get_hostname();
        qr.show();

        dialog.get_content_area().pack_end(qr, true, true, 0);
        dialog.show();
    }

    protected override void activate() {
        // We want it to start as a daemon and not showing the window from
        // the beginning
        if (cert_created) {
            ensure_window();
            window.present();
            show_qrcode();
        } else if (!first_activation) {
            ensure_window();
            window.present();
        }


        first_activation = false;

        if (connect_host != null && cert != null) {
            var host = connect_host;
            var client = new SocketClient();

            client.tls = true;
            client.event.connect(on_socket_client_event);
            client.connect_to_host_async.begin(connect_host, 12233, cancellable, (obj, res) => {
                try {
                    var connection = client.connect_to_host_async.end(res);
                    warning("connect ok");
                    connections.add_connection(new Connection(host, connection));
                } catch (Error e) {
                    warning("Could not connect to server: %s", connect_host);
                }
            });
        }

        base.activate();
    }

    // FIXME: this cannot be a lambda, since for now vala does not realize SocketConnectable is nullable
    private void on_socket_client_event(SocketClientEvent event, SocketConnectable? connectable, IOStream? ios) {
        if (event == SocketClientEvent.TLS_HANDSHAKING) {
            warning("TLS_HANDSHAKING");
            var tls = (TlsConnection) ios;
            tls.accept_certificate.connect((cert, err) => {
                return true;
            });
            tls.set_certificate(cert);
        }
    }

    protected override int command_line(ApplicationCommandLine cl) {
        var dict = cl.get_options_dict();

        dict.lookup("connect", "s", out connect_host);
        activate();
        connect_host = null;

        return 0;
    }

    private async void connect_interface(DBusObject object, DBusInterface iface, bool dump) {
        if (!(iface is DBusProxy)) {
            return;
        }

        var name = (iface as DBusProxy).get_interface_name();
        var path = new ObjectPath(object.get_object_path());

        if (dump) {
            if (!name.has_prefix("org.freedesktop.DBus")) {
                print("added: [%s]\n", path);
                print("  %s\n", name);
            }
        }

        // try to get the device
        if (name == "org.bluez.Device1" && !connections.get_connected(path)) {
            try {
                BluezDeviceBus device = Bus.get_proxy_sync(BusType.SYSTEM, "org.bluez", path);

                if (device.paired) {
                    print("connect device: %s\n", device.name);
                    try {
                        yield device.connect_profile("00001101-0000-1000-8000-00805f9b34fb");
                    } catch (Error e) {
                        warning("Error connecting to device '%s': %s", device.name, e.message);
                    }
                }
            } catch (Error e) {
                warning("%s", e.message);
            }
        }
    }

    private void interface_added(DBusObjectManager manager, DBusObject object, DBusInterface iface) {
        connect_interface.begin(object, iface, true);
    }

    private void interface_removed(DBusObjectManager manager, DBusObject object, DBusInterface iface) {
        print("removed: [%s]\n", object.get_object_path());
        print("  %s\n", iface.get_info().name);
    }

    private async void handle_managed_objects(bool dump) {
        var objects = manager.get_objects();

        foreach (DBusObject o in objects) {
            foreach (DBusInterface iface in o.get_interfaces()) {
                yield connect_interface(o, iface, dump);
            }
        }

        if (!connections.is_connected()) {
            // try to connect to the paired device every few seconds
            connect_devices_id = Timeout.add_seconds(5, on_try_to_connect_devices);
        }
    }

    private bool on_try_to_connect_devices() {
        connect_devices_id = 0;
        handle_managed_objects.begin(false);

        return false;
    }

    private void on_about_activate() {
        const string copyright = "Copyright \xc2\xa9 2015 Holy Lobster Team";

        const string authors[] = {
            "Andrea Curtoni <andrea.curtoni@gmail.com>",
            "Ignacio Casal Quinteiro <icq@gnome.org>",
            "Paolo Borelli <pborelli@gnome.org>",
            null
        };

        Gtk.show_about_dialog(window,
                              "program-name", _("Nuntius"),
                              "logo-icon-name", "nuntius",
                              "version", Config.VERSION,
                              "comments", _("Deliver notifications from your phone or tablet to your computer over Bluetooth."),
                              "copyright", copyright,
                              "authors", authors,
                              "license-type", Gtk.License.GPL_2_0,
                              "wrap-license", false,
                              "translator-credits", _("translator-credits"),
                              null);
    }

    public void add_notification(Notification notification) {
        bool found = false;

        foreach (var napp in _notification_apps) {
            if (napp.id == notification.package_name) {
                napp.add_notification(notification);
                found = true;
                break;
            }
        }

        if (!found) {
            var napp = new NotificationApp(notification.package_name);
            napp.add_notification(notification);
            _notification_apps.prepend(napp);

            notification_app_added(napp);
        }

        send_notification(notification.id,
                          notification.to_gnotification());
    }

    public void mark_notification_read(string id, string package_name) {
        Notification? notification = null;

        foreach (var napp in _notification_apps) {
            if (napp.id == package_name) {
                notification = napp.get_notification(id);
                break;
            }
        }

        if (notification != null) {
            withdraw_notification(notification.id);
            notification.read = true;
        }
    }
}

} // namespace Nuntius

/* ex:set ts=4 et: */
