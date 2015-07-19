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

public class Notification : Object {
    public string id { get; construct set; }
    public string package_name { get; construct set; }
    public string app_name { get; construct set; }
    public string title { get; construct set; }
    public string body { get; construct set; }
    public string? flag { get; construct set; }
    public string? key { get; construct set; }
    public BytesIcon icon { get; construct set; }
    public string[]? actions { get; construct set; }
    public Client client { get; construct set; }

    private bool _read;

    [CCode (notify = false)]
    public bool read {
        get { return _read; }
        set {
            if (_read != value) {
                _read = value;
                notify_property("read");
            }
        }
        default = false;
    }

    public Notification(Client client, string id, string package_name, string app_name, string title, string? flag, string? key, string? body, BytesIcon? icon, string[]? actions) {
        Object(client: client, id: id, package_name: package_name, app_name: app_name, title: title, flag: flag, key: key, body: body, icon: icon, actions: actions);
    }

    public void send_dismiss_message() {
        Json.Builder builder = new Json.Builder();
        builder.begin_object();
        builder.set_member_name("event");
        builder.add_string_value("dismiss");
        builder.set_member_name("notification");
        builder.begin_object();

        if (key != null){
            builder.set_member_name("key");
            builder.add_string_value(_key);
        } else {
            builder.set_member_name("packageName");
            builder.add_string_value(_package_name);
            builder.set_member_name("flag");
            builder.add_string_value(_flag);
            builder.set_member_name("id");
            builder.add_string_value(_id);
        }
        builder.end_object();
        builder.end_object();

        Json.Generator generator = new Json.Generator();
        Json.Node root = builder.get_root();
        generator.set_root(root);
        string dismiss_message = generator.to_data(null);
        client.send_message(dismiss_message);
    }

    public void send_action_message(string s) {
        Json.Builder builder = new Json.Builder();
        builder.begin_object();
        builder.set_member_name("event");
        builder.add_string_value("action");
        builder.set_member_name("action");
        builder.begin_object();

        builder.set_member_name("key");
        builder.add_string_value(_key);
        builder.set_member_name("actionName");
        builder.add_string_value(s);

        builder.end_object();
        builder.end_object();

        Json.Generator generator = new Json.Generator();
        Json.Node root = builder.get_root();
        generator.set_root(root);
        string action_message = generator.to_data(null);
        client.send_message(action_message);
    }

    public GLib.Notification to_gnotification() {
        GLib.Notification notification = new GLib.Notification(title);

        if (body != null) {
            notification.set_body(body);
        }

        if (icon != null) {
            notification.set_icon(icon);
        }

        var variant = new Variant("(ss)", id, package_name);
        notification.set_default_action_and_target_value("app.open-notifications-view", variant);

        return notification;
    }
}

} // namespace Nuntius

/* ex:set ts=4 et: */
