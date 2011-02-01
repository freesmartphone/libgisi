/*
 * Communication helper library for GISI
 *
 * (C) 2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 * (C) 2011 Klaus 'MrMoku' Kurzmann <mok@fluxnetz.de>
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

namespace GIsiComm
{
    public delegate void StringResultFunc( ErrorCode error, string? result );

    public enum ErrorCode
    {
        OK,
        INVALID_FORMAT,
    }

    public class PhoneInfo
    {
        private GIsiClient.PhoneInfo ll;

        public PhoneInfo( GIsi.Modem modem )
        {
            ll = modem.phone_info_client_create();
        }

        //
        // Helpers
        //
        private void checked( bool predicate ) throws GLib.Error
        {
            if ( !predicate )
            {
                throw new GLib.IOError.INVALID_DATA( "FSO" );
            }
        }

        private void parseSimpleString( GIsi.Message msg, StringResultFunc cb )
        {
            if ( !msg.ok() )
            {
                cb( (ErrorCode) msg.error, null );
                return;
            }

            var sbi = msg.subblock_iter_create( 2 );
            if ( !sbi.is_valid() )
            {
                cb( ErrorCode.INVALID_FORMAT, null );
                return;
            }

            try
            {
                cb( ErrorCode.OK, sbi.latin_tag_at_position( sbi.byte_at_position( 3 ), 4 ) );
            }
            catch ( Error e )
            {
                cb( ErrorCode.INVALID_FORMAT, null );
            }
        }

        //
        // public API
        //

        public void readManufacturer( owned StringResultFunc cb )
        {
            var req = new uchar[] { GIsiClient.PhoneInfo.MessageType.PRODUCT_INFO_READ_REQ, GIsiClient.PhoneInfo.SubblockType.PRODUCT_INFO_MANUFACTURER };

            ll.send( req, ( msg ) => {
                parseSimpleString( msg, cb );
            } );
        }

        public void readModel( owned StringResultFunc cb )
        {
            var req = new uchar[] { GIsiClient.PhoneInfo.MessageType.PRODUCT_INFO_READ_REQ, GIsiClient.PhoneInfo.SubblockType.PRODUCT_INFO_NAME };

            ll.send( req, ( msg ) => {
                parseSimpleString( msg, cb );
            } );
        }

        public void readSerial( owned StringResultFunc cb )
        {
            var req = new uchar[] { GIsiClient.PhoneInfo.MessageType.SERIAL_NUMBER_READ_REQ, GIsiClient.PhoneInfo.SubblockType.SN_IMEI_PLAIN };

            ll.send( req, ( msg ) => {
                parseSimpleString( msg, cb );
            } );
        }

        public void readVersion( owned StringResultFunc cb )
        {
            var req = new uchar[] { GIsiClient.PhoneInfo.MessageType.VERSION_READ_REQ, GIsiClient.PhoneInfo.SubblockType.MCUSW_VERSION };

            ll.send( req, ( msg ) => {
                parseSimpleString( msg, cb );
            } );

            // FIXME: This has more subblocks which need to be deciphered
        }

    }
} /* namespace GIsiComm */

