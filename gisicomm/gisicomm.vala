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

    /** Helpers **/

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

    public class PhoneInfo
    {
        private GIsiClient.PhoneInfo ll;

        public PhoneInfo( GIsi.Modem modem )
        {
            ll = modem.phone_info_client_create();
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

    public class SIM
    {
        private GIsiClient.SIM ll;

        public SIM( GIsi.Modem modem )
        {
            ll = modem.sim_client_create();
            var ok = ll.ind_subscribe( GIsiClient.SIM.MessageType.IND, onIndicationReceived );
            if ( !ok )
            {
                warning( "Could not subscribe to SIM indications" );
            }
        }

        private void onIndicationReceived( GIsi.Message msg )
        {
            message( @"Received Indication with message $msg" );
        }

        public void readHPLMN( owned StringResultFunc cb )
        {
            var req = new uchar[] { GIsiClient.SIM.MessageType.NETWORK_INFO_REQ, GIsiClient.SIM.ServiceType.READ_HPLMN, 0x0 };
            ll.send( req, ( msg ) => {
                if ( !msg.ok() )
                {
                    cb( (ErrorCode) msg.error, null );
                    return;
                }
                else
                {
                    cb( ErrorCode.OK, "yo" );
                }
            } );
        }

        public void readSPN( owned StringResultFunc cb )
        {
            var req = new uchar[] { GIsiClient.SIM.MessageType.SERV_PROV_NAME_REQ, GIsiClient.SIM.ServiceType.SIM_ST_READ_SERV_PROV_NAME, 0x0 };

            ll.send( req, ( msg ) => {
                if ( !msg.ok() )
                {
                    cb( (ErrorCode) msg.error, null );
                    return;
                }
                cb( ErrorCode.OK, "FSO TELEKOM" );
            } );

            /*
            for (i = 0; i < SIM_MAX_SPN_LENGTH; i++) {
                uint16_t c = resp->name[i] >> 8 | resp->name[i] << 8;

                if (c == 0)
                        c = 0xFF;
                else if (!g_ascii_isprint(c))
                        c = '?';

                spn[i + 1] = c;

            } );
            */
        }
    }


} /* namespace GIsiComm */

