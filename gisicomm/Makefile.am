include $(top_srcdir)/Makefile.decl

NULL =

AM_CPPFLAGS = \
	-I$(top_srcdir) \
	-I$(top_srcdir)/gisi \
	-I$(top_srcdir)/clients \
	$(GLIB_CFLAGS) \
	$(GLIB_EXTRA_CFLAGS) \
	-DG_LOG_DOMAIN=\"gisicomm\" \
	$(NULL)

VALAC_ARGS = \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/data \
	--vapidir $(top_srcdir)/vapi \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg libgisi \
	--pkg posix \
	--header gisicomm.h \
	--library gisicomm-0.0

#if WANT_DEBUG
#VALAC_ARGS += -g -D DEBUG
#AM_CFLAGS = -ggdb -O0
#endif

BUILT_SOURCES = .vala.stamp

lib_LTLIBRARIES = \
	libgisicomm.la
	$(NULL)

libgisicomm_la_VALASOURCES = \
	gisicomm.vala \
	$(NULL)

libgisicomm_la_SOURCES = \
	$(BUILT_SOURCES) \
	$(libgisicomm_la_VALASOURCES:.vala=.c) \
	$(NULL)

gisicommincludedir = $(includedir)/gisi-0.0

gisicomminclude_HEADERS = gisicomm.h

gisicomm-0.0.vapi .vala.stamp: $(libgisicomm_la_VALASOURCES)
	$(VALAC) -C $(VALAC_ARGS) $^
	touch $@

libgisicomm_la_LIBADD = \
	$(GLIB_LIBS) \
	$(GLIB_EXTRA_LIBS) \
	$(NULL)

vapidir = $(datadir)/vala/vapi

dist_vapi_DATA = \
	gisicomm-0.0.vapi \
	gisicomm-0.0.deps \
	$(NULL)

EXTRA_DIST += \
	$(libgisicomm_la_VALASOURCES) \
	gisicomm-0.0.vapi \
	$(BUILT_SOURCES) \
	$(NULL)

CLEANFILES = \
    $(BUILT_SOURCES) \
    $(libgisicomm_la_SOURCES) \
    $(NULL)

MAINTAINERCLEANFILES = \
	$(CLEANFILES) \
	Makefile.in
