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

[GtkTemplate (ui = "/org/holylobster/nuntius/ui/window.ui")]
public class Window : Gtk.ApplicationWindow {
    [GtkChild]
    private AppsListPanel apps_list_panel;
    [GtkChild]
    private NotificationsView notifications_view;
    [GtkChild]
    private Gtk.HeaderBar titlebar_right;

    private GLib.Settings settings;

    public Window(Application app) {
        Object(application: app);
    }

    construct {
        settings = new Settings("org.holylobster.nuntius.state.window");
        settings.delay ();

        destroy.connect(() => {
            settings.apply();
        });

        // Setup window geometry saving
        Gdk.WindowState window_state = (Gdk.WindowState)settings.get_int("state");
        if (Gdk.WindowState.MAXIMIZED in window_state) {
            maximize();
        }

        int width, height;
        settings.get ("size", "(ii)", out width, out height);
        resize(width, height);

        apps_list_panel.selection_changed.connect(on_selection_changed);
    }

    protected override bool configure_event(Gdk.EventConfigure event) {
        if (get_realized() && !(Gdk.WindowState.MAXIMIZED in get_window ().get_state())) {
            settings.set("size", "(ii)", event.width, event.height);
        }

        return base.configure_event(event);
    }

    protected override bool window_state_event(Gdk.EventWindowState event) {
        settings.set_int("state", event.new_window_state);
        return base.window_state_event(event);
    }

    protected override bool delete_event(Gdk.EventAny event) {
        return base.hide_on_delete();
    }

    private void on_selection_changed(NotificationApp? notification_app) {
        if (notification_app == null) {
            titlebar_right.title = null;
            return;
        }

        titlebar_right.title = notification_app.app_name;

        notifications_view.reset();

        foreach (var n in notification_app.notifications) {
            notifications_view.add_notification(n);

            if (!n.read) {
                this.application.withdraw_notification(n.id);
                n.read = true;
            }
        }
    }
}

} // namespace Nuntius

/* ex:set ts=4 et: */
