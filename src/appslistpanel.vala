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

[GtkTemplate (ui = "/org/holylobster/nuntius/ui/appslistpanel.ui")]
public class AppsListPanel : Gtk.Frame {
    private uint filter_entry_changed_id;

    [GtkChild]
    private Gtk.ToolItem search_tool_item;

    [GtkChild]
    private Gtk.SearchEntry filter_entry;

    [GtkChild]
    private AppsList apps_list_view;

    public void refilter() {
        string str = filter_entry.get_text();

        apps_list_view.set_filter_text(str);
    }

    private bool filter_entry_changed_timeout() {
        filter_entry_changed_id = 0;
        refilter();
        return false;
    }

    [GtkCallback]
    private void filter_entry_changed(Gtk.Editable editable) {
        if (filter_entry_changed_id != 0) {
            Source.remove(filter_entry_changed_id);
        }

        filter_entry_changed_id = Timeout.add(300, filter_entry_changed_timeout);
    }

    public signal void selection_changed(NotificationApp? notification_app);

    construct {
        search_tool_item.set_expand(true);

        apps_list_view.selection_changed.connect((napp) => {
            selection_changed(napp);
        });
    }
}

} // namespace Nuntius

/* ex:set ts=4 et: */
