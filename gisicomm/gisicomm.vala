/*
 *  Communication helper library for GISI
 *
 *  (C) 2009-2010 Nokia Corporation and/or its subsidiary(-ies).
 *  (C) 2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *  (C) 2011 Klaus 'MrMoku' Kurzmann <mok@fluxnetz.de>
 *
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

namespace GIsiComm
{
    public delegate void VoidResultFunc( ErrorCode error );
    public delegate void BoolResultFunc( ErrorCode error, bool yesOrNo );
    public delegate void StringResultFunc( ErrorCode error, string? result );
    public delegate void IntResultFunc( ErrorCode error, int result );
    public delegate void IsiRegStatusResultFunc( ErrorCode error, Network.ISI_RegStatus? status );
    public delegate void IsiProviderArrayResultFunc( ErrorCode error, Network.ISI_Provider[] providers );
    public delegate void MtcStatesResultFunc( ErrorCode error, GIsiClient.MTC.ModemState current, GIsiClient.MTC.ModemState target );
    public delegate void ByteArrayResultFunc( ErrorCode code, uint8[] array );

    public enum ErrorCode
    {
        OK = 0xE0,
        INVALID_FORMAT = 0xE1,
    }

    public enum OnlineStatus
    {
        UNKNOWN,
        NO,
        YES
    }

    /**
     * @class ModemAccess
     *
     * Covers modem and subsystems lifecycle
     **/

    public class ModemAccess
    {
        public GIsi.Modem m;
        protected OnlineStatus online;
        protected unowned GIsi.PhonetNetlink netlink;

        public GIsiComm.MTC mtc;
        public GIsiComm.PhoneInfo info;
        public GIsiComm.SIM sim;
        public GIsiComm.Call call;
        public GIsiComm.SIMAuth simauth;
        public GIsiComm.Network net;
        public GIsiComm.SS ss;
        public GIsiComm.GSS gss;
        public GIsiComm.GPDS gpds;

        public GIsiComm.EpocInfo epoc;

        public GIsiClient.MTC.ModemState state;

        public signal void netlinkChanged( bool online );

        private async GIsiClient.MTC.ModemState queryModemState()
        {
            bool ok = false;

            GIsiClient.MTC.ModemState current = 0xE3;
            GIsiClient.MTC.ModemState target = 0xE4;

            do
            {
                Timeout.add_seconds( 1, () => { queryModemState.callback(); return false; } );
                yield;

                mtc.readState( (error, c, t) => {
                    if ( error != ErrorCode.OK )
                    {
                        debug( "ERROR GETTING STATE" );
                    }
                    else
                    {
                        current = c;
                        target = t;
                        queryModemState.callback();
                    }
                } );

                yield;

                debug( @"MODEM STATE NOW $current, TARGET = $target" );

            } while ( current != target );

            return current;
        }

        private void onNetlinkStateChanged( GIsi.Modem modem, GIsi.PhonetLinkState state, string iface )
        {
            debug( @"NETLINK STATE = $state" );
            /* ignore the link going down on startup */
            if ( online == OnlineStatus.UNKNOWN && state == GIsi.PhonetLinkState.DOWN )
                return;
            online = ( state == GIsi.PhonetLinkState.UP ) ? OnlineStatus.YES : OnlineStatus.NO;
            this.netlinkChanged( online == OnlineStatus.YES );
        }

        public ModemAccess( string iface )
        {
            m = new GIsi.Modem( iface );
        }

        public async bool connect()
        {
            if ( m == null )
            {
                return false;
            }

            netlink = m.netlink_start( onNetlinkStateChanged );

            if ( netlink == null )
            {
                return false;
            }

            while ( online == OnlineStatus.UNKNOWN )
            {
                Timeout.add( 500, () => { connect.callback(); return false; } );
                debug( "waiting for netlink state to change..." );
                yield;
            }

            return online == OnlineStatus.YES;
        }

        public async void disconnect()
        {
            if ( m == null )
            {
                return;
            }

            if ( netlink != null )
            {
                netlink.stop();
            }
        }

        public async bool launch()
        {
            mtc = new GIsiComm.MTC( m );
            yield mtc.waitUntilSubsystemIsOnline();
            info = new GIsiComm.PhoneInfo( m );
            yield info.waitUntilSubsystemIsOnline();
            sim = new GIsiComm.SIM( m );
            yield sim.waitUntilSubsystemIsOnline();
            simauth = new GIsiComm.SIMAuth( m );
            yield simauth.waitUntilSubsystemIsOnline();
            call = new GIsiComm.Call( m );
            yield call.waitUntilSubsystemIsOnline();
            ss = new GIsiComm.SS( m );
            yield ss.waitUntilSubsystemIsOnline();
            gss = new GIsiComm.GSS( m );
            yield gss.waitUntilSubsystemIsOnline();
            net = new GIsiComm.Network( m );
            yield net.waitUntilSubsystemIsOnline();
            gpds = new GIsiComm.GPDS( m );
            yield gpds.waitUntilSubsystemIsOnline();

            epoc = new GIsiComm.EpocInfo( m );

            return ( mtc.reachable && info.reachable && sim.reachable && call.reachable && ss.reachable && gss.reachable && net.reachable && gpds.reachable );
        }

        public async bool startup()
        {
            var ok = false;
            mtc.startupSynq( ( error ) => {
                ok = ( error == ErrorCode.OK );
                startup.callback();
            } );
            yield;

            Timeout.add_seconds( 2, startup.callback );
            yield;

            return true;
        }

        public async bool poweron()
        {
            // nothing to do here
            return true;
        }

    }

    /**
     * @class AbstractBaseClient
     *
     * Handles initial setup and indicator/notification subscriptions
     **/

    public abstract class AbstractBaseClient
    {
        public bool reachable;
        public uint16 isiobj;
        protected unowned GIsi.Client client;

        public SourceFunc cb;

        public AbstractBaseClient()
        {
        }

        public async void waitUntilSubsystemIsOnline()
        {
            assert( client != null );
            client.verify( onReachabilityResultReceived );
            cb = waitUntilSubsystemIsOnline.callback;
            yield;
        }

        private void onReachabilityResultReceived( GIsi.Message msg )
        {
            message( @"Reachability result: $msg" );
            if ( !msg.ok() )
            {
                warning( "Subsystem not reachable" );
                reachable = false;
            }
            else
            {
                reachable = true;
                isiobj = msg.object;
                onSubsystemIsReachable();
            }
            cb();
            cb = null;
        }

        protected abstract void onSubsystemIsReachable();

        //
        // public API
        //
        public void sendGenericRequest( uint8[] req, ByteArrayResultFunc cb )
        {
            client.send( req, ( msg ) => {
                if ( !msg.ok() )
                {
                    cb( ErrorCode.INVALID_FORMAT, null );
                    return;
                }
                cb( ErrorCode.OK, msg.data );
            } );
        }

        public uint8 align4( uint8 size )
        {
            return (((size) + 3) & ~3);
        }

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
            cb( ErrorCode.INVALID_FORMAT, null );
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
     * @class MTC
     *
     * Power and Functionality control
     **/

    public class MTC : AbstractBaseClient
    {
        protected GIsiClient.MTC ll;
        public GIsiClient.MTC.ModemState state;

        public delegate void IsiCauseResultFunc( ErrorCode error, GIsiClient.MTC.IsiCause cause );

        public MTC( GIsi.Modem modem )
        {
            client = ll = modem.mtc_client_create();
            state = 0xE0;
        }

        protected override void onSubsystemIsReachable()
        {
            var ok = ll.ind_subscribe( GIsiClient.MTC.MessageType.STATE_INFO_IND, onStateInfoIndicationReceived );
            if ( !ok )
            {
                warning( "Could not subscribe to MTC STATE_INFO_IND" );
            }
            else
            {
                readState( ( error, current, target ) => {
                    if ( error == ErrorCode.OK )
                    {
                        this.state = current;
                        debug( @"initial state = $state" );
                    }
                    else
                    {
                        debug( "can't query initial state: error = %d", error );
                    }
                } );
            }
        }

        private void onStateInfoIndicationReceived( GIsi.Message msg )
        {
            GIsiClient.MTC.ModemState state = (GIsiClient.MTC.ModemState) msg.data[0];
            GIsiClient.MTC.IsiAction action = (GIsiClient.MTC.IsiAction) msg.data[1];
            message( @"Received state info indication with message $msg, state = $state, action = $action" );
            if ( action == GIsiClient.MTC.IsiAction.READY )
            {
                this.state = state;
            }
        }

        //
        // public API
        //
        public void readState( MtcStatesResultFunc cb )
        {
            var req = new uchar[] { GIsiClient.MTC.MessageType.STATE_QUERY_REQ, 0x00, 0x00 };

            ll.send( req, ( msg ) => {
                if ( !msg.ok() )
                {
                    debug( "error reading state" );
                    cb( ErrorCode.INVALID_FORMAT, (GIsiClient.MTC.ModemState) 0xE0, (GIsiClient.MTC.ModemState) 0xE1 );
                    return;
                }
                GIsiClient.MTC.ModemState current = (GIsiClient.MTC.ModemState) msg.data[0];
                GIsiClient.MTC.ModemState target = (GIsiClient.MTC.ModemState) msg.data[1];
                debug( @"reading state ok: current = $current, target = $target" );
                cb( ErrorCode.OK, current, target );
            } );
        }

        public void setState( bool on, bool online, IntResultFunc cb )
        {
            GIsiClient.MTC.ModemState state = GIsiClient.MTC.ModemState.NORMAL;
            if ( !on )
            {
                state = GIsiClient.MTC.ModemState.POWER_OFF;
            }
            if ( !online )
            {
                state = GIsiClient.MTC.ModemState.RF_INACTIVE;
            }

            var req = new uchar[] { GIsiClient.MTC.MessageType.STATE_REQ, state, 0x00 };

            ll.send_with_timeout( req, GIsiClient.MTC.STATE_REQ_TIMEOUT, ( msg ) => {
                if ( !msg.ok() )
                {
                    cb( ErrorCode.INVALID_FORMAT, 0xFF );
                    return;
                }
                GIsiClient.MTC.IsiCause cause = (GIsiClient.MTC.IsiCause) msg.data[0];
                cb( ErrorCode.OK, cause );
            } );
        }

        public void startupSynq( VoidResultFunc cb )
        {
            var req = new uchar[] { GIsiClient.MTC.MessageType.STARTUP_SYNQ_REQ, 0, 0 };
            ll.send( req, ( msg ) => {
                if ( !msg.ok() )
                {
                    cb( ErrorCode.INVALID_FORMAT );
                    return;
                }
                cb( ErrorCode.OK );
            } );
        }

        public void setPower( bool on, IsiCauseResultFunc cb )
        {
            var req = new uchar[] { on ? GIsiClient.MTC.MessageType.POWER_ON_REQ : GIsiClient.MTC.MessageType.POWER_OFF_REQ, 0x00, 0x00 };

            ll.send( req, ( msg ) => {
                if ( !msg.ok() )
                {
                    cb( ErrorCode.INVALID_FORMAT, 0 );
                    return;
                }
                GIsiClient.MTC.IsiCause cause = (GIsiClient.MTC.IsiCause) msg.data[0];
                debug( @"set power answer $cause" );
                cb( ErrorCode.OK, cause );
            } );
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

                for ( GIsi.SubBlockIter sbi = msg.subblock_iter_create( 2 ); sbi.is_valid(); sbi.next() )
                {
                    string sbtype = ( (GIsiClient.PhoneInfo.SubblockType) sbi.id).to_string() ?? "unknown";

                    message( @"Got subblock $sbtype (0x%02X) w/ length $(sbi.length)", sbi.id );
                }
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

            // subscribe to indications
            var ok = ll.ind_subscribe( GIsiClient.SIMAuth.MessageType.STATUS_IND, onIndicationReceived );
            if ( !ok )
            {
                warning( "Could not subscribe to SIM indications" );
            }
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
                    cb( ErrorCode.INVALID_FORMAT, 0 );
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
                                error( "Unknown SIMAuth.StatusResponseRunningType 0x%0X", msg.data[1] );
                                cb( ErrorCode.INVALID_FORMAT, 0 );
                        }
                        break;

                    default:
                        error( "Unknown SIMAuth.StatusResponse 0x%0Xd", msg.data[0] );
                        cb( ErrorCode.INVALID_FORMAT, 0 );
                        break;
                }
            } );
    	}

        public void sendPin( string pin, owned IntResultFunc cb )
        {
            var req = new uchar[] { GIsiClient.SIMAuth.MessageType.REQ, GIsiClient.SIMAuth.SubblockType.REQ_PIN,
                                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		                            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                            		0x00, 0x00, 0x00, 0x00 };

            uchar* p = req;

            GLib.Memory.copy( p+2, pin.data, pin.length );

            ll.send_with_timeout( req, GIsiClient.SIMAuth.TIMEOUT, ( msg ) => {
                if ( !msg.ok() )
                {
                    cb( ErrorCode.INVALID_FORMAT, 0 );
                    return;
                }

                switch ( msg.id )
                {
                    case GIsiClient.SIMAuth.MessageType.FAIL_RESP:
                        switch ( msg.data[0] )
                        {
                            case GIsiClient.SIMAuth.ErrorType.INVALID_PW:
                            case GIsiClient.SIMAuth.ErrorType.NEED_PUK:
                                cb( ErrorCode.OK, msg.data[0] );
                                break;

                            default:
                                error( "Unknown SIMAuth.IsiCause 0x%0X", msg.data[0] );
                                cb( ErrorCode.INVALID_FORMAT, 0 );
                        }
                        break;

                    case GIsiClient.SIMAuth.MessageType.SUCCESS_RESP:
                        switch ( msg.data[0] )
                        {
                            case GIsiClient.SIMAuth.IndicationType.OK:
                                cb( ErrorCode.OK, msg.data[0] );
                                break;

                            default:
                                error( "Unknown SIMAuth.IndicationType 0x%0X", msg.data[0] );
                                cb( ErrorCode.INVALID_FORMAT, 0 );
                        }
                        break;

                    default:
                        error( "Unknown Send PIN response message ID 0x%0X", msg.id );
                        cb( ErrorCode.INVALID_FORMAT, 0 );
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
                    cb( ErrorCode.INVALID_FORMAT, null );
                    return;
                }
                if ( msg.data[1] == GIsiClient.SIM.IsiCause.SERV_DATA_NOT_AVAIL )
                {
                    cb( ErrorCode.OK, "<unknown>" );
                    return;
                }
                if ( msg.data[1] != GIsiClient.SIM.IsiCause.SERV_OK )
                {
                    cb( ErrorCode.INVALID_FORMAT, null );
                    return;
                }

                uint8 digits12 = msg.data[2];
                uint8 digits3 = msg.data[3] & 0x0F;
                uint8 digits45 = msg.data[4];

                uchar result[6];
                result[0] = '0' + ( digits12 & 0xF );
                result[1] = '0' + ( digits12 >> 4 );
                result[2] = '0' + digits3;
                result[3] = '0' + ( digits45 & 0xF );
                result[4] = '0' + ( digits45 >> 4 );
                result[5] = '\0';

                cb( ErrorCode.OK, (string)result );
            } );
        }

        public void readSPN( owned StringResultFunc cb )
        {
            var req = new uchar[] { GIsiClient.SIM.MessageType.SERV_PROV_NAME_REQ, GIsiClient.SIM.ServiceType.SIM_ST_READ_SERV_PROV_NAME, 0x0 };

            ll.send( req, ( msg ) => {
                if ( !msg.ok() )
                {
                    cb( ErrorCode.INVALID_FORMAT, null );
                    return;
                }
                if ( msg.data[1] == GIsiClient.SIM.IsiCause.SERV_DATA_NOT_AVAIL )
                {
                    cb( ErrorCode.OK, "<unknown>" );
                    return;
                }
                if ( msg.data[1] != GIsiClient.SIM.IsiCause.SERV_OK )
                {
                    cb( ErrorCode.INVALID_FORMAT, null );
                    return;
                }

                ISI_SPN* isispn;
                if ( !msg.data_get_struct( 2, out isispn, sizeof(ISI_SPN) ) )
                {
                    cb( ErrorCode.INVALID_FORMAT, null );
                    return;
                }

                uint8 spn[17];

                for ( int i = 0; i < 16; ++i )
                {
                    uint16 c = isispn->name[i] >> 8 | isispn->name[i] << 8;
                    spn[i] = ( c > 31 && c < 128 ) ? (uint8) c : '?';
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
                    cb( ErrorCode.INVALID_FORMAT, null );
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
        public signal void registrationStatus( ISI_RegStatus status );
        public signal void timeInfo( GLib.Time time );

        public struct ISI_Provider
        {
            GIsiClient.Network.OperatorStatus status;
            string name;
            string mcc;
            string mnc;
            int technology;
        }

        public struct ISI_RegStatus
        {
            GIsiClient.Network.RegistrationStatus status;
            GIsiClient.Network.OperatorSelectMode mode;
            string network;
            string name;
            string lac;
            string cid;
            string mcc;
            string mnc;
            uint band;
            bool egprs;
            bool hsdpa;
            bool hsupa;
        }

        public struct ISI_Time
        {
            uint8 year;
            uint8 mon;
            uint8 mday;
            uint8 hour;
            uint8 min;
            uint8 sec;
            uint8 utc;
            uint8 dst;
        }

        public Network( GIsi.Modem modem )
        {
            client = ll = modem.network_client_create();
        }

        protected override void onSubsystemIsReachable()
        {
            // FIXME: For Debugging only
            //return;

            ll.ind_subscribe( GIsiClient.Network.MessageType.RSSI_IND, onSignalStrengthIndicationReceived );
            ll.ind_subscribe( GIsiClient.Network.MessageType.REG_STATUS_IND, onRegistrationStatusIndicationReceived );
            ll.ind_subscribe( GIsiClient.Network.MessageType.RAT_IND, onRadioAccessTechnologyIndicationReceived );
            ll.ind_subscribe( GIsiClient.Network.MessageType.TIME_IND, onTimeIndicationReceived );

            queryRat( ( error, result ) => {
                debug( "query rat done, error = %d", error );
                queryStatus( ( error, result ) => {
                    debug( "query status done, error = %d", error );
                } );
            } );
        }

        private ISI_RegStatus parseRegistrationStatusMessage( GIsi.Message msg )
        {
            ISI_RegStatus result = {};

            for ( GIsi.SubBlockIter sbi = msg.subblock_iter_create( 2 ); sbi.is_valid(); sbi.next() )
            {
                message( @"Have subblock with ID $(sbi.id), length $(sbi.length)" );

                switch ( sbi.id )
                {
                    case GIsiClient.Network.SubblockType.GSM_REG_NETWORK_INFO:

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

                        uint8 nNames = sbi.byte_at_position( 4 );
                        debug( @"# of alternative names: $nNames" );

                        if ( result.status == GIsiClient.Network.RegistrationStatus.HOME ||
                             result.status == GIsiClient.Network.RegistrationStatus.ROAM ||
                             result.status == GIsiClient.Network.RegistrationStatus.ROAM_BLINK )
                        {
                            result.network = sbi.alpha_tag_at_position( sbi.byte_at_position( 7 ) * 2, 8 );
                            debug( @"regname = $(result.network)" );
                        }
                        else
                        {
                            debug( "not looking for regname, since we're not camped" );
                        }

                        break;

                    case GIsiClient.Network.SubblockType.GSM_REG_INFO:

                        result.lac = "%04X".printf( sbi.word_at_position( 2 ) );
                        result.cid = "%04X".printf( sbi.dword_at_position( 4 ) >> 16 );

                        sbi.oper_code_at_position( out result.mcc, out result.mnc, 8 );
                        debug( @"mccmnc = $(result.mcc)$(result.mnc)" );

                        switch ( sbi.byte_at_position( 11 ) )
                        {
                            case 1:
                                result.band = 900;
                                break;
                            case 2:
                                result.band = 1800;
                                break;
                            case 4:
                                result.band = 1900;
                                break;
                            case 8:
                                result.band = 850;
                                break;
                            default:
                                result.band = 0;
                                break;
                        }
                        debug( @"band = $(result.band)" );

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

        private void onRadioAccessTechnologyIndicationReceived( GIsi.Message msg )
        {
            message( @"NET RAT IND $msg received, iterating through subblocks" );

            for ( GIsi.SubBlockIter sbi = msg.subblock_iter_create( 2 ); sbi.is_valid(); sbi.next() )
            {
                message( @"Have subblock with ID $(sbi.id), length $(sbi.length)" );

                switch ( sbi.id )
                {
                    case GIsiClient.Network.SubblockType.RAT_INFO:
                        message( @"FIXME: RAT 0x%0X detected", sbi.byte_at_position( 2 ) );
                        break;

                    default:
                        message( @"FIXME: handle unknown subblock with ID $(sbi.id)" );
                        break;

                }
            }
        }

        private void onTimeIndicationReceived( GIsi.Message msg )
        {
            message( @"NET TIME IND $msg received, iterating through subblocks" );

            for ( GIsi.SubBlockIter sbi = msg.subblock_iter_create( 2 ); sbi.is_valid(); sbi.next() )
            {
                message( @"Have subblock with ID $(sbi.id), length $(sbi.length)" );

                switch ( sbi.id )
                {
                    case GIsiClient.Network.SubblockType.TIME_INFO:

                        var isitime = ISI_Time();
                        if ( !sbi.get_struct( &isitime, sizeof( ISI_Time ), 2 ) )
                        {
                            continue;
                        }

                        var t = GLib.Time();

                        /* Value is years since last turn of century */
                        t.year = isitime.year != GIsiClient.Network.INVALID_TIME ? isitime.year : -1;
                        t.year += 2000;

                        t.month = isitime.mon != GIsiClient.Network.INVALID_TIME ? isitime.mon : -1;
                        t.day = isitime.mday != GIsiClient.Network.INVALID_TIME ? isitime.mday : -1;
                        t.hour = isitime.hour != GIsiClient.Network.INVALID_TIME ? isitime.hour : -1;
                        t.minute = isitime.min != GIsiClient.Network.INVALID_TIME ? isitime.min : -1;
                        t.second = isitime.sec != GIsiClient.Network.INVALID_TIME ? isitime.sec : -1;
                        t.isdst = isitime.dst != GIsiClient.Network.INVALID_TIME ? isitime.dst : -1;

                        /* Most significant bit set indicates negative offset. The
                         * second most significant bit is 'reserved'. The value is the
                         * offset from UTC in a count of 15min intervals, possibly
                         * including the current DST adjustment.
                        t.utcoff = (time->utc & 0x3F) * 15 * 60;
                        if (time->utc & 0x80)
                                t.utcoff *= -1;
                        */

                        this.timeInfo( t );

                        break;

                    default:
                        message( @"FIXME: handle unknown subblock with ID $(sbi.id)" );
                        break;
                }
            }
        }

        private void onRegistrationStatusIndicationReceived( GIsi.Message msg )
        {
            message( @"NET Status IND $msg received, iterating through subblocks" );
            var status = parseRegistrationStatusMessage( msg );
            this.registrationStatus( status );
        }

        private void onSignalStrengthIndicationReceived( GIsi.Message msg )
        {
            message( "RSSI = %d", msg.data[0] );
            this.signalStrength( msg.data[0] );
        }

        //
        // public API
        //
        public void queryStatus( owned IsiRegStatusResultFunc cb )
        {
            var req = new uchar[] { GIsiClient.Network.MessageType.REG_STATUS_GET_REQ };

            ll.send( req, ( msg ) => {
                if ( !msg.ok() )
                {
                    cb( ErrorCode.INVALID_FORMAT, null );
                    return;
                }

                var status = parseRegistrationStatusMessage( msg );
                cb( ErrorCode.OK, status );
            } );
        }

        public void queryStrength( owned IntResultFunc cb )
        {
            var req = new uchar[] { GIsiClient.Network.MessageType.RSSI_GET_REQ, GIsiClient.Network.CsType.GSM, GIsiClient.Network.MeasurementType.CURRENT_CELL_RSSI };
            // FIXME: PN_MODEM_NETWORK would need four additional filler bytes

            ll.send( req, ( msg ) => {
                if ( !msg.ok() )
                {
                    cb( ErrorCode.INVALID_FORMAT, -1 );
                    return;
                }

                for ( GIsi.SubBlockIter sbi = msg.subblock_iter_create( 2 ); sbi.is_valid(); sbi.next() )
                {
                    message( @"Have subblock with ID $(sbi.id), length $(sbi.length)" );

                    if ( sbi.id == GIsiClient.Network.SubblockType.RSSI_CURRENT )
                    {
                        cb( ErrorCode.OK, sbi.byte_at_position( 2 ) );
                        break;
                    }
                }
            } );
        }

        public void listProviders( owned IsiProviderArrayResultFunc cb )
        {
            var req = new uchar[] {
                GIsiClient.Network.MessageType.AVAILABLE_GET_REQ,
                GIsiClient.Network.SearchMode.MANUAL_SEARCH,
                0x01,  /* Sub-block count */
                GIsiClient.Network.SubblockType.GSM_BAND_INFO,
                0x04,  /* Sub-block length */
                GIsiClient.Network.GsmBandInfo.ALL_SUPPORTED_BANDS,
                0x00
            };

            ll.send_with_timeout( req, GIsiClient.Network.SCAN_TIMEOUT, ( msg ) => {
                if ( !msg.ok() )
                {
                    cb( ErrorCode.INVALID_FORMAT, null );
                    return;
                }

                var providers = new ISI_Provider[] {};
                uint index = 0;

                for ( GIsi.SubBlockIter sbi = msg.subblock_iter_create( 2 ); sbi.is_valid(); sbi.next() )
                {
                    message( @"Have subblock with ID $(sbi.id), length $(sbi.length)" );

                    switch ( sbi.id )
                    {
                        case GIsiClient.Network.SubblockType.AVAIL_NETWORK_INFO_COMMON:

                            var newp = ISI_Provider();
                            newp.name = sbi.alpha_tag_at_position( sbi.byte_at_position( 5 ) * 2, 6 );
                            newp.status = (GIsiClient.Network.OperatorStatus) sbi.byte_at_position( 2 );
                            providers += newp;
                            break;

                        case GIsiClient.Network.SubblockType.DETAILED_NETWORK_INFO:

                            ISI_Provider* p = &providers[index];
                            sbi.oper_code_at_position( out p.mcc, out p.mnc, 2 );
                            p.technology = sbi.byte_at_position( 7 ) != 0 ? 2 : 3;
                            index++;

                            break;

                        default:
                            message( @"FIXME: handle unknown subblock with ID $(sbi.id)" );
                            break;
                    }
                }

                foreach ( var prov in providers )
                {
                    debug( @"found provider $(prov.name) [$(prov.mcc)$(prov.mnc)] with status $(prov.status)" );
                }

                cb( ErrorCode.OK, providers );
            } );
        }

        public void registerAutomatic( bool force, owned VoidResultFunc cb )
        {
            var req = new uchar[] {
                GIsiClient.Network.MessageType.SET_REQ,
                0x00,  /* Registered in another protocol? */
                0x01,  /* Sub-block count */
                GIsiClient.Network.SubblockType.OPERATOR_INFO_COMMON,
                0x04,  /* Sub-block length */
                force ? GIsiClient.Network.OperatorSelectMode.USER_RESELECTION : GIsiClient.Network.OperatorSelectMode.AUTOMATIC,
                0x00  /* Index not used */
            };

            ll.send_with_timeout( req, GIsiClient.Network.SET_TIMEOUT, ( msg ) => {
                if ( !msg.ok() )
                {
                    cb( ErrorCode.INVALID_FORMAT );
                    return;
                }
                cb( ErrorCode.OK );
            } );
        }

        public void registerManual( string mcc, string mnc, owned VoidResultFunc cb )
        {
            debug( @"mcc = $mcc, mnc = $mnc" );

            uint8 bcd[3] = { 0, 0, 0 };
            bcd[0] = (mcc[0] - '0') | (mcc[1] - '0') << 4;
            bcd[1] = (mcc[2] - '0');
            bcd[1] |= (mnc[2] == '\0' ? 0x0f : (mnc[2] - '0')) << 4;
            bcd[2] = (mnc[0] - '0') | (mnc[1] - '0') << 4;

            var req = new uchar[] {
                GIsiClient.Network.MessageType.SET_REQ,
                0x00,  /* Registered in another protocol? */
                0x02,  /* Sub-block count */
                GIsiClient.Network.SubblockType.OPERATOR_INFO_COMMON,
                0x04,  /* Sub-block length */
                GIsiClient.Network.OperatorSelectMode.MANUAL,
                0x00,  /* Index not used */
                GIsiClient.Network.SubblockType.GSM_OPERATOR_INFO,
                0x08,  /* Sub-block length */
                bcd[0], bcd[1], bcd[2],
                GIsiClient.Network.GsmBandInfo.INFO_NOT_AVAIL,  /* Pick any supported band */
                0x00, 0x00  /* Filler */
            };

            ll.send_with_timeout( req, GIsiClient.Network.SET_TIMEOUT, ( msg ) => {
                if ( !msg.ok() )
                {
                    cb( ErrorCode.INVALID_FORMAT );
                    return;
                }
                cb( ErrorCode.OK );
            } );
        }

        public void queryRat( owned IntResultFunc cb )
        {
            var req = new uchar[] { GIsiClient.Network.MessageType.RAT_REQ, GIsiClient.Network.RatType.CURRENT_RAT };
            ll.send( req, ( msg ) => {
                if ( !msg.ok() )
                {
                    cb( ErrorCode.INVALID_FORMAT, -1 );
                    return;
                }

                for ( GIsi.SubBlockIter sbi = msg.subblock_iter_create( 2 ); sbi.is_valid(); sbi.next() )
                {
                    message( @"Have subblock with ID $(sbi.id), length $(sbi.length)" );

                    switch ( sbi.id )
                    {
                        default:
                            message( @"FIXME: handle unknown subblock with ID $(sbi.id)" );
                            break;
                    }
                }

                cb( ErrorCode.OK, 0 );

            } );
        }
    }

    /**
     * @class Call
     *
     * Call Handling
     **/

    public class Call : AbstractBaseClient
    {
        private GIsiClient.Call ll;

        public struct ISI_CallStatus
        {
            uint8 id;
            GIsiClient.Call.Status status;
            uint8 ntype;
            string number;
        }

        public signal void statusChanged( ISI_CallStatus status );

        public Call( GIsi.Modem modem )
        {
            client = ll = modem.call_client_create();
        }

        protected override void onSubsystemIsReachable()
        {
            /*
            COMING_IND,
            MO_ALERT_IND,
            MT_ALERT_IND,
            WAITING_IND,
            ANSWER_REQ,
            ANSWER_RESP,
            RELEASE_REQ,
            RELEASE_RESP,
            RELEASE_IND,
            TERMINATED_IND,
            STATUS_REQ,
            STATUS_RESP,
            STATUS_IND,
            SERVER_STATUS_IND,
            CONTROL_REQ,
            CONTROL_RESP,
            CONTROL_IND,
            MODE_SWITCH_REQ,
            MODE_SWITCH_RESP,
            MODE_SWITCH_IND,
            DTMF_SEND_REQ,
            DTMF_SEND_RESP,
            DTMF_STOP_REQ,
            DTMF_STOP_RESP,
            DTMF_STATUS_IND,
            DTMF_TONE_IND,
            RECONNECT_IND,
            */


            /*
            var ok = ll.ind_subscribe( GIsiClient.Call.MessageType.COMING_IND, onComingIndicationReceived );
            if ( !ok )
            {
                warning( "Could not subscribe to CALL_COMING_IND" );
            }
            ok = ll.ind_subscribe( GIsiClient.Call.MessageType.MT_ALERT_IND, onMTAlertIndicationReceived );
            if ( !ok )
            {
                warning( "Could not subscribe to CALL_MT_ALERT_IND" );
            }
            */
            var ok = ll.ind_subscribe( GIsiClient.Call.MessageType.STATUS_IND, onStatusIndicationReceived );
            if ( !ok )
            {
                warning( "Could not subscribe to CALL_STATUS_IND" );
            }
            ok = ll.ind_subscribe( GIsiClient.Call.MessageType.TERMINATED_IND, onTerminatedIndicationReceived );
            if ( !ok )
            {
                warning( "Could not subscribe to CALL_TERMINATED_IND" );
            }
        }

        private ISI_CallStatus parseCallStatus( GIsi.Message msg )
        {
            uint8 id;
            var status = ISI_CallStatus();

            msg.data_get_byte( 1, out id );
            status.id = id & 0x07;

            for ( GIsi.SubBlockIter sbi = msg.subblock_iter_create( 2 ); sbi.is_valid(); sbi.next() )
            {
                message( @"Have subblock with ID $(sbi.id), length $(sbi.length)" );

                switch ( sbi.id )
                {
                    case GIsiClient.Call.SubblockType.MODE:
                        GIsiClient.Call.Mode m = (GIsiClient.Call.Mode) sbi.byte_at_position( 2 );
                        GIsiClient.Call.ModeInfo mi = (GIsiClient.Call.ModeInfo) sbi.byte_at_position( 3 );
                        debug( @"call mode is $m (0x%0X)", m );
                        debug( @"call mode_info is $mi (0x%0X)", mi );
                        break;

                    case GIsiClient.Call.SubblockType.STATUS:
                        status.status = (GIsiClient.Call.Status) sbi.byte_at_position( 2 );
                        debug( @"call status is $(status.status) (0x%0X)", sbi.byte_at_position( 2 ) );
                        break;

                    case GIsiClient.Call.SubblockType.ORIGIN_ADDRESS:
                        status.ntype = sbi.byte_at_position( 2 ) | 0x80;
                        uint8 presentation = sbi.byte_at_position( 3 );
                        status.number = sbi.alpha_tag_at_position( sbi.byte_at_position( 5 ) * 2, 6 );
                        debug( "call origin is type 0x%0X, presentation 0x%0X, number %s", status.ntype, presentation, status.number );
                        break;

                    default:
                        debug( @"FIXME: handle unhandled subblock with id $(sbi.id)" );
                        break;
                }
            }

            return status;
        }

        private void onStatusIndicationReceived( GIsi.Message msg )
        {
            message( @"$msg received" );
            this.statusChanged( parseCallStatus( msg ) );
        }

        private void onTerminatedIndicationReceived( GIsi.Message msg )
        {
            message( @"$msg received" );
            msg.dump();
            //parseCallStatus( msg );
        }

        //
        // public API
        //

        public void initiateVoiceCall( string number, uint8 ntype, GIsiClient.Call.PresentationType presentation, VoidResultFunc cb )
        {
            size_t addr_len = number.length;
            size_t sub_len = (6 + 2 * addr_len + 3) & ~3;
            size_t offset = 3 + 4 + 8 + 6;

            var req = new uchar[] {
                GIsiClient.Call.MessageType.CREATE_REQ,
                0,              /* No id */
                3,              /* Mode, Clir, Number */
                /* MODE SB */
                GIsiClient.Call.SubblockType.MODE, 4, GIsiClient.Call.Mode.SPEECH, GIsiClient.Call.ModeInfo.NONE,
                /* ORIGIN_INFO SB */
                GIsiClient.Call.SubblockType.ORIGIN_INFO, 8, presentation, 0, 0, 0, 0, 0,
                /* DESTINATION_ADDRESS SB */
                GIsiClient.Call.SubblockType.DESTINATION_ADDRESS,
                (uchar)sub_len,
                (uchar)ntype & 0x7F,
                0, 0,
                (uchar)addr_len,
                0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0
            };

            size_t rlen = 3 + 4 + 8 + sub_len;
            for ( int i = 0; i < addr_len; ++i )
            {
                req[offset + 2 * i + 1] = number[i];
            }

            ll.send( req, ( msg ) => {
                if ( !msg.ok() )
                {
                    cb( ErrorCode.INVALID_FORMAT );
                    return;
                }
                cb( ErrorCode.OK );
            } );
        }

        public void releaseVoiceCall( uint8 callid, GIsiClient.Call.CauseType causeType, GIsiClient.Call.IsiCause causeValue, VoidResultFunc cb )
        {

            var req = new uchar[] {
                GIsiClient.Call.MessageType.RELEASE_REQ,
                callid,
                1,      /* Sub-block count */
                GIsiClient.Call.SubblockType.CAUSE,
                4,      /* Sub-block length */
                causeType,
                causeValue
            };

            ll.send( req, ( msg ) => {
                if ( !msg.ok() )
                {
                    cb( ErrorCode.INVALID_FORMAT );
                    return;
                }
                cb( ErrorCode.OK );
            } );
        }

        public void answerVoiceCall( uint8 callid, VoidResultFunc cb )
        {
            var req = new uchar[] { GIsiClient.Call.MessageType.ANSWER_REQ, callid, 0x0 };

            ll.send( req, ( msg ) => {
                if ( !msg.ok() )
                {
                    cb( ErrorCode.INVALID_FORMAT );
                    return;
                }

                debug( "answer msg return code 0x%0X", msg.data[0] );

                cb( ErrorCode.OK );
            } );
        }

        public void controlVoiceCall( uint8 callid, GIsiClient.Call.Operation operation, uint8 param, VoidResultFunc cb )
        {
            var req = new uchar[] {
                GIsiClient.Call.MessageType.CONTROL_REQ,
                callid,
                1, /* #subblocks */
                GIsiClient.Call.SubblockType.OPERATION, 4, operation, param
            };

            ll.send( req, ( msg ) => {
                if ( !msg.ok() )
                {
                    cb( ErrorCode.INVALID_FORMAT );
                    return;
                }

                debug( "control voice call msg return code 0x%0X", msg.data[0] );

                cb( ErrorCode.OK );
            } );
        }

        public void sendTonesOnVoiceCall( uint8 callid, string tones, VoidResultFunc cb )
        {
            size_t str_len = (uint8) tones.length;
            size_t sub_len = 4 + ((2 * str_len + 3) & ~3);
            size_t offset = 3 + 4 + 8 + 4;
            size_t rlen = 3 + 4 + 8 + sub_len;

            var req = new uint8[] {
                    GIsiClient.Call.MessageType.DTMF_SEND_REQ,
                    callid,
                    3, /* #subblocks */
                    GIsiClient.Call.SubblockType.DTMF_INFO, 4, GIsiClient.Call.DTMFIndicationType.ENABLE_TONE_IND_SEND, 0,
                    GIsiClient.Call.SubblockType.DTMF_TIMERS, 8,
                    0, 200, /* duration in ms */
                    0, 100, /* gap in ms */
                    0, 0,   /* filler */
                    GIsiClient.Call.SubblockType.DTMF_STRING, (uint8) sub_len,
                    100,     /* pause length */
                    (uint8) str_len,
                    /* string */
                    0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                    0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                    0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                    0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                    0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                    0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                    0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                    0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                    0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                    0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                    0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                    0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                    0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0
            };

            for ( int i = 0; i < str_len; ++i )
            {
                req[offset + 2 * i + 1] = tones[i];
            }

            ll.send( req, ( msg ) => {
                if ( !msg.ok() )
                {
                    cb( ErrorCode.INVALID_FORMAT );
                    return;
                }

                debug( "send tones msg return code 0x%0X", msg.data[0] );

                cb( ErrorCode.OK );
            } );
        }
    }

    /**
     * @class GSS
     *
     * General Stack Server
     **/

    public class GSS : AbstractBaseClient
    {
        private GIsiClient.GSS ll;

        public GSS( GIsi.Modem modem )
        {
            client = ll = modem.gss_client_create();
        }

        protected override void onSubsystemIsReachable()
        {
        }
    }

    /**
     * @class SS
     *
     * Stack Server
     **/

    public class SS : AbstractBaseClient
    {
        private GIsiClient.SS ll;

        public SS( GIsi.Modem modem )
        {
            client = ll = modem.ss_client_create();
        }

        protected override void onSubsystemIsReachable()
        {
            ll.ind_subscribe( GIsiClient.SS.MessageType.STATUS_IND, onStatusIndicationReceived );
            ll.ind_subscribe( GIsiClient.SS.MessageType.GSM_USSD_RECEIVE_IND, onUssdReceiveIndicationReceived );
        }

        private void onStatusIndicationReceived( GIsi.Message msg )
        {
            message( @"$msg received" );
        }

        private void onUssdReceiveIndicationReceived( GIsi.Message msg )
        {
            message( @"$msg received" );
        }
    }

    public class GPDSHelper
    {
        public GPDS instance;
        public SourceFunc cb;

        public GPDSHelper( GPDS instance, SourceFunc cb )
        {
            this.instance = instance;
            this.cb = cb;
        }
    }

    /**
     * @class GSS
     *
     * General Stack Server
     **/
    public class GPDS : AbstractBaseClient
    {
        private GIsiClient.GPDS ll;
        private GIsi.PEP pep;
        private GIsi.Pipe pipe;
        private uint8 ctxid;
        private GPDSHelper helper;

        public signal void contextActivated( string iface, string ip, string dns1, string dns2 );
        public signal void contextDeactivated();

        private static void onPipeCreated( GIsi.Pipe p )
        {
            debug( "on pipe created" );
            var helper = (GPDSHelper) p.get_userdata();
            helper.cb();
        }

        public GPDS( GIsi.Modem modem )
        {
            client = ll = modem.gpds_client_create();
        }

        protected override void onSubsystemIsReachable()
        {
            ll.ind_subscribe( GIsiClient.GPDS.MessageType.DETACH_IND, onDetachIndicationReceived );
            ll.ind_subscribe( GIsiClient.GPDS.MessageType.TRANSFER_STATUS_IND, onTransferStatusIndicationReceived );

            ll.ind_subscribe( GIsiClient.GPDS.MessageType.CONTEXT_ACTIVATE_IND, onContextActivateIndicationReceived );
            ll.ind_subscribe( GIsiClient.GPDS.MessageType.CONTEXT_DEACTIVATE_IND, onContextDeactivateIndicationReceived );

            //ll.ind_subscribe( GIsiClient.GPDS.MessageType.CONTEXT_ID_CREATE_IND, onContextIdCreateIndicationReceived );
            //ll.ind_subscribe( GIsiClient.GPDS.MessageType.CONTEXT_ID_DELETE_IND, onContextIdDeleteIndicationReceived );
            //ll.ind_subscribe( GIsiClient.GPDS.MessageType.CONTEXT_MWI_ACT_REQUEST_IND, onContextMwiActRequestIndicationReceived );
            //ll.ind_subscribe( GIsiClient.GPDS.MessageType.ATTACH_IND, onAttachIndicationReceived );
            //ll.ind_subscribe( GIsiClient.GPDS.MessageType.SMS_PDU_RECEIVE_IND, onSmsPduReceiveIndicationReceived );
            //ll.ind_subscribe( GIsiClient.GPDS.MessageType.CONTEXT_ACTIVATE_FAIL_IND, onContextActivateFailIndicationReceived );
            //ll.ind_subscribe( GIsiClient.GPDS.MessageType.CONTEXT_STATUS_IND, onContextStatusIndicationReceived );
            //ll.ind_subscribe( GIsiClient.GPDS.MessageType.CONTEXT_ACTIVATING_IND, onContextActivatingIndicationReceived );
            //ll.ind_subscribe( GIsiClient.GPDS.MessageType.CONTEXT_MODIFY_IND, onContextModifyIndicationReceived );
            //ll.ind_subscribe( GIsiClient.GPDS.MessageType.ATTACH_FAIL_IND, onAttachFailIndicationReceived );
            //ll.ind_subscribe( GIsiClient.GPDS.MessageType.CONTEXT_DEACTIVATING_IND, onContextDeactivatingIndicationReceived );
            //ll.ind_subscribe( GIsiClient.GPDS.MessageType.CONFIGURATION_INFO_IND, onConfigurationInfoIndicationReceived );
            //ll.ind_subscribe( GIsiClient.GPDS.MessageType.RADIO_ACTIVITY_IND, onRadioActivityIndicationReceived );
            //ll.ind_subscribe( GIsiClient.GPDS.MessageType.MBMS_STATUS_IND, onMbmsStatusIndicationReceived );
            //ll.ind_subscribe( GIsiClient.GPDS.MessageType.MBMS_CONTEXT_DELETE_IND, onMbmsContextDeleteIndicationReceived );
            //ll.ind_subscribe( GIsiClient.GPDS.MessageType.MBMS_SERVICE_SELECTION_IND, onMbmsServiceSelectionIndicationReceived );
            //ll.ind_subscribe( GIsiClient.GPDS.MessageType.MBMS_SERVICE_AVAILABLE_IND, onMbmsServiceAvailableIndicationReceived );
        }

        public async void activate( string apn, string? user, string? pw, VoidResultFunc cb )
        {
            pep = GIsi.PEP.create( ll.modem, ( p ) => { } );
            if ( pep == null )
            {
                warning( "failed to create ISI PEP" );
                cb( ErrorCode.INVALID_FORMAT );
                return;
            }

            pipe = GIsi.Pipe.create( ll.modem, onPipeCreated, pep.get_object(), isiobj, 0x04, 0x04 );
            if ( pipe == null )
            {
                warning( "failed to create ISI Pipe" );
                cb( ErrorCode.INVALID_FORMAT );
                return;
            }
            pipe.set_userdata( helper = new GPDSHelper( this, activate.callback ) );
            yield;

            helper = null;
            bool ok = true;

            var req1 = new uint8[] { GIsiClient.GPDS.MessageType.CONTEXT_ID_CREATE_REQ };
            ll.send( req1, ( msg ) => {
                if ( !msg.ok() )
                {
                    warning( "could not create GPRS context ID" );
                    cb( ErrorCode.INVALID_FORMAT );
                    ok = false;
                }
                ctxid = msg.data[0];
                activate.callback();
            } );
            yield;

            if ( !ok )
            {
                return;
            }

            var req2 = new uint8[] {
                    GIsiClient.GPDS.MessageType.LL_CONFIGURE_REQ,
                    ctxid, pipe.get_handle(), GIsiClient.GPDS.PppMode.PLAIN
            };
            ll.send( req2, ( msg ) => {
                if ( !msg.ok() )
                {
                    warning( "could not configure GPRS PPP mode" );
                    ok = false;
                    cb( ErrorCode.INVALID_FORMAT );
                }
                activate.callback();
            } );
            yield;

            if ( !ok )
            {
                return;
            }

            var req3 = new uint8[] {
                GIsiClient.GPDS.MessageType.CONTEXT_CONFIGURE_REQ,
                ctxid,
                GIsiClient.GPDS.PdpType.IPV4,
                GIsiClient.GPDS.ContextType.NORMAL,
                ctxid,
                0x00,		/* filler */
                2,		/* sub blocks */
                GIsiClient.GPDS.SubblockType.DNS_ADDRESS_REQ_INFO,
                4,		/* subblock length */
                0, 0,		/* padding */
                GIsiClient.GPDS.SubblockType.APN_INFO,
                43,
                (uint8) apn.length,
                0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0
            };

            for ( int i = 0; i < apn.length; ++i )
            {
                req3[14 + i] = apn[i];
            }

            ll.send( req3, ( msg ) => {
                if ( !msg.ok() )
                {
                    warning( "could not configure GPRS context" );
                    cb( ErrorCode.INVALID_FORMAT );
                    ok = false;
                }
                activate.callback();
            } );
            yield;

            if ( !ok )
            {
                return;
            }

            if ( user != null && pw != null )
            {
                /* Pad the fields to the next 32bit boundary */
                uint8 sb_userinfo_len = align4( 3 + user.length );
                uint8 userinfo_pad_len = sb_userinfo_len - ( 3 + user.length );
                uint8 sb_password_info_len = align4( 3 + pw.length );
                uint8 password_pad_len = sb_password_info_len - ( 3 + pw.length );

                var pad = new uint8[] { 0x00, 0x00, 0x00, 0x00 };

                var top = new uint8[] {
                    GIsiClient.GPDS.MessageType.CONTEXT_AUTH_REQ,
                    ctxid,
                    2,	/* sub blocks */
                    GIsiClient.GPDS.SubblockType.USER_NAME_INFO,
                    sb_userinfo_len,
                    (uint8) user.length
                    /* Username goes here */
                    /* Possible padding goes here */
                };

                var bottom = new uint8[] {
                    GIsiClient.GPDS.SubblockType.PASSWORD_INFO,
                    sb_password_info_len,
                    (uint8) pw.length
                    /* Password goes here */
                    /* Possible padding goes here */
                };

                Posix.iovector[] iov2 = new Posix.iovector[6];
                iov2[0] = { top, top.length };
                iov2[1] = { user, user.length };
                iov2[2] = { pad, userinfo_pad_len };
                iov2[3] = { bottom, bottom.length };
                iov2[4] = { pw, pw.length };
                iov2[5] = { pad, password_pad_len };

                ll.vsend( iov2, ( msg ) => {
                    if ( !msg.ok() )
                    {
                        warning( "could not configure GPRS user and password" );
                        cb( ErrorCode.INVALID_FORMAT );
                        ok = false;
                    }
                    activate.callback();
                } );
                yield;
            }

            if ( !ok )
            {
                return;
            }

            var req4 = new uint8[] {
                GIsiClient.GPDS.MessageType.CONTEXT_ACTIVATE_REQ,
                ctxid, 0
            };

            ll.send( req4, ( msg ) => {
                if ( !msg.ok() )
                {
                    warning( "could not activate context" );
                    cb( ErrorCode.INVALID_FORMAT );
                    ok = false;
                }
                activate.callback();
            } );
            yield;

            if ( ok )
            {
                pipe.start();
                cb( ErrorCode.OK );
            }
        }

        public async void deactivate()
        {
            var req = new uint8[] {
                    GIsiClient.GPDS.MessageType.CONTEXT_DEACTIVATE_REQ,
                    ctxid
            };

            ll.send( req, ( msg ) => {
                if ( !msg.ok() )
                {
                    //cb( ErrorCode.INVALID_FORMAT );
                    deactivate.callback();
                    return;
                }

                //cb( ErrorCode.OK );
                deactivate.callback();
            } );

            yield;

            pipe = null;
            pep = null;
        }

        private void onContextActivateIndicationReceived( GIsi.Message msg )
        {
            message( @"$msg received" );

            string ip_addr = null;
            string[] dns = new string[] {};

            for ( GIsi.SubBlockIter sbi = msg.subblock_iter_create( 2 ); sbi.is_valid(); sbi.next() )
            {
                message( @"Have subblock with ID $(sbi.id), length $(sbi.length)" );

                uint8 addr_length = 0;
                void *addr_value = null;

                switch ( sbi.id )
                {
                    case GIsiClient.GPDS.SubblockType.PDP_ADDRESS_INFO:
                        if ( !sbi.get_byte( out addr_length, 3 ) )
                        {
                            warning( @"Failed to get length of address from subblock with ID $(sbi.id)" );
                            continue;
                        }
                        debug( @"addr_length = $addr_length" );

                        if ( !sbi.get_data( out addr_value, 4 ) )
                        {
                            warning( @"Failed to get data of address from subblock with ID $(sbi.id)" );
                            continue;
                        }

                        if ( addr_length == 4 )
                        {
                            var dst = new uint8[Posix.INET_ADDRSTRLEN];
                            ip_addr = Posix.inet_ntop( Posix.AF_INET, addr_value, dst );
                        }
                        else if ( addr_length == 16 )
                        {
                            var dst = new uint8[Posix.INET6_ADDRSTRLEN];
                            ip_addr = Posix.inet_ntop( Posix.AF_INET6, addr_value, dst );
                        }
                        break;

                    case GIsiClient.GPDS.SubblockType.PDNS_ADDRESS_INFO:
                    case GIsiClient.GPDS.SubblockType.SDNS_ADDRESS_INFO:
                        if ( dns.length == 2 )
                        {
                            warning( "Ignoring additional dns server" );
                            continue;
                        }

                        if ( !sbi.get_byte( out addr_length, 3 ) )
                        {
                            warning( @"Failed to get length of address from subblock with ID $(sbi.id)" );
                            continue;
                        }
                        debug( @"addr_length = $addr_length" );

                        if ( !sbi.get_data( out addr_value, 4 ) )
                        {
                            warning( @"Failed to get data of address from subblock with ID $(sbi.id)" );
                            continue;
                        }

                        if ( addr_length == 4 )
                        {
                            var dst = new uint8[Posix.INET_ADDRSTRLEN];
                            dns += Posix.inet_ntop( Posix.AF_INET, addr_value, dst );
                        }
                        else if ( addr_length == 16 )
                        {
                            var dst = new uint8[Posix.INET6_ADDRSTRLEN];
                            dns += Posix.inet_ntop( Posix.AF_INET6, addr_value, dst );
                        }
                        break;

                    default:
                        message( @"FIXME: handle unknown subblock with ID $(sbi.id)" );
                        break;
                }
            }

            //uint8[Posix.IF_NAMESIZE] iface = null;
            this.contextActivated( "gprs0", ip_addr, dns.length > 0 ? dns[0] : "", dns.length > 1 ? dns[1] : "" );
        }

        private void onContextDeactivateIndicationReceived( GIsi.Message msg )
        {
            message( @"$msg received" );
            this.contextDeactivated();
        }

        private void onContextIdCreateIndicationReceived( GIsi.Message msg )
        {
            message( @"$msg received" );
        }

        private void onContextIdDeleteIndicationReceived( GIsi.Message msg )
        {
            message( @"$msg received" );
        }

        private void onContextMwiActRequestIndicationReceived( GIsi.Message msg )
        {
            message( @"$msg received" );
        }

        private void onAttachIndicationReceived( GIsi.Message msg )
        {
            message( @"$msg received" );
        }

        private void onDetachIndicationReceived( GIsi.Message msg )
        {
            message( @"$msg received" );
        }

        private void onSmsPduReceiveIndicationReceived( GIsi.Message msg )
        {
            message( @"$msg received" );
        }

        private void onTransferStatusIndicationReceived( GIsi.Message msg )
        {
            message( @"$msg received" );
        }

        private void onContextActivateFailIndicationReceived( GIsi.Message msg )
        {
            message( @"$msg received" );
        }

        private void onContextStatusIndicationReceived( GIsi.Message msg )
        {
            message( @"$msg received" );
        }

        private void onContextActivatingIndicationReceived( GIsi.Message msg )
        {
            message( @"$msg received" );
        }

        private void onContextModifyIndicationReceived( GIsi.Message msg )
        {
            message( @"$msg received" );
        }

        private void onAttachFailIndicationReceived( GIsi.Message msg )
        {
            message( @"$msg received" );
        }

        private void onContextDeactivatingIndicationReceived( GIsi.Message msg )
        {
            message( @"$msg received" );
        }

        private void onConfigurationInfoIndicationReceived( GIsi.Message msg )
        {
            message( @"$msg received" );
        }

        private void onRadioActivityIndicationReceived( GIsi.Message msg )
        {
            message( @"$msg received" );
        }

        private void onMbmsStatusIndicationReceived( GIsi.Message msg )
        {
            message( @"$msg received" );
        }

        private void onMbmsContextDeleteIndicationReceived( GIsi.Message msg )
        {
            message( @"$msg received" );
        }

        private void onMbmsServiceSelectionIndicationReceived( GIsi.Message msg )
        {
            message( @"$msg received" );
        }

        private void onMbmsServiceAvailableIndicationReceived( GIsi.Message msg )
        {
            message( @"$msg received" );
        }

    }

    /**
     * @class EpocInfo
     *
     * EPOC Info Server
     **/

    public class EpocInfo
    {
        private uint sv;
        private GIsiServer.EpocInfo ll;

        public EpocInfo( GIsi.Modem modem )
        {
            sv = 2;
            ll = modem.info_server_create();
            ll.handle( 0x00, onSerialNumberReadReq );
        }

        private void onSerialNumberReadReq( GIsi.Message msg )
        {
            message( @"$msg received" );

            if ( msg.id != 0x00 )
                return;

            if ( msg.data[0] != GIsiServer.EpocInfo.SubblockType.SN_IMEI_SV_TO_NET )
                return;

            var req = new uint8[] {
                GIsiServer.EpocInfo.MessageType.SERIAL_NUMBER_READ_RESP,
                GIsiServer.EpocInfo.IsiCause.OK, 1,
                GIsiServer.EpocInfo.SubblockType.SN_IMEI_SV_TO_NET, 16,
                /* Mobile Identity IE, TS 24.008 section 10.5.1.4 */
                0, 9,
                /* F in place of IMEI digits and filler */
                0xf3, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
                0x0f | ((sv / 10) << 4),
                0xf0 | ((sv % 10) & 0x0f),
                /* Subblock filler */
                0, 0, 0
            };

            ll.send( msg, req );
        }
    }

} /* namespace GIsiComm */

// vim:ts=4:sw=4:expandtab
