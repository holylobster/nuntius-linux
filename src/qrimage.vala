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

public class QRImage : Gtk.DrawingArea {
    private string _text;
    private Qrencode.QRcode? qrcode;
    private const double MIN_SQUARE_SIZE = 1.0;

    [CCode (notify = false)]
    public string text {
        get { return _text; }
        set {
            if (_text != value) {
                _text = value;
                qrcode = new Qrencode.QRcode.encodeString(_text, 0,
                                                          Qrencode.EcLevel.M,
                                                          Qrencode.Mode.B8, 1);
                notify_property("text");

                queue_draw();
            }
        }
    }

    protected override bool draw(Cairo.Context cr) {
        if (qrcode != null) {
            uint width, height;

            width = get_allocated_width();
            height = get_allocated_height();

            /* make it square */
            if (height < width) {
                width = height;
            }

            double square_size = width / qrcode.width;
            if (square_size < MIN_SQUARE_SIZE) {
                square_size = MIN_SQUARE_SIZE;
            }

            cr.save();

            cr.set_source_rgb(0, 0, 0);

            for (int iy = 0; iy < qrcode.width; iy++) {
                for (int ix = 0; ix < qrcode.width; ix++) {
                    /* Symbol data is represented as an array contains
                     * width*width uchars. Each uchar represents a module
                     * (dot). If the less significant bit of the uchar
                     * is 1, the corresponding module is black. The other
                     * bits are meaningless for us.
                     */
                    if ((qrcode.data[iy * qrcode.width + ix] & 1) != 0) {
                        cr.rectangle(ix * square_size, iy * square_size, square_size, square_size);
                        cr.fill();
                    }
                }
            }

            cr.restore();
        }

        return false;
    }
}

} // namespace Nuntius

/* ex:set ts=4 et: */
