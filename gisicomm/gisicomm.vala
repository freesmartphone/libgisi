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
    public delegate void IntResultFunc( ErrorCode error, int result );

    public enum ErrorCode
    {
        OK,
        INVALID_FORMAT,
    }

    /**
     * @class AbstractBaseClient
     *
     * Handles initial setup and indicator/notification subscriptions
     **/

    public abstract class AbstractBaseClient
    {
        protected unowned GIsi.Client client;

        public AbstractBaseClient()
        {
            Idle.add( () => {
                onIdle(); return false;
            } );
        }

        private void onIdle()
        {
            if ( client != null )
            {
                client.verify( onReachabilityResultReceived );
            }
        }

        private void onReachabilityResultReceived( GIsi.Message msg )
        {
            message( @"Reachability result: $msg" );
            if ( !msg.ok() )
            {
                warning( "Subsystem not reachable" );
                return;
            }
            onSubsystemIsReachable();
        }

        protected abstract void onSubsystemIsReachable();
    }

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

    /**
     * @class PhoneInfo
     *
     * Device Information Interface
     **/

    public class PhoneInfo : AbstractBaseClient
    {
        protected GIsiClient.PhoneInfo ll;

        public PhoneInfo( GIsi.Modem modem )
        {
            client = ll = modem.phone_info_client_create();
        }

        protected override void onSubsystemIsReachable()
        {
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

    /**
     * @class SIMAuth
     *
     * SIM Authorization Interface
     **/

    public class SIMAuth : AbstractBaseClient
    {
        protected GIsiClient.SIMAuth ll;
        private bool ready;

        public SIMAuth( GIsi.Modem modem )
        {
            client = ll = modem.sim_auth_client_create();
        }

        protected override void onSubsystemIsReachable()
        {
            // gather initial SIM status
            queryStatus( ( error, result ) => {
                debug( @"received SIM status result $result" );
            } );

            ready = true;
        }

        private void onIndicationReceived( GIsi.Message msg )
        {
            message( @"Received Indication with message $msg" );
        }

        //
        // public API
        //
        public void queryStatus( owned IntResultFunc cb )
        {
            var req = new uchar[] { GIsiClient.SIMAuth.MessageType.STATUS_REQ, 0x0, 0x0 };
            ll.send_with_timeout( req, GIsiClient.SIMAuth.TIMEOUT, ( msg ) => {
                if ( !msg.ok() )
                {
                    cb( (ErrorCode) msg.error, 0 );
                    return;
                }

                switch ( msg.data[0] )
                {
                    case GIsiClient.SIMAuth.StatusResponse.NEED_PIN:
                    case GIsiClient.SIMAuth.StatusResponse.NEED_PUK:
                    case GIsiClient.SIMAuth.StatusResponse.INIT:
                        cb( ErrorCode.OK, msg.data[0] );
                        break;

                    case GIsiClient.SIMAuth.StatusResponse.RUNNING:
                        switch ( msg.data[1] )
                        {
                            case GIsiClient.SIMAuth.StatusResponseRunningType.AUTHORIZED:
                            case GIsiClient.SIMAuth.StatusResponseRunningType.UNPROTECTED:
                            case GIsiClient.SIMAuth.StatusResponseRunningType.NO_SIM:
                                cb( ErrorCode.OK, msg.data[1] );
                                break;

                            default:
                                error( "Unknown SIMAuth.StatusResponseRunningType %d", msg.data[1] );
                                cb( ErrorCode.INVALID_FORMAT, 0 );
                        }
                        break;

                    default:
                        error( "Unknown SIMAuth.StatusResponse %d", msg.data[0] );
                        cb( ErrorCode.INVALID_FORMAT, 0 );
                        break;
                }
            } );
    	}
    }

    /**
     * @class SIM
     *
     * SIM Data Interface
     **/

    public class SIM : AbstractBaseClient
    {
        private GIsiClient.SIM ll;

        internal struct ISI_IMSI
        {
            uint8 length;
            uint8 imsi[8];
        }

        public SIM( GIsi.Modem modem )
        {
            client = ll = modem.sim_client_create();
        }

        protected override void onSubsystemIsReachable()
        {
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

        public void readIMSI( owned StringResultFunc cb )
        {
            var req = new uchar[] { GIsiClient.SIM.MessageType.IMSI_REQ_READ_IMSI, GIsiClient.SIM.ServiceType.READ_IMSI };

            ll.send( req, ( msg ) => {
                if ( !msg.ok() )
                {
                    cb( (ErrorCode) msg.error, null );
                    return;
                }
                else
                {
                    ISI_IMSI* isiimsi;
                    if ( !msg.data_get_struct( 2, out isiimsi, sizeof(ISI_IMSI) ) )
                    {
                        cb( ErrorCode.INVALID_FORMAT, null );
                        return;
                    }

                    var imsi = new uint8[GIsiClient.SIM.MAX_IMSI_LENGTH+1];

                    /* Ignore the low-order semi-octet of the first byte */
                    imsi[0] = ((isiimsi->imsi[0] & 0xF0) >> 4) + '0';

                    size_t j = 1;

                    for ( size_t i = 1; i < isiimsi->length && j < GIsiClient.SIM.MAX_IMSI_LENGTH; ++i )
                    {
                        char nibble;

                        imsi[j++] = (isiimsi->imsi[i] & 0x0F) + '0';
                        nibble = (isiimsi->imsi[i] & 0xF0) >> 4;
                        if (nibble != 0x0F)
                                imsi[j++] = nibble + '0';
                    }

                    imsi[j] = '\0';

                    cb( ErrorCode.OK, (string)imsi );
                }
            } );
        }
    }

} /* namespace GIsiComm */

