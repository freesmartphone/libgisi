AC_INIT([libgisi], [0.0.0], [smartphones-userland@linuxtogo.org], [libgisi])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([dist-bzip2])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

AC_PROG_CC
AM_PROG_CC_C_O
AC_PROG_CC_C99
AC_GNU_SOURCE
AC_DISABLE_STATIC
AC_PROG_LIBTOOL

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

AC_CONFIG_FILES([
                 Makefile
                 gisi/Makefile
                 data/Makefile
                 data/libgisi.pc])

AC_OUTPUT
