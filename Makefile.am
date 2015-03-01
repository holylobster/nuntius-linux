ACLOCAL_AMFLAGS = -I m4 ${ACLOCAL_FLAGS}

# desktop file
applicationsdir = $(datadir)/applications
applications_DATA = data/org.holylobster.nuntius.desktop

# autostart file
autostartdir = $(sysconfdir)/xdg/autostart
autostart_DATA = $(applications_DATA)

# DBus service file
servicedir = $(datadir)/dbus-1/services
service_DATA = data/org.holylobster.nuntius.service
dist_noinst_DATA = data/org.holylobster.nuntius.service.in

data/org.holylobster.nuntius.service: data/org.holylobster.nuntius.service.in Makefile
	$(AM_V_GEN) $(MKDIR_P) $(dir $@); sed -e "s|\@bindir\@|$(bindir)|" $< > $@

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
	-DDATADIR=\""$(datadir)"\"

AM_VALAFLAGS = \
	--target-glib=2.40 \
	--pkg gio-2.0 \
	--pkg gio-unix-2.0 \
	--pkg json-glib-1.0 \
	--pkg posix

bin_PROGRAMS = nuntius

VALA_SOURCES = \
	src/application.vala \
	src/connection.vala \
	src/main.vala

nuntius_SOURCES = \
	$(VALA_SOURCES) \
	src/config.vapi

AM_CFLAGS = \
	$(NUNTIUS_CFLAGS) \
	-Wall \
	-Wno-unused-but-set-variable \
	-Wno-unused-variable

nuntius_LDFLAGS = -export-dynamic
nuntius_LDADD = \
	$(NUNTIUS_LIBS) \
	-lm

install-data-local: data-icons-install-icons

uninstall-local: data-icons-uninstall-icons

EXTRA_DIST = \
	$(applications_DATA) \
	$(addprefix data/icons/,$(data_icons_public_icons))

CLEANFILES = \
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
