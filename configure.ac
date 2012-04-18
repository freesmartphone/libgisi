AC_INIT([libgisi], [0.1.0], [smartphones-userland@linuxtogo.org], [libgisi])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([dist-bzip2 no-dist-gzip])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

AC_PROG_CC
AM_PROG_CC_C_O
AC_PROG_CC_C99
AC_GNU_SOURCE
AC_DISABLE_STATIC
AC_PROG_LIBTOOL

VALA_REQUIRED=0.12.1
AC_PATH_PROG(VALAC, valac, valac)
AC_SUBST(VALAC)
m4_ifdef([AM_PROG_VALAC], [AM_PROG_VALAC([$VALA_REQUIRED])])

AC_SUBST(CFLAGS)
AC_SUBST(CPPFLAGS)
AC_SUBST(LDFLAGS)

# pkg-config
PKG_PROG_PKG_CONFIG
VALA_REQUIRED=0.9.7
GLIB_REQUIRED=2.18.0

PKG_CHECK_MODULES(GLIB,
                  glib-2.0 >= $GLIB_REQUIRED)
AC_SUBST(GLIB_CFLAGS)
AC_SUBST(GLIB_LIBS)

PKG_CHECK_MODULES(GLIB_EXTRA,
                  gobject-2.0 >= $GLIB_REQUIRED
                  gio-2.0 >= $GLIB_REQUIRED)
AC_SUBST(GLIB_EXTRA_CFLAGS)
AC_SUBST(GLIB_EXTRA_LIBS)

AC_CONFIG_FILES([
                 Makefile
                 clients/Makefile
                 gisi/Makefile
                 gisicomm/Makefile
                 data/Makefile
                 data/libgisi.pc
                 data/gisicomm-1.0.pc
                 tests/Makefile
                 tools/Makefile
                ])

AC_OUTPUT
