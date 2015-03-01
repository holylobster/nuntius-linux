AC_PREREQ(2.63)

AC_INIT([nuntius], [0.0.1])

dnl http://people.gnome.org/~walters/docs/build-api.txt
dnl We don't support separate builddir when building from git
echo \#buildapi-variable-no-builddir >/dev/null

AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_HEADERS(config.h)
AC_CONFIG_SRCDIR(src/main.vala)

AM_INIT_AUTOMAKE([1.11 tar-ustar dist-xz no-dist-gzip foreign])
m4_ifdef([AM_SILENT_RULES],[AM_SILENT_RULES([yes])])

AC_PROG_CC
AC_PROG_CC_STDC
AC_PROG_INSTALL
AM_PROG_VALAC([0.23.3])

PKG_PROG_PKG_CONFIG

PKG_CHECK_MODULES(NUNTIUS, [
    gio-2.0 >= 2.40
    gio-unix-2.0 >= 2.38
    glib-2.0 >= 2.38
    json-glib-1.0 >= 0.16.2
])

AC_CONFIG_FILES([
    Makefile
])

AC_OUTPUT

echo "
    nuntius ${VERSION}

    prefix: ${prefix}
    Vala compiler: ${VALAC}
    C compiler: ${CC}

    Now type 'make' to build ${PACKAGE}
"
