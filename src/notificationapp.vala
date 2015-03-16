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

public class NotificationApp : Object {
    private string _id;
    List<Notification> _notifications;

    public string id {
        get { return _id; }
        set construct { _id = value; }
    }

    public List<Notification> notifications {
        get { return _notifications; }
    }

    public NotificationApp(string id) {
        Object(id: id);
    }

    construct {
        _notifications = new List<Notification>();
    }

    public void add_notification(Notification notification) {
        _notifications.append(notification);
    }
}

} // namespace Nuntius

/* ex:set ts=4 et: */
