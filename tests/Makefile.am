include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	-I$(top_srcdir)/gisi \
	-I$(top_srcdir)/clients \
	-I$(top_srcdir)/gisicomm \
	-I$(top_srcdir) \
	$(GLIB_CFLAGS) \
	$(GLIB_EXTRA_CFLAGS) \
	$(NULL)

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

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(GLIB_LIBS) \
	$(GLIB_EXTRA_LIBS) \
	$(top_builddir)/gisi/libgisi.la \
	$(top_builddir)/gisicomm/libgisicomm.la

#
# ping test
#
# TEST_PROGS += testping
testping_VALASOURCES = testping.vala
testping_SOURCES = testping.c
$(testping_SOURCES): $(testping_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@
testping_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testping_VALASOURCES)

#
# servers test
#
# TEST_PROGS += testservers
testservers_VALASOURCES = testservers.vala
testservers_SOURCES = testservers.c
$(testservers_SOURCES): $(testservers_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@
testservers_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testservers_VALASOURCES)

CLEANFILES = \
    $(TEST_PROGS) \
    *.? \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
