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

public static int main(string[] args) {
    Gtk.init(ref args);

    var window = new Gtk.Window();
    window.title = "QR Test";
    window.border_width = 10;
    window.set_default_size(350, 70);
    window.destroy.connect(Gtk.main_quit);

    var qr = new Nuntius.QRImage();
    qr.text = "This is a test";

    window.add(qr);
    window.show_all();

    Gtk.main();

    return 0;
}

/* ex:set ts=4 et: */
