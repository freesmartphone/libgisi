include $(top_srcdir)/Makefile.decl

NULL =

VALAC_ARGS = \
	-C \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/data \
	--vapidir $(top_srcdir)/gisicomm \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg libgisi \
	--pkg gisicomm-1.0

INCLUDES = \
	-I$(top_srcdir)/gisi \
	-I$(top_srcdir)/clients \
	-I$(top_srcdir)/gisicomm \
	$(GLIB_CFLAGS) \
	$(GLIB_EXTRA_LIBS) \
	$(NULL)

BUILT_SOURCES = .vala.stamp

sbin_PROGRAMS = sendisi

sendisi_VALASOURCES = \
	sendisi.vala \
	$(NULL)

sendisi_SOURCES = \
	$(sendisi_VALASOURCES:.vala=.c) \
	$(NULL)

$(BUILT_SOURCES): $(sendisi_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@

sendisi_LDADD = \
	$(GLIB_LIBS) \
	$(GLIB_EXTRA_LIBS) \
	../gisi/libgisi.la \
	../gisicomm/libgisicomm.la \
	$(NULL)

EXTRA_DIST += \
	$(sendisi_VALASOURCES) \
	$(BUILT_SOURCES) \
	$(NULL)

CLEANFILES = \
	*.c \
	*.h \
	$(BUILT_SOURCES) \
	$(NULL)

MAINTAINERCLEANFILES = \
	Makefile.in \
	$(NULL)
