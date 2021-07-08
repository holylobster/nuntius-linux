ACLOCAL_AMFLAGS = -I m4 ${ACLOCAL_FLAGS}

SUBDIRS = po

# desktop file
desktopdir = $(datadir)/applications
desktop_in_files = data/org.holylobster.nuntius.desktop.in
desktop_DATA = $(desktop_in_files:.desktop.in=.desktop)
@INTLTOOL_DESKTOP_RULE@

# autostart file
autostartdir = $(sysconfdir)/xdg/autostart
autostart_DATA = $(desktop_DATA)

# appdata file
appdatadir = $(datadir)/appdata
appdata_DATA = $(appdata_in_files:.xml.in=.xml)
appdata_in_files = data/org.holylobster.nuntius.appdata.xml.in
@INTLTOOL_XML_RULE@

# DBus service file
servicedir = $(datadir)/dbus-1/services
service_DATA = data/org.holylobster.nuntius.service
dist_noinst_DATA = data/org.holylobster.nuntius.service.in

data/org.holylobster.nuntius.service: data/org.holylobster.nuntius.service.in Makefile
	$(AM_V_GEN) $(MKDIR_P) $(dir $@); sed -e "s|\@bindir\@|$(bindir)|" $< > $@

# gsettings
gsettings_SCHEMAS = data/org.holylobster.nuntius.gschema.xml
@GSETTINGS_RULES@

data_icons_public_icons = \
	hicolor_apps_16x16_nuntius.png \
	hicolor_apps_22x22_nuntius.png \
	hicolor_apps_24x24_nuntius.png \
	hicolor_apps_32x32_nuntius.png \
	hicolor_apps_48x48_nuntius.png \
	hicolor_apps_256x256_nuntius.png

data-icons-install-icons:
	@echo "Installing icons"; \
	for icon in $(data_icons_public_icons); do \
		THEME=`echo $$icon | cut -d_ -f1`; \
		CONTEXT=`echo $$icon | cut -d_ -f2`; \
		SIZE=`echo $$icon | cut -d_ -f3`; \
		ICONFILE=`echo $$icon | cut -d_ -f4`; \
		$(mkinstalldirs) $(DESTDIR)$(datadir)/icons/$$THEME/$$SIZE/$$CONTEXT; \
		echo "  - $(DESTDIR)$(datadir)/icons/$$THEME/$$SIZE/$$CONTEXT/$$ICONFILE"; \
		$(INSTALL_DATA) $(srcdir)/data/icons/$$icon $(DESTDIR)$(datadir)/icons/$$THEME/$$SIZE/$$CONTEXT/$$ICONFILE; \
	done;

data-icons-uninstall-icons:
	-for icon in $(data_icons_public_icons); do \
		THEME=`echo $$icon | cut -d_ -f1`; \
		CONTEXT=`echo $$icon | cut -d_ -f2`; \
		SIZE=`echo $$icon | cut -d_ -f3`; \
		ICONFILE=`echo $$icon | cut -d_ -f4`; \
		rm -f $(DESTDIR)$(datadir)/icons/$$THEME/$$SIZE/$$CONTEXT/$$ICONFILE; \
	done;

AM_CPPFLAGS = \
	-DGETTEXT_PACKAGE=\""$(GETTEXT_PACKAGE)"\" \
	-DGNOMELOCALEDIR=\""$(localedir)"\" \
	-DDATADIR=\""$(datadir)"\" \
	-DTOOLSDIR=\""$(libexecdir)/$(PACKAGE)"\"

AM_VALAFLAGS = \
	--target-glib=2.40 \
	--pkg gio-2.0 \
	--pkg gio-unix-2.0 \
	--pkg gtk+-3.0 \
	--pkg json-glib-1.0 \
	--pkg posix \
	--pkg avahi-gobject \
	--pkg avahi-client \
	--gresources  $(top_srcdir)/src/resources/nuntius.gresource.xml

bin_PROGRAMS = nuntius qrtest

BUILT_SOURCES = \
	src/resources.c

resource_files = $(shell $(GLIB_COMPILE_RESOURCES) --generate-dependencies --sourcedir=$(top_srcdir)/src/resources $(top_srcdir)/src/resources/nuntius.gresource.xml)
src/resources.c: $(top_srcdir)/src/resources/nuntius.gresource.xml $(resource_files)
	$(AM_V_GEN) $(GLIB_COMPILE_RESOURCES) --target=$@ --sourcedir=$(top_srcdir)/src/resources --generate-source $<

toolsdir = $(libexecdir)/$(PACKAGE)
tools_SCRIPTS = createcert.sh

VALA_SOURCES = \
	src/application.vala \
	src/appslistpanel.vala \
	src/appslist.vala \
	src/client.vala \
	src/mdns.vala \
	src/notification.vala \
	src/notificationapp.vala \
	src/notificationcounter.vala \
	src/notificationsview.vala \
	src/qrimage.vala \
	src/smsnotification.vala \
	src/testview.vala \
	src/window.vala \
	src/main.vala

nuntius_SOURCES = \
	$(BUILT_SOURCES) \
	$(VALA_SOURCES) \
	src/config.vapi \
	src/qrencode.vapi

AM_CFLAGS = \
	$(NUNTIUS_CFLAGS) \
	-Wall \
	-Wno-unused-but-set-variable \
	-Wno-unused-variable

nuntius_LDFLAGS = -export-dynamic
nuntius_LDADD = \
	$(NUNTIUS_LIBS) \
	-lm

qrtest_SOURCES = \
	tests/qrtest.vala \
	src/qrimage.vala \
	src/qrencode.vapi

qrtest_LDFLAGS = -export-dynamic
qrtest_LDADD = \
	$(NUNTIUS_LIBS) \
	-lm

check-local: $(desktop_DATA)
	$(DESKTOP_FILE_VALIDATE) $(desktop_DATA)

install-data-local: data-icons-install-icons

uninstall-local: data-icons-uninstall-icons

EXTRA_DIST = \
	$(appdata_in_files) \
	$(desktop_in_files) \
	$(resource_files) \
	src/resources/nuntius.gresource.xml \
	$(addprefix data/icons/,$(data_icons_public_icons))

CLEANFILES = \
	$(appdata_DATA) \
	$(desktop_DATA) \
	$(service_DATA)

MAINTAINERCLEANFILES = \
	ABOUT-NLS \
	aclocal.m4 \
	config.guess \
	config.h.in \
	config.rpath \
	config.sub \
	depcomp \
	install-sh \
	ltmain.sh \
	missing \
	compile \
	$(VALA_SOURCES:.vala=.c) \
	*.stamp

-include $(top_srcdir)/git.mk
