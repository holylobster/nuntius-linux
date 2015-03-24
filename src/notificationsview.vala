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

public class NotificationsView : Gtk.TextView {
    private Gtk.TextTag notification_tag;
    private Gtk.TextTag title_tag;
    private bool first_notification;

    construct {
        var buf = get_buffer();

        notification_tag = buf.create_tag("notification", null);
        title_tag = buf.create_tag("title",
                                   "weight",
                                   Pango.Weight.BOLD,
                                   null);
    }

    protected override void draw_layer(Gtk.TextViewLayer layer, Cairo.Context cr) {
        cr.save();

        if (layer == Gtk.TextViewLayer.BELOW) {
            if (get_buffer() == null) {
                return;
            }

            var context = get_style_context();

            context.save();
            context.add_class("notification");

            Gdk.Rectangle visible_rect;
            get_visible_rect(out visible_rect);

            Gdk.Rectangle clip;
            Gdk.cairo_get_clip_rectangle(cr, out clip);

            int x1, y1, x2, y2;
            x1 = clip.x;
            y1 = clip.y;
            x2 = x1 + clip.width;
            y2 = y1 + clip.height;

            window_to_buffer_coords(Gtk.TextWindowType.TEXT,
                                    x1, y1,
                                    out x1, out y1);

            window_to_buffer_coords(Gtk.TextWindowType.TEXT,
                                    x2, y2,
                                    out x2, out y2);

            Gtk.TextIter s, e;
            get_iter_at_location(out s, x1, y1);
            get_iter_at_location(out e, x2, y2);

            while (true) {
                Gtk.TextIter it = s;

                if (s.has_tag(notification_tag)) {
                    if (!it.forward_to_tag_toggle(notification_tag)) {
                        break;
                    }

                    Gdk.Rectangle rect1;
                    get_iter_location(s, out rect1);

                    buffer_to_window_coords(Gtk.TextWindowType.TEXT,
                                            rect1.x, rect1.y,
                                            out x1, out y1);

                    if (it.compare(e) > 0) {
                        it = e;
                    }

                    Gdk.Rectangle rect2;
                    get_iter_location(it, out rect2);
                    buffer_to_window_coords(Gtk.TextWindowType.TEXT,
                                            rect2.x + rect2.width, rect2.y + rect2.height,
                                            out x2, out y2);

                    int x = left_margin / 2;
                    int y = int.max(y1 - rect1.height / 2, clip.y);
                    int width = clip.width - left_margin / 2 - right_margin / 2;
                    int height = int.min(y2 + rect2.height / 2 - y1 + rect1.height / 2, clip.height);

                    context.render_background(cr, x, y, width, height);
                }

                if (!s.forward_to_tag_toggle(notification_tag)) {
                    break;
                }

                if (s.compare(e) > 0) {
                    break;
                }
            }

            context.restore();
        }

        cr.restore();
    }

    public void reset() {
        get_buffer().set_text("");
        first_notification = true;
    }

    public void add_notification(Notification notification) {
        var buf = get_buffer();
        var insert = buf.get_insert();
        Gtk.TextIter it;
        buf.get_iter_at_mark(out it, insert);

        if (first_notification) {
            buf.insert(ref it, "\n\n", -1);
        }

#if VALA_0_28
        buf.insert_with_tags(ref it, notification.title, -1, notification_tag, title_tag, null);

        if (notification.body != null) {
            buf.insert_with_tags(ref it, "\n\n", -1, notification_tag, null);
            buf.insert_with_tags(ref it, notification.body, -1, notification_tag, null);
        }
#else
        buf.insert_with_tags(it, notification.title, -1, notification_tag, title_tag, null);

        if (notification.body != null) {
            buf.insert_with_tags(it, "\n\n", -1, notification_tag, null);
            buf.insert_with_tags(it, notification.body, -1, notification_tag, null);
        }
#endif

        buf.insert(ref it, "\n\n\n", -1);

        first_notification = false;
    }
}

} // namespace Nuntius

/* ex:set ts=4 et: */
