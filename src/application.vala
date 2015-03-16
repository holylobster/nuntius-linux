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

[DBus (name = "org.bluez.Profile1")]
public class BluezProfile : Object {
    HashTable<ObjectPath, DeviceConnection>? connections;

    public BluezProfile(Cancellable cancellable) {
        connections = new HashTable<ObjectPath, DeviceConnection>(str_hash, str_equal);

        cancellable.connect(() => {
            connections.remove_all();
        });
    }

    public void release() {
        print("release method called\n");
    }

    public void new_connection(ObjectPath device, Socket socket, HashTable<string, Variant> fd_properties) {
        print("new_connection method called for device: %s\n", device);
        var connection = new DeviceConnection(device, socket);

        connections.insert(device, connection);
        connection.notify["connected"].connect(() => {
            if (!connection.connected) {
                connections.remove(connection.device);
                print("removed connection for device '%s'\n", connection.device);
            }
        });

        connection.notification_posted.connect((notification) => {
            var app = GLib.Application.get_default();
            app.send_notification(notification.id,
                                  notification.to_gnotification());
        });

        connection.notification_removed.connect((id) => {
            var app = GLib.Application.get_default();
            app.withdraw_notification(id);
        });
    }

    public void request_disconnection(ObjectPath device) {
        print("request_disconnection method called for devices: %s\n", device);

        var device_connection = connections.lookup(device);
        if (device_connection != null) {
            connections.remove(device);
        }
    }

    public bool has_any_device_connected() {
        return connections.size() > 0;
    }

    public bool get_device_connected(ObjectPath device) {
        return connections.get(device) != null;
    }
}

public class Application : GLib.Application {
    Cancellable? cancellable;
    DBusObjectManager manager;
    BluezProfileManager? profile_manager;
    BluezProfile? profile;
    uint connect_devices_id;

    public Application() {
        Object(application_id: "org.holylobster.nuntius");
    }

    construct {
        cancellable = new Cancellable();
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

        profile = new BluezProfile(cancellable);

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
    }

    protected override void activate() {
        base.activate();
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
        if (name == "org.bluez.Device1" && !profile.get_device_connected(path)) {
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

        if (!profile.has_any_device_connected()) {
            // try to connect to the paired device every few seconds
            connect_devices_id = Timeout.add_seconds(5, on_try_to_connect_devices);
        }
    }

    private bool on_try_to_connect_devices() {
        connect_devices_id = 0;
        handle_managed_objects.begin(false);

        return false;
    }
}

} // namespace Nuntius

/* ex:set ts=4 et: */
