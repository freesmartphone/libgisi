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
    public GIsiClient.PhoneInfo phoneinfo;
    public GIsiClient.SIM sim;

    public GIsiComm.PhoneInfo gcphoneinfo;

    public ModemTester( string iface )
    {
        modem = new GIsi.Modem( iface );
        linkstate = (GIsi.PhonetLinkState) 999;
    }

    public void deviceReadManufacturer()
    {
      	var req = new uchar[] { GIsiClient.PhoneInfo.MessageType.PRODUCT_INFO_READ_REQ, GIsiClient.PhoneInfo.SubblockType.PRODUCT_INFO_MANUFACTURER };
        phoneinfo.send( req, onResponseReceived );
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
        debug( "ISI message ok is %s", msg.ok().to_string() );
    }

    public void onResponseReceived( GIsi.Message msg )
    {
        debug( @"got a response: $msg" );
        debug( "ISI message status is %d", msg.error );

        unowned string str;

        var sbi = msg.subblock_iter_create( 2 );
        debug( "yo" );
        debug( "iter is valid = %s", sbi.is_valid().to_string() );
        debug( "get latin tag = %s", sbi.get_latin_tag( out str, 5, 4 ).to_string() );


        debug( "result = %s", str );




        debug( "next = %s", sbi.next().to_string() );
        debug( "yo" );
        debug( "iter is valid = %s", sbi.is_valid().to_string() );
        debug( "next = %s", sbi.next().to_string() );
        debug( "yo" );
        debug( "iter is valid = %s", sbi.is_valid().to_string() );
        debug( "next = %s", sbi.next().to_string() );

        /*
        for ( var sbi = msg.subblock_iter_create( 2 ); sbi.is_valid(); sbi.next() )
        {
            debug( "got one subblock iter" );
        }
        */

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
void test_client_sim_bringup()
//===========================================================================
{
    mt.sim = mt.modem.sim_client_create();
    assert( mt.sim != null );

    mt.sim.verify( mt.onClientReachabilityVerification );
}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );

    Test.add_func( "/GISI/Modem/Create", test_modem_create );
    Test.add_func( "/GISI/Netlink/Bringup", test_netlink_bringup );
    Test.add_func( "/GISI/Client/PhoneInfo/Bringup", test_client_phoneinfo_bringup );
    Test.add_func( "/GISI/COMM/PhoneInfo/Query", test_comm_phoneinfo_query );
    Test.add_func( "/GISI/Client/SIM/Bringup", test_client_sim_bringup );

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
