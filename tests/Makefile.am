include $(top_srcdir)/Makefile.decl

NULL =

AM_CFLAGS = \
	-I$(top_srcdir)/src/lib \
	$(GLIB_CFLAGS) \
	$(GLIB_EXTRA_CFLAGS) \
	$(NULL)

VALAC_ARGS = \
	-C \
	--basedir $(top_srcdir) \
	--vapidir $(top_srcdir)/data \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gio-2.0 \
	--pkg libgisi

noinst_PROGRAMS = $(TEST_PROGS)

progs_ldadd = \
	$(GLIB_LIBS) \
	$(GLIB_EXTRA_LIBS) \
	../gisi/libgisi.la

#
# ping test
#
TEST_PROGS += testping
testping_VALASOURCES = testping.vala
testping_SOURCES = testping.c
$(testping_SOURCES): $(testping_VALASOURCES)
	$(VALAC) $(VALAC_ARGS) $^
	touch $@
testping_LDADD = $(progs_ldadd)
EXTRA_DIST += $(testping_VALASOURCES)

CLEANFILES = \
    $(TEST_PROGS) \
    *.? \
    $(NULL)

MAINTAINERCLEANFILES = \
  Makefile.in \
  $(NULL)
