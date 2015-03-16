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

public class DeviceConnection : Object {
    Cancellable cancellable;
    Socket socket;
    SocketConnection? connection;
    DataInputStream? input;
    bool _connected;
    ObjectPath _device;

    public bool connected {
        get { return _connected; }
        set { _connected = value; }
    }

    public ObjectPath device {
        get { return _device; }
    }

    public signal void notification_posted(Notification notification);

    public signal void notification_removed(string id);

    public DeviceConnection(ObjectPath device, Socket socket) {
        cancellable = new Cancellable();
        this.socket = socket;
        _connected = true;
        _device = device;

        connection = SocketConnection.factory_create_connection(socket);
        input = new DataInputStream(connection.get_input_stream());
        input.set_newline_type(DataStreamNewlineType.CR_LF);

        read_message();
    }

    protected override void dispose() {
        if (cancellable != null) {
            cancellable.cancel();
            cancellable = null;
        }

        input = null;
        connection = null;

        base.dispose();
    }

    void read_message() {
        input.read_line_async.begin(Priority.DEFAULT, cancellable, (obj, res) => {
            try {
                string notification_json = input.read_line_async.end(res);

                print("Got the json message: %s\n", notification_json);

                var parser = new Json.Parser();
                try {
                    parser.load_from_data(notification_json, -1);
                } catch (Error e) {
                    warning("There was a problem parsing the notification data: %s",
                            e.message);
                    read_message();
                    return;
                }

                var event = parser.get_root().get_object().get_string_member("event");
                var eventItems = parser.get_root().get_object().get_array_member("eventItems").get_elements();

                switch (event) {
                case "deviceConnected":
                    foreach (var i in eventItems) {
                        var object = i.get_object();
                        var name = object.get_string_member("name");
                        print("Device '%s' connected\n", name);
                    }
                    break;
                case "notificationPosted":
                    foreach (var i in eventItems) {
                        Notification? notification = null;

                        var object = i.get_object();
                        var id = object.get_int_member("id").to_string();
                        var package_name = object.get_string_member("packageName");
                        var app_name = object.get_string_member("appName");

                        BytesIcon icon = null;
                        if (object.has_member("icon")) {
                            icon = new BytesIcon(new Bytes(Base64.decode(object.get_string_member("icon"))));
                        }

                        var notification_object = object.get_object_member("notification");
                        if (notification_object.has_member("title")) {
                            var title = notification_object.get_string_member("title");
                            string? text = null;

                            if (notification_object.has_member("text")) {
                                text = notification_object.get_string_member("text");
                            }

                            notification = new Notification(id, package_name, app_name, title, text, icon);

                            notification_posted(notification);
                        }
                    }
                    break;
                case "notificationRemoved":
                    foreach (var i in eventItems) {
                        var object = i.get_object();
                        var id = object.get_int_member("id").to_string();

                        notification_removed(id);
                    }
                    break;
                case "listNotifications":
                    break;
                default:
                    warning("Unknown event: %s", event);
                    break;
                }
                /* read the next message */
                read_message();
            } catch (IOError e) {
                warning("There was a problem reading the notification: %s",
                        e.message);
                connected = false;
            }
        });
    }
}

} // namespace Nuntius

/* ex:set ts=4 et: */
