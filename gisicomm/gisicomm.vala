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

        internal struct ISI_SPN
        {
            uint16 name[17]; /* 16 +1 */
            uint8 disp_home;
            uint8 disp_roam;
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

                ISI_SPN* isispn;
                if ( !msg.data_get_struct( 2, out isispn, sizeof(ISI_SPN) ) )
                {
                    cb( ErrorCode.INVALID_FORMAT, null );
                    return;
                }

                uint8 spn[17];
                spn[0] = '?';

                for ( int i = 0; i < 16; ++i )
                {
                    //debug( "bytes at position %d are 0x%02X 0x%02X", i, isispn.name[i] & 0xff, isispn.name[i] >> 8 );
                    //uint16 c = isispn->name[i] >> 8 | isispn->name[i] << 8;

                    //spn[i] = ( c > 31 && c < 128 ) ? (uint8) c : '?';
                }

                cb( ErrorCode.OK, (string) spn );
            } );
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
            } );
        }
    }

    /**
     * @class Network
     *
     * Network Registration and Status Interface
     **/

    public class Network : AbstractBaseClient
    {
        private GIsiClient.Network ll;

        public signal void signalStrength( uint8 rssi );
        public signal void operatorName( string name );

        public struct ISI_RegStatus
        {
            GIsiClient.Network.RegistrationStatus status;
            GIsiClient.Network.OperatorSelectMode mode;
            string name;
            string lac;
            string cid;
            bool egprs;
            bool hsdpa;
            bool hsupa;
        }

        public Network( GIsi.Modem modem )
        {
            client = ll = modem.network_client_create();
        }

        protected override void onSubsystemIsReachable()
        {
            var ok = ll.ind_subscribe( GIsiClient.Network.MessageType.RSSI_IND, onSignalStrengthIndicationReceived );
            if ( !ok )
            {
                warning( "Could not subscribe to NET RSSI indications" );
            }
            ok = ll.ind_subscribe( GIsiClient.Network.MessageType.REG_STATUS_IND, onRegistrationStatusIndicationReceived );
            if ( !ok )
            {
                warning( "Could not subscribe to NET Status indications" );
            }
        }

        private ISI_RegStatus parseRegistrationStatusMessage( GIsi.Message msg )
        {
            ISI_RegStatus result = {};

            for ( GIsi.SubBlockIter sbi = msg.subblock_iter_create( 2 ); sbi.is_valid(); sbi.next() )
            {
                message( @"have subblock with ID $(sbi.id), length $(sbi.length)" );

                switch ( sbi.id )
                {
                    case 0xE3: /* operator display name */

                        uint8 length;
                        if ( !sbi.get_byte( out length, 5 ) )
                        {
                            continue;
                        }
                        debug( @"length = $length" );
                        length *= 2; // UCS-2
                        string str;
                        if ( !sbi.get_alpha_tag( out str, length, 6 ) )
                        {
                            continue;
                        }
                        message( @"OPER = $str" );
                        result.name = str;
                        break;

                    case GIsiClient.Network.SubblockType.REG_INFO_COMMON:

                        result.status = (GIsiClient.Network.RegistrationStatus) sbi.byte_at_position( 2 );
                        result.mode = (GIsiClient.Network.OperatorSelectMode) sbi.byte_at_position( 3 );

                        debug( @"regstatus = $(result.status)" );
                        debug( @"regmode = $(result.mode)" );
                        break;

                    case GIsiClient.Network.SubblockType.GSM_REG_INFO:

                        result.lac = "%0X".printf( sbi.word_at_position( 2 ) );
                        result.cid = "%0X".printf( sbi.dword_at_position( 4 ) >> 16 );
                        result.egprs = sbi.bool_at_position( 17 );
                        result.hsdpa = sbi.bool_at_position( 20 );
                        result.hsupa = sbi.bool_at_position( 21 );

                        debug( "lac = 0x%s, cid = 0x%s", result.lac, result.cid );
                        debug( @"edge = $(result.egprs), hsdpa = $(result.hsdpa), hsupa = $(result.hsupa)" );
                        break;

                    default:
                        message( @"FIXME: handle unknown subblock with ID $(sbi.id)" );
                        break;
                }
            }

            return result;
        }

        private void onRegistrationStatusIndicationReceived( GIsi.Message msg )
        {
            message( "NET Status indication received, iterating through subblocks" );
            var status = parseRegistrationStatusMessage( msg );

        }

        private void onSignalStrengthIndicationReceived( GIsi.Message msg )
        {
            message( "RSSI = %d", msg.data[0] );
            this.signalStrength( msg.data[0] );
        }
    }


} /* namespace GIsiComm */

