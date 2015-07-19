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

public class SmsNotification : Object {
    public string id { get; construct set; }
    public string sender { get; construct set; }
    public string sender_num { get; construct set; }
    public string message { get; construct set; }
    public BytesIcon icon { get; construct set; }
    public Client client { get; construct set; }

    public SmsNotification(Client client, string id, string sender, string sender_num, string message, BytesIcon icon) {
        Object(client: client, id: id, sender: sender, sender_num: sender_num, message: message, icon: icon);
    }

    public void send_sms_message(string message) {
        Json.Builder builder = new Json.Builder();
        builder.begin_object();
        builder.set_member_name("event");
        builder.add_string_value("sms");
        builder.set_member_name("sms");
        builder.begin_object();

        builder.set_member_name("senderNum");
        builder.add_string_value(_sender_num);

        builder.set_member_name("msg");
        builder.add_string_value(message);

        builder.end_object();
        builder.end_object();

        Json.Generator generator = new Json.Generator();
        Json.Node root = builder.get_root();
        generator.set_root(root);
        string sms_message = generator.to_data(null);
        client.send_message(sms_message);
    }

    public GLib.Notification to_gnotification() {
        GLib.Notification notification = new GLib.Notification(sender);

        notification.set_body(message);
        notification.set_icon(icon);

        // FIXME: just a test message until we have UI to type the reply
        var variant = new Variant("(ss)", id, "Sent by Nuntius");
        notification.add_button_with_target_value(_("Reply"),"app.send-sms", variant);

        return notification;
    }
}

}
