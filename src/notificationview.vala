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

public class NotificationView : Gtk.Window {

    Notification notification;

    public NotificationView(Notification notification) {
        this.notification = notification;

        // Sets the title of the Window:
        this.title = notification.title;

        // Center window at startup:
        this.window_position = Gtk.WindowPosition.CENTER;

        // Sets the default size of a window:
        this.set_default_size(500,150);

        // Whether the titlebar should be hidden during maximization.
        this.hide_titlebar_when_maximized = false;

        // Method called on pressing [X]
        this.destroy.connect(() => {
            // Print "Bye!" to our console:
            stdout.printf("Bye!\n");

        });

        Gtk.Box vertical_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        vertical_box.set_margin_left(20);
        vertical_box.set_margin_right(20);
        this.add(vertical_box);

        Gtk.Box notification_area = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
        vertical_box.pack_start(notification_area);

        Gtk.Image icon = new Gtk.Image();
        icon.set_from_gicon(notification.icon, Gtk.IconSize.DIALOG);
        notification_area.pack_start(icon);

        var label = new Gtk.Label(notification.body);
        notification_area.pack_start(label);


        Gtk.Box button_area = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
        vertical_box.pack_start(button_area, false, false, 10);
        var dismiss_button = new Gtk.Button.with_label("Dismiss");

        dismiss_button.clicked.connect(() => {
            notification.send_dismiss_message();
        });

        button_area.pack_start(dismiss_button);

        if (notification.actions != null) {
            var actions = notification.actions;
            foreach(string s in actions) {
                var action_button = new Gtk.Button.with_label(s);
                button_area.pack_start(action_button);
                action_button.clicked.connect(() => {
                    notification.send_action_message(s);
                });
            }
        }

        var blacklist_button = new Gtk.Button.with_label("Blacklist this app");

        blacklist_button.clicked.connect(() => {
            Json.Builder builder = new Json.Builder();
            builder.begin_object();
            builder.set_member_name("event");
            builder.add_string_value("blacklist");
            builder.set_member_name("app");
            builder.begin_object();

            builder.set_member_name("packageName");
            builder.add_string_value(notification.package_name);

            builder.end_object();
            builder.end_object();

            Json.Generator generator = new Json.Generator();
            Json.Node root = builder.get_root();
            generator.set_root(root);
            string blaclist_message = generator.to_data(null);
            notification.connection.send_message(blaclist_message);
        });
        button_area.pack_start(blacklist_button);
    }
}

}
