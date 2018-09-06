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

Application app = null;

bool on_terminate_app() {
    app.release();
    return false;
}

public static int main(string[] args) {
    Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.GNOMELOCALEDIR);
    Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");
    Intl.textdomain(Config.GETTEXT_PACKAGE);

    app = new Nuntius.Application();

    Unix.signal_add(Posix.Signal.INT, on_terminate_app);
    Unix.signal_add(Posix.Signal.HUP, on_terminate_app);
    Unix.signal_add(Posix.Signal.TERM, on_terminate_app);

    return app.run(args);
}

/* ex:set ts=4 et: */
