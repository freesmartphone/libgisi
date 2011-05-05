/*
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 2 as
 *  published by the Free Software Foundation.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
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
public static void schedule( int seconds = 3 )
{
    var starttime = time_t();

    while ( time_t() < starttime + seconds )
    {
         MainContext.default().iteration( false );
    }
}

//===========================================================================
class ModemTester
{
    public GIsi.Modem modem;
    public GIsi.PhonetLinkState linkstate;
    public GIsiClient.MTC mtc;
    public GIsiClient.PhoneInfo phoneinfo;
    public GIsiClient.SIMAuth simauth;
    public GIsiClient.SIM sim;
    public GIsiClient.Network network;
    public GIsiClient.Call call;

    public GIsiComm.MTC gcmtc;
    public GIsiComm.PhoneInfo gcphoneinfo;
    public GIsiComm.SIMAuth gcsimauth;
    public GIsiComm.SIM gcsim;
    public GIsiComm.Network gcnetwork;
    public GIsiComm.Call gccall;

    public ModemTester( string iface )
    {
        modem = new GIsi.Modem( iface );
        linkstate = (GIsi.PhonetLinkState) 999;
    }

    //
    // callbacks
    //
    public void onNetlinkStateChanged( GIsi.Modem modem, GIsi.PhonetLinkState st, string iface )
    {
        linkstate = st;
        debug( "netlink status for modem %p (%s) now %s", modem, iface, st.to_string() );
    }

    public void onClientReachabilityVerification( GIsi.Message msg )
    {
        debug( @"client reachability verification got a response: $msg" );
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
void test_servers_query_versions()
//===========================================================================
{
    mt.gcmtc = new GIsiComm.MTC( mt.modem );
    var req = new uint8[] { 0x02, 0x00, 0x00 };
    var ok = false;

    for ( int i = 0x01; i < 0x0FF; ++i )
    {
        uchar resource = (uchar) i;
        debug( @"Querying resource $i..." );

    /*
    mt.modem.request_send( resource, req, 5, (msg) => {
        debug( @"reply is $msg" );
        ok = true;
    } );
    */

        mt.modem.resource_ping( resource, (msg) => {
            debug( @"reply is $msg" );
            ok = true;
        } );

        ok = false;
        while ( !ok ) MainContext.default().iteration( false );
    }
}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );

    Test.add_func( "/GISI/Modem/Create", test_modem_create );
    Test.add_func( "/GISI/Netlink/Bringup", test_netlink_bringup );

    Test.add_func( "/GISI/Servers/QueryVersions", test_servers_query_versions );

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

// vim:ts=4:sw=4:expandtab
