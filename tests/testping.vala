/*
 * Copyright (C) 2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */

using GLib;

const string MODEM_IFACE = "usbpn0";
//const string MODEM_IFACE = "phonet0";

static ModemTester mt = null;
static MainLoop loop = null;

//===========================================================================
public static void sighandler( int signum )
{
    Posix.signal( signum, null ); // restore original sighandler
    loop.quit();
}

//===========================================================================
class ModemTester
{
    public GIsi.Modem modem;
    public GIsi.PhonetLinkState linkstate;

    public ModemTester( string iface )
    {
        modem = new GIsi.Modem( iface );
        linkstate = (GIsi.PhonetLinkState) 999;
    }

    public void onNetlinkStateChanged( GIsi.Modem modem, GIsi.PhonetLinkState st, string iface )
    {
        linkstate = st;
        debug( "netlink status for modem %p (%s) now %s", modem, iface, st.to_string() );
    }
}

//===========================================================================
void test_modem_create()
//===========================================================================
{
    var modem = new GIsi.Modem();
    modem = new GIsi.Modem( MODEM_IFACE );
    modem = new GIsi.Modem.index_new( 0 );
}

//===========================================================================
void test_netlink_bringup()
//===========================================================================
{
    mt.modem = new GIsi.Modem( MODEM_IFACE );
    assert( mt.modem != null );

    unowned GIsi.PhonetNetlink netlink = mt.modem.netlink_start( mt.onNetlinkStateChanged );
    assert( netlink != null );

    mt.modem.netlink_set_address( GIsi.PhonetDevice.SOS );

    while ( mt.linkstate != GIsi.PhonetLinkState.UP && mt.linkstate != GIsi.PhonetLinkState.DOWN )
    {
        MainContext.default().iteration( false );
    }

    assert( mt.linkstate == GIsi.PhonetLinkState.UP );
}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );

    Test.add_func( "/GISI/Modem/Create", test_modem_create );
    Test.add_func( "/GISI/Netlink/Bringup", test_netlink_bringup );

    mt = new ModemTester( MODEM_IFACE );

    loop = new MainLoop();
    Idle.add( () => {
        Test.run();
        return false;
    } );

    Posix.signal( Posix.SIGINT, sighandler );
    Posix.signal( Posix.SIGTERM, sighandler );

    debug( "=> mainloop" );
    loop.run();
    debug( "<= mainloop" );
}
