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

static MainLoop loop = null;

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
public string hexdump( uint8[] array, int linelength = 16, string prefix = "", uchar unknownCharacter = '?' )
{
    if ( array.length < 1 )
    {
        return "";
    }

    string result = "";

    int BYTES_PER_LINE = linelength;

    var hexline = new StringBuilder( prefix );
    var ascline = new StringBuilder();
    uchar b;
    int i;

    for ( i = 0; i < array.length; ++i )
    {
        b = array[i];
        hexline.append_printf( "%02X ", b );
        if ( 31 < b && b < 128 )
            ascline.append_printf( "%c", b );
        else
            ascline.append_printf( "." );

        if ( i % BYTES_PER_LINE+1 == BYTES_PER_LINE )
        {
            hexline.append( ascline.str );
            result += hexline.str;
            result += "\n";
            hexline = new StringBuilder( prefix );
            ascline = new StringBuilder();
        }
    }
    if ( i % BYTES_PER_LINE+1 != BYTES_PER_LINE )
    {
        while ( hexline.len < 3 * BYTES_PER_LINE )
        {
            hexline.append_c( ' ' );
        }

        hexline.append( ascline.str );
        result += hexline.str;
        result += "\n";
    }

    return result.strip();
}

//===========================================================================
public async void sendCommand( string[] args )
{
    stdout.printf( "sendisi 1.0.0 (C) Michael 'Mickey' Lauer comes without any warranty. Don't blame me for frying your modem!\n" );

    var modem = new GIsiComm.ModemAccess( args[1] );
    if ( !yield modem.connect() )
    {
        stderr.printf( "Can't connect to modem via %s. Check privileges and interface\n", args[1] );
        Posix.exit( -1 );
    }

    var req = new uint8[] {};

    uint8 resource = 0;
    args[2].scanf( "%X", &resource );

    foreach ( var byte in args[3:args.length] )
    {
        uint8 b = 0;
        if ( byte.scanf( "%X", &b ) <= 0 )
        {
            stderr.printf( @"Can't parse $byte in command" );
            Posix.exit( -1 );
        }

        req += b;
    }

    stdout.printf( "Connected to ISI modem via %s", args[1] );
    stdout.printf( ", checking whether resource 0x%02X is reachable...\n", resource );

    bool msgok = false;

    modem.m.resource_ping( resource, (msg) => {
        msgok = msg.ok();
        sendCommand.callback();
    } );
    yield;

    if ( !msgok )
    {
        stderr.printf( "Resource 0x%02X is not reachable, giving up\n", resource );
        Posix.exit( -1 );
    }

    if ( args.length > 3 )
    {
        stderr.printf( "Resource 0x%02X answering, sending message...\n", resource );
    }
    else
    {
        stdout.printf(" Resource 0x%02X answering. OK\n", resource );
        Posix.exit( 0 );
    }

    modem.m.request_send( resource, req, 5, (msg) => {
        if ( msg.ok() )
        {
            stdout.printf( "Answer OK. Result is\n%s\n", hexdump( msg.data ) );
        }
        else
        {
            stdout.printf( "Answer ERROR: %s\n", msg.strerror );
        }
        sendCommand.callback();
    } );
    yield;

    loop.quit();
}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    if ( args.length < 3 )
    {
        stderr.printf( "Usage: %s <iface> <resource> [firstbyte] ...\n", args[0] );
        Posix.exit( -1 );
    }

    loop = new MainLoop();

    Idle.add( () => {
        sendCommand( args );
        return false;
    } );

    loop.run();
}
