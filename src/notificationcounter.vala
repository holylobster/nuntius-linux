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

[GtkTemplate (ui = "/org/holylobster/nuntius/ui/notificationcounter.ui")]
public class NotificationCounter : Gtk.Frame {
    private uint _counter;

    [GtkChild]
    private Gtk.Label label_counter;

    public uint counter {
        get { return _counter; }
        set {
            _counter = value;
            label_counter.set_label(_counter.to_string());
        }
    }
}

} // namespace Nuntius

/* ex:set ts=4 et: */
