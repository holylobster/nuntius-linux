AC_PREREQ(2.63)

AC_INIT([nuntius], [0.2.0])

dnl http://people.gnome.org/~walters/docs/build-api.txt
dnl We don't support separate builddir when building from git
echo \#buildapi-variable-no-builddir >/dev/null

AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_HEADERS(config.h)
AC_CONFIG_SRCDIR(src/main.vala)

AM_INIT_AUTOMAKE([1.11 tar-ustar dist-xz no-dist-gzip foreign])
m4_ifdef([AM_SILENT_RULES],[AM_SILENT_RULES([yes])])

IT_PROG_INTLTOOL([0.50.1])
AM_GNU_GETTEXT([external])
AM_GNU_GETTEXT_VERSION([0.17])
GETTEXT_PACKAGE=AC_PACKAGE_NAME
AC_SUBST([GETTEXT_PACKAGE])
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE,"$GETTEXT_PACKAGE",[The name of the gettext domain])

AC_PROG_CC
AC_PROG_CC_STDC
AC_PROG_INSTALL
AM_PROG_VALAC([0.23.3])

AC_PATH_PROG(DESKTOP_FILE_VALIDATE, desktop-file-validate, /bin/true)
AC_PATH_PROG(GLIB_COMPILE_RESOURCES, glib-compile-resources)

GLIB_GSETTINGS

PKG_PROG_PKG_CONFIG

PKG_CHECK_MODULES(NUNTIUS, [
    gio-2.0 >= 2.40
    gio-unix-2.0 >= 2.38
    glib-2.0 >= 2.38
    gtk+-3.0 >= 3.14.0
    json-glib-1.0 >= 0.16.2
    libqrencode >= 3.1.0
    avahi-client >= 0.6.31
    avahi-gobject >= 0.6.31
])

AC_CONFIG_FILES([
    Makefile
    data/org.holylobster.nuntius.gschema.xml
    po/Makefile.in
])

AC_OUTPUT

echo "
    nuntius ${VERSION}

    prefix: ${prefix}
    Vala compiler: ${VALAC}
    C compiler: ${CC}

    Now type 'make' to build ${PACKAGE}
"
