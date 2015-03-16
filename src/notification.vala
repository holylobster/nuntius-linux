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
    private string _id;
    private string _package_name;
    private string _app_name;
    private string _title;
    private string _body;
    private BytesIcon _icon;

    public string id {
        get { return _id; }
        set construct { _id = value; }
    }

    public string package_name {
        get { return _package_name; }
        set construct { _package_name = value; }
    }

    public string app_name {
        get { return _app_name; }
        set construct { _app_name = value; }
    }

    public string title {
        get { return _title; }
        set construct { _title = value; }
    }

    public string body {
        get { return _body; }
        set construct { _body = value; }
    }

    public BytesIcon icon {
        get { return _icon; }
        set construct { _icon = value; }
    }

    public Notification(string id, string package_name, string app_name, string title, string body, BytesIcon icon) {
        Object(id: id, package_name: package_name, app_name: app_name, title: title, body: body, icon: icon);
    }

    public GLib.Notification to_gnotification() {
        GLib.Notification notification = new GLib.Notification(title);

        if (body != null) {
            notification.set_body(body);
        }

        if (icon != null) {
            notification.set_icon(icon);
        }

        return notification;
    }
}

} // namespace Nuntius

/* ex:set ts=4 et: */
