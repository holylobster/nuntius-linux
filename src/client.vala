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

public enum TcpConnectionStatus {
    DISCONNECTED,
    CONNECTING,
    CONNECTED
}

public class Client : Object {
    private Cancellable cancellable;
    private SocketConnection? _connection;
    private DataInputStream? input;
    private DataOutputStream? output;

    public SocketConnection? socket {
        get { return _connection; }
        set {
            _connection = value;
            input = new DataInputStream(_connection.get_input_stream());
            input.set_newline_type(DataStreamNewlineType.CR_LF);
            output = new DataOutputStream(_connection.get_output_stream());
            read_message();
        }
    }

    public TcpConnectionStatus tcp_status { get; construct set; default = TcpConnectionStatus.DISCONNECTED; }
    public string host { get; construct set; }
    public uint16 port { get; set; }

    public signal void notification_posted(Notification notification);

    public signal void sms_received(SmsNotification notification);

    public signal void notification_removed(string id, string package_name);

    private Client();

    public Client.lan(string host, uint16 port) {
        Object(host: host);
        this.port = port;
    }

    public Client.blue(string host, SocketConnection socketConnection) {
        Object(host: host, socket: socketConnection);

        input = new DataInputStream(_connection.get_input_stream());
        input.set_newline_type(DataStreamNewlineType.CR_LF);
        output = new DataOutputStream(_connection.get_output_stream());
        read_message();
    }

    construct {
        cancellable = new Cancellable();
    }

    protected override void dispose() {
        if (cancellable != null) {
            cancellable.cancel();
            cancellable = null;
        }

        input = null;
        output = null;
        _connection = null;

        base.dispose();
    }

    public void send_message(string msg) {
        try {
            output.put_string(msg + "\n");
        } catch (Error e) {
            print("Couldn't send message to " + host);
        }
        print(msg);
    }

    void read_message() {
        input.read_line_async.begin(Priority.DEFAULT, cancellable, (obj, res) => {
            try {
                string notification_json = input.read_line_async.end(res);
                if (notification_json != null) {
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
                            string? key = null;

                            var object = i.get_object();
                            var id = object.get_int_member("id").to_string();
                            var package_name = object.get_string_member("packageName");
                            var app_name = object.get_string_member("appName");

                            BytesIcon icon = null;
                            if (object.has_member("icon")) {
                                icon = new BytesIcon(new Bytes(Base64.decode(object.get_string_member("icon"))));
                            }

                            if (object.has_member("key")) {
                                key = object.get_string_member("key");
                            }

                            var notification_object = object.get_object_member("notification");
                            if (notification_object.has_member("title")) {
                                var title = notification_object.get_string_member("title");
                                string? text = null;
                                string? flags = null;
                                string[]? actions_string = null;

                                if (notification_object.has_member("flags")) {
                                    flags = notification_object.get_string_member("flags");
                                }

                                if (notification_object.has_member("text")) {
                                    text = notification_object.get_string_member("text");
                                }

                                if (notification_object.has_member("actions")) {
                                    var actions = notification_object.get_array_member("actions").get_elements();
                                    var number_of_actions = notification_object.get_array_member("actions").get_length();
                                    actions_string = new string[number_of_actions];
                                    var count = 0;
                                    foreach (var action in actions) {
                                        actions_string[count] = action.get_object().get_string_member("title");
                                        count++;
                                    }
                                }
                                notification = new Notification(this, id, package_name, app_name, title, flags, key, text, icon, actions_string);

                                notification_posted(notification);
                            }
                        }
                        break;
                    case "notificationRemoved":
                        foreach (var i in eventItems) {
                            var object = i.get_object();
                            var id = object.get_int_member("id").to_string();
                            var package_name = object.get_string_member("packageName");
                            notification_removed(id, package_name);
                        }
                        break;
                    case "listNotifications":
                        break;
                    case "sms":
                        foreach (var i in eventItems) {
                            var object = i.get_object();
                            string? id = null;
                            string? sender = null;
                            string? sender_num = null;
                            string? msg = null;
                            BytesIcon? icon = null;

                            if (object.has_member("id")) {
                                id = object.get_string_member("id");
                            }

                            if (object.has_member("sender")) {
                                sender = object.get_string_member("sender");
                            }

                            if (object.has_member("sender_num")) {
                                sender_num = object.get_string_member("sender_num");
                            }

                            if (object.has_member("message")) {
                                msg = object.get_string_member("message");
                            }

                            if (object.has_member("icon")) {
                                icon = new BytesIcon(new Bytes(Base64.decode(object.get_string_member("icon"))));
                            }
                            SmsNotification notification = new SmsNotification(this, id, sender, sender_num, msg, icon);
                            sms_received(notification);
                        }
                        break;
                    default:
                        warning("Unknown event: %s", event);
                        break;
                    }
                    /* read the next message */
                    read_message();
                } else {
                    tcp_status = TcpConnectionStatus.DISCONNECTED;
                    print("client %s disconnected\n", host);
                }
            } catch (IOError e) {
                warning("There was a problem reading the notification: %s",
                        e.message);
                tcp_status = TcpConnectionStatus.DISCONNECTED;
            }
        });
    }
}

} // namespace Nuntius

/* ex:set ts=4 et: */
