NULL = 

AM_CFLAGS = \
	    $(GLIB_CFLAGS) \
	    $(NULL)
lib_LTLIBRARIES = \
		  libgisi.la \
		  $(NULL)

libgisi_la_SOURCES = \
		    client.c \
		    iter.c \
		    message.c \
		    modem.c \
		    netlink.c \
		    pep.c \
		    pipe.c \
		    server.c \
		    socket.c \
		    $(NULL)

libgisi_la_LIBADD = \
		    $(GLIB_LIBS) \
		    $(NULL)


libgisiincludedir = $(includedir)/gisi-0.0/gisi
libgisiinclude_DATA = \
                    client.h \
                    common.h \
                    iter.h \
                    libgisi.h \
                    message.h \
                    modem.h \
                    netlink.h \
                    pep.h \
                    phonet.h \
                    pipe.h \
                    server.h \
                    socket.h \
		    $(NULL)

