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
    public GIsiClient.PhoneInfo phoneinfo;
    public GIsiClient.SIMAuth simauth;
    public GIsiClient.SIM sim;
    public GIsiClient.Network network;
    public GIsiClient.Call call;

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
void test_client_phoneinfo_bringup()
//===========================================================================
{
    mt.phoneinfo = mt.modem.phone_info_client_create();
    assert( mt.phoneinfo != null );

    mt.phoneinfo.verify( mt.onClientReachabilityVerification );
}

//===========================================================================
void test_comm_phoneinfo_query()
//===========================================================================
{
    var ok = false;

    mt.gcphoneinfo = new GIsiComm.PhoneInfo( mt.modem );
    mt.gcphoneinfo.readManufacturer( ( error, result ) => {
        assert( error == GIsiComm.ErrorCode.OK );
        assert( result == "Nokia" );
        debug( @"Vendor = $result" );
        ok = true;
    } );

    while ( !ok ) MainContext.default().iteration( false );

    ok = false;

    mt.gcphoneinfo.readModel( ( error, result ) => {
        assert( error == GIsiComm.ErrorCode.OK );
        assert( result == "Nokia N900" );
        debug( @"Model = $result" );
        ok = true;
    } );

    while ( !ok ) MainContext.default().iteration( false );

    ok = false;

    mt.gcphoneinfo.readSerial( ( error, result ) => {
        assert( error == GIsiComm.ErrorCode.OK );
        assert( result.has_prefix( "35" ) && result.length == 15 );
        debug( @"IMEI = $result" );
        ok = true;
    } );

    while ( !ok ) MainContext.default().iteration( false );

    ok = false;

    mt.gcphoneinfo.readVersion( ( error, result ) => {
        assert( error == GIsiComm.ErrorCode.OK );
        assert( result.length == 2 );
        debug( @"Version = $result" );
        ok = true;
    } );

    while ( !ok ) MainContext.default().iteration( false );

    ok = false;
}

//===========================================================================
void test_client_simauth_bringup()
//===========================================================================
{
    mt.simauth = mt.modem.sim_auth_client_create();
    assert( mt.simauth != null );

    mt.simauth.verify( mt.onClientReachabilityVerification );
}

//===========================================================================
void test_comm_simauth_query()
//===========================================================================
{
    var ok = false;

    mt.gcsimauth = new GIsiComm.SIMAuth( mt.modem );

    schedule();

    mt.gcsimauth.queryStatus( ( error, result ) => {
        assert( error == GIsiComm.ErrorCode.OK );
        debug( "SIM Status = 0x%0X", result );
        ok = true;
    } );

    while ( !ok ) MainContext.default().iteration( false );
}

//===========================================================================
void test_client_sim_bringup()
//===========================================================================
{
    mt.sim = mt.modem.sim_client_create();
    assert( mt.sim != null );

    mt.sim.verify( mt.onClientReachabilityVerification );
}

//===========================================================================
void test_comm_sim_query()
//===========================================================================
{
    var ok = false;

    mt.gcsim = new GIsiComm.SIM( mt.modem );
    mt.gcsim.readSPN( ( error, result ) => {
        assert( error == GIsiComm.ErrorCode.OK );
        //assert( result == "Nokia" );
        debug( @"SPN = $result" );
        ok = true;
    } );

    while ( !ok ) MainContext.default().iteration( false );
    ok = false;

    mt.gcsim.readHPLMN( ( error, result ) => {
        assert( error == GIsiComm.ErrorCode.OK );
        assert( result.has_prefix( "262" ) );
        debug( @"HPLMN = $result" );
        ok = true;
    } );

    while ( !ok ) MainContext.default().iteration( false );
    ok = false;

    mt.gcsim.readIMSI( ( error, result ) => {
        assert( error == GIsiComm.ErrorCode.OK );
        assert( result.has_prefix( "262" ) );
        debug( @"IMSI = $result" );
        ok = true;
    } );

    while ( !ok ) MainContext.default().iteration( false );
    ok = false;
}

//===========================================================================
void test_client_network_bringup()
//===========================================================================
{
    mt.network = mt.modem.network_client_create();
    assert( mt.network != null );

    mt.network.verify( mt.onClientReachabilityVerification );
}

//===========================================================================
void test_comm_network_query()
//===========================================================================
{
    var ok = false;

    mt.gcnetwork = new GIsiComm.Network( mt.modem );

    mt.gcnetwork.queryStatus( ( error, result ) => {
        assert( error == GIsiComm.ErrorCode.OK );
        debug( "Provider = %s (%s%s) in %s.%s", result.name, result.mcc, result.mnc, result.lac, result.cid );
        ok = true;
    } );
    while ( !ok ) MainContext.default().iteration( false );
    ok = false;

    mt.gcnetwork.queryStrength( ( error, result ) => {
        assert( error == GIsiComm.ErrorCode.OK );
        debug( "RSSI = %d", result );
        ok = true;
    } );

    while ( !ok ) MainContext.default().iteration( false );
    ok = false;

#if 0
    mt.gcnetwork.listProviders( ( error, result ) => {
        assert( error == GIsiComm.ErrorCode.OK );
        //debug( "RSSI = %d", result );
        ok = true;
    } );

    while ( !ok ) MainContext.default().iteration( false );
#endif
}

//===========================================================================
void test_client_call_bringup()
//===========================================================================
{
    mt.call = mt.modem.call_client_create();
    assert( mt.call != null );

    mt.call.verify( mt.onClientReachabilityVerification );
}

//===========================================================================
void test_comm_call_query()
//===========================================================================
{
    var ok = false;

    mt.gccall = new GIsiComm.Call( mt.modem );

    /*

    mt.gccall.queryStatus( ( error, result ) => {
        assert( error == GIsiComm.ErrorCode.OK );
        //ok = true;
    } );
    *
    */
    while ( !ok ) MainContext.default().iteration( false );
    ok = false;
}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );

    Test.add_func( "/GISI/Modem/Create", test_modem_create );
    Test.add_func( "/GISI/Netlink/Bringup", test_netlink_bringup );

//    Test.add_func( "/GISI/Client/PhoneInfo/Bringup", test_client_phoneinfo_bringup );
//    Test.add_func( "/GISI/COMM/PhoneInfo/Query", test_comm_phoneinfo_query );

//    Test.add_func( "/GISI/Client/SIMAuth/Bringup", test_client_simauth_bringup );
//    Test.add_func( "/GISI/COMM/SIMAuth/Query", test_comm_simauth_query);

//    Test.add_func( "/GISI/Client/SIM/Bringup", test_client_sim_bringup );
//    Test.add_func( "/GISI/COMM/SIM/Query", test_comm_sim_query );

    Test.add_func( "/GISI/Client/Network/Bringup", test_client_network_bringup );
    Test.add_func( "/GISI/COMM/Network/Query", test_comm_network_query );

    Test.add_func( "/GISI/Client/Call/Bringup", test_client_call_bringup );
    Test.add_func( "/GISI/COMM/Call/Query", test_comm_call_query );

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
