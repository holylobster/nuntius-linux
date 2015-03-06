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

[DBus (name = "org.freedesktop.DBus.ObjectManager")]
public interface DBusObjectManager : Object {
    public abstract HashTable<ObjectPath, HashTable<string, HashTable<string, Variant>>> get_managed_objects() throws DBusError, IOError;

    public signal void interfaces_added(ObjectPath path, HashTable<string, HashTable<string, Variant>> interfaces);
    public signal void interfaces_removed(ObjectPath path,  string[] interfaces);
}

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
    }

    public void request_disconnection(ObjectPath device) {
        print("request_disconnection method called for devices: %s\n", device);

        var device_connection = connections.lookup(device);
        if (device_connection != null) {
            connections.remove(device);
        }
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

            manager = Bus.get_proxy_sync(BusType.SYSTEM, "org.bluez", "/");
            print("obtained bluez proxy\n");

            handle_managed_objects(true);

            // check interfaces added dynamically
            manager.interfaces_added.connect(interfaces_added);
            manager.interfaces_removed.connect(interfaces_removed);
        } catch (Error e) {
            warning("%s", e.message);
        }
    }

    protected override void activate() {
        base.activate();
    }

    private async void connect_interfaces(ObjectPath path, HashTable<string, HashTable<string, Variant>> interfaces, bool dump) {
        if (dump) {
            print("added: [%s]\n", path);
            interfaces.foreach((iface, props) => {
                if (iface.has_prefix("org.freedesktop.DBus")) {
                    // skip dbus stuff
                    return;
                }

                print("  %s\n", iface);
                props.foreach((key, val) => {
                    print("     %s: %s\n", key, val.print(false));
                });
            });
        }

        // try to get the device
        if (interfaces.get("org.bluez.Device1") != null && !profile.get_device_connected(path)) {
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

    private void interfaces_added(ObjectPath path, HashTable<string, HashTable<string, Variant>> interfaces) {
        connect_interfaces(path, interfaces, true);
    }

    private void interfaces_removed(ObjectPath path,  string[] interfaces) {
        print("removed: [%s]\n", path);
        foreach (var iface in interfaces) {
            print("  %s\n", iface);
        }
    }

    private void handle_managed_objects(bool dump) {
        try {
            var objects = manager.get_managed_objects();

            objects.foreach((path, ifaces) => {
                connect_interfaces(path, ifaces, dump);
            });
        } catch (Error e) {
            warning("%s", e.message);
        }

        // try to connect to the paired device every few seconds
        connect_devices_id = Timeout.add_seconds(5, on_try_to_connect_devices);
    }

    private bool on_try_to_connect_devices() {
        connect_devices_id = 0;
        handle_managed_objects(false);

        return false;
    }
}

} // namespace Nuntius

/* ex:set ts=4 et: */
