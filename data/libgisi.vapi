/*
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

/**
 * @namespace Gisi
 *
 * The low level communication services
 **/

[CCode (cprefix = "GIsi", lower_case_cprefix = "g_isi_")]
namespace GIsi
{

    [Compact]
    [CCode (free_function = "g_isi_client_destroy", cheader_filename = "libgisi.h")]
    public class Client
    {
        // construction
        [CCode (cname = "g_isi_client_create")]
        public Client( GIsi.Modem modem, GIsi.PhonetSubsystem resource );

        /*
        [CCode (cname = "g_isi_client_create")]
        public static unowned GIsi.Client create( GIsi.Modem modem, GIsi.PhonetSubsystem resource );
        */

        [CCode (cname = "g_isi_client_ind_subscribe")]
        public bool ind_subscribe( uchar type, GIsi.NotifyFunc notify );

        [CCode (cname = "g_isi_client_modem")]
        public unowned GIsi.Modem modem();

        [CCode (cname = "g_isi_client_ntf_subscribe")]
        public bool ntf_subscribe( uchar type, GIsi.NotifyFunc notify );

        [CCode (cname = "g_isi_client_reset")]
        public void reset();

        [CCode (cname = "g_isi_client_resource")]
        public uchar resource();

        [CCode (cname = "g_isi_client_send")]
        public bool send( uint8[] msg, GIsi.NotifyFunc notify, GLib.DestroyNotify? destroy = null );

        [CCode (cname = "g_isi_client_send_with_timeout")]
        public bool send_with_timeout( uint8[] msg, uint timeout, GIsi.NotifyFunc notify, GLib.DestroyNotify? destroy = null );

        [CCode (cname = "g_isi_client_set_timeout")]
        public void set_timeout( uint timeout );

        // verify whether a certain client subsystem is reachable
        [CCode (cname = "g_isi_client_verify")]
        public bool verify( GIsi.NotifyFunc notify, GLib.DestroyNotify? destroy = null );

        [CCode (cname = "g_isi_client_vsend")]
        public bool vsend( uint8[] iov, GIsi.NotifyFunc notify, GLib.DestroyNotify? destroy = null );

        [CCode (cname = "g_isi_client_vsend_with_timeout")]
        public bool vsend_with_timeout( uint8[] iov, uint timeout, GIsi.NotifyFunc notify, GLib.DestroyNotify? destroy = null );
    }

    /**
     * @class Message
     *
     * ISI Communication Message
     **/
    [Compact]
    [CCode (lower_case_cprefix = "g_isi_msg_", cheader_filename = "libgisi.h,call.h,gpds.h,gss.h,info.h,mtc.h,network.h,sim.h,sms.h,ss.h", free_function = "")]
    public class Message
    {
        //FIXME: Really expose?
        /*
        public void* addr;
        public void* data;
        public int error;
        public size_t len;
        public void* @private;
        public weak GIsi.Version version;
        */

        [CCode (cname = "g_isi_msg_data", cheader_filename = "libgisi.h")]
        public void* msg_data();
        [CCode (cname = "g_isi_msg_data_get_byte", cheader_filename = "libgisi.h")]
        public bool msg_data_get_byte( uint offset, uchar byte );
        [CCode (cname = "g_isi_msg_data_get_struct", cheader_filename = "libgisi.h")]
        public bool msg_data_get_struct( uint offset, void* type, size_t len );
        [CCode (cname = "g_isi_msg_data_get_word", cheader_filename = "libgisi.h")]
        public bool msg_data_get_word( uint offset, uint16 word );
        [CCode (cname = "g_isi_msg_data_len", cheader_filename = "libgisi.h")]
        public size_t msg_data_len();
        [CCode (cname = "g_isi_msg_error", cheader_filename = "libgisi.h")]
        public int msg_error();
        [CCode (cname = "g_isi_msg_id", cheader_filename = "libgisi.h")]
        public uchar msg_id();
        [CCode (cname = "g_isi_msg_object", cheader_filename = "libgisi.h")]
        public uint16 msg_object();
        [CCode (cname = "g_isi_msg_resource", cheader_filename = "libgisi.h")]
        public PhonetSubsystem msg_resource();
        [CCode (cname = "g_isi_msg_strerror", cheader_filename = "libgisi.h")]
        public unowned string msg_strerror();
        [CCode (cname = "g_isi_msg_utid", cheader_filename = "libgisi.h")]
        public uchar msg_utid();
        [CCode (cname = "g_isi_msg_version_major", cheader_filename = "libgisi.h")]
        public int msg_version_major();
        [CCode (cname = "g_isi_msg_version_minor", cheader_filename = "libgisi.h")]
        public int msg_version_minor();

        // subblocks
        public SubBlockIter subblock_iter_create( size_t used )
        {
            SubBlockIter iter;
            iter.init( this, used );
            return iter;
        }

        // synthesized
        public bool ok()
        {
            return ! ( msg_error() < 0 );
        }
        public string to_string()
        {
            return "<Message %s (%d) v%03d.%03d>".printf( msg_resource().to_string(), (int)msg_resource(), msg_version_major(), msg_version_minor() );
        }
    }

    /**
     * @class Modem
     *
     * Basic class for interacting with a GISI modem
     **/
    [Compact]
    [CCode (free_function = "g_isi_modem_destroy", cheader_filename = "libgisi.h")]
    public class Modem {

        //
        // construction
        //
        [CCode (cname = "g_isi_modem_create_by_name" )]
        public Modem( string name = "phonet0" );

        [CCode (cname = "g_isi_modem_create")]
        public Modem.index_new( uint index );

        //
        // phonet netlink
        //
        [CCode (cname = "g_isi_pn_netlink_by_modem", cheader_filename = "libgisi.h")]
        public unowned GIsi.PhonetNetlink netlink();

        [CCode (cname = "g_isi_pn_netlink_start", cheader_filename = "libgisi.h")]
        public unowned GIsi.PhonetNetlink netlink_start( GIsi.PhonetNetlinkFunc cb );

        [CCode (cname = "g_isi_pn_netlink_set_address", cheader_filename = "libgisi.h")]
        public int netlink_set_address( GIsi.PhonetDevice local );

        //
        // synthesized client factory
        //
        public GIsiClient.SIM sim_client_create()
        {
            return (GIsiClient.SIM) new GIsi.Client( this, GIsi.PhonetSubsystem.SIM );
        }

        public GIsiClient.PhoneInfo phone_info_client_create()
        {
            return (GIsiClient.PhoneInfo) new GIsi.Client( this, GIsi.PhonetSubsystem.PHONE_INFO );
        }

        //
        // assorted modem functions
        //
        [CCode (cname = "g_isi_modem_get_userdata")]
        public void* get_userdata ();
        [CCode (cname = "g_isi_modem_index")]
        public uint index ();
        [CCode (cname = "g_isi_modem_send")]
        public int send (uchar resource, void* buf, size_t len);
        [CCode (cname = "g_isi_modem_sendto")]
        public int sendto (void* dst, void* buf, size_t len);
        [CCode (cname = "g_isi_modem_set_debug")]
        public void set_debug (GIsi.DebugFunc debug);
        [CCode (cname = "g_isi_modem_set_trace")]
        public void set_trace (GIsi.NotifyFunc notify);
        [CCode (cname = "g_isi_modem_set_userdata")]
        public void* set_userdata (void* data);
        [CCode (cname = "g_isi_modem_vsend")]
        public int vsend (uchar resource, void* iov, size_t iovlen);
        [CCode (cname = "g_isi_modem_vsendto")]
        public int vsendto (void* dst, void* iov, size_t iovlen);

        //
        // assorted request functions (deprecated?)
        //
        [CCode (cname = "g_isi_request_send", cheader_filename = "libgisi.h")]
        public unowned GIsi.Pending request_send( uchar resource, void* buf, size_t len, uint timeout, GIsi.NotifyFunc notify, GLib.DestroyNotify? destroy = null );
        [CCode (cname = "g_isi_request_sendto", cheader_filename = "libgisi.h")]
        public unowned GIsi.Pending request_sendto( void* dst, void* buf, size_t len, uint timeout, GIsi.NotifyFunc notify, GLib.DestroyNotify? destroy = null );
        [CCode (cname = "g_isi_request_utid", cheader_filename = "libgisi.h")]
        public uchar request_utid (GIsi.Pending resp);
        [CCode (cname = "g_isi_request_vsend", cheader_filename = "libgisi.h")]
        public unowned GIsi.Pending request_vsend( uchar resource, void* iov, size_t iovlen, uint timeout, GIsi.NotifyFunc notify, GLib.DestroyNotify? destroy = null );
        [CCode (cname = "g_isi_request_vsendto", cheader_filename = "libgisi.h")]
        public unowned GIsi.Pending request_vsendto( void* dst, void* iov, size_t iovlen, uint timeout, GIsi.NotifyFunc notify, GLib.DestroyNotify? destroy = null );
        [CCode (cname = "g_isi_resource_ping", cheader_filename = "libgisi.h")]
        public unowned GIsi.Pending resource_ping( uchar resource, GIsi.NotifyFunc notify, GLib.DestroyNotify? destroy = null );
        [CCode (cname = "g_isi_response_send", cheader_filename = "libgisi.h")]
        public int response_send( GIsi.Message req, void* buf, size_t len);
        [CCode (cname = "g_isi_response_vsend", cheader_filename = "libgisi.h")]
        public int response_vsend( GIsi.Message req, void* iov, size_t iovlen);
    }


    [Compact]
    [CCode (free_function = "g_isi_pep_destroy", cheader_filename = "libgisi.h")]
    public class PEP {
        [CCode (cname = "g_isi_pep_create")]
        public static unowned GIsi.PEP create (GIsi.Modem modem, GIsi.PEPCallback cb, void* data);
        [CCode (cname = "g_isi_pep_get_ifindex")]
        public uint get_ifindex ();
        [CCode (cname = "g_isi_pep_get_ifname")]
        public unowned string get_ifname (string ifname);
        [CCode (cname = "g_isi_pep_get_object")]
        public uint16 get_object ();
    }


    [Compact]
    [CCode (cheader_filename = "libgisi.h")]
    public class Pending
    {
        [CCode (cname = "g_isi_pending_remove")]
        public void remove();
        [CCode (cname = "g_isi_pending_set_owner")]
        public void set_owner( void* owner );
    }

    /**
     * @class PhonetNetlink
     *
     * Access to the underlying phonet netlink functions
     **/
    [Compact]
    [CCode (lower_case_cprefix = "g_isi_pn_netlink_", cheader_filename = "libgisi.h")]
    public class PhonetNetlink
    {
        public void stop();
    }

    [Compact]
    [CCode (free_function = "g_isi_pipe_destroy", cheader_filename = "libgisi.h")]
    public class Pipe
    {
        [CCode (cname = "g_isi_pipe_create")]
        public static unowned GIsi.Pipe create (GIsi.Modem modem, GIsi.PipeHandler cb, uint16 obj1, uint16 obj2, uchar type1, uchar type2);
        [CCode (cname = "g_isi_pipe_get_error")]
        public int get_error ();
        [CCode (cname = "g_isi_pipe_get_handle")]
        public uchar get_handle ();
        [CCode (cname = "g_isi_pipe_get_userdata")]
        public void* get_userdata ();
        [CCode (cname = "g_isi_pipe_set_error_handler")]
        public void set_error_handler (GIsi.PipeErrorHandler cb);
        [CCode (cname = "g_isi_pipe_set_userdata")]
        public void* set_userdata (void* data);
        [CCode (cname = "g_isi_pipe_start")]
        public int start ();
    }


    [Compact]
    [CCode (free_function = "g_isi_server_destroy", cheader_filename = "libgisi.h")]
    public class Server
    {
        [CCode (cname = "g_isi_server_create")]
        public static unowned GIsi.Server create (GIsi.Modem modem, uchar resource, GIsi.Version version);
        [CCode (cname = "g_isi_server_handle")]
        public unowned GIsi.Pending handle (uchar type, GIsi.NotifyFunc notify, void* data);
        [CCode (cname = "g_isi_server_modem")]
        public unowned GIsi.Modem modem ();
        [CCode (cname = "g_isi_server_resource")]
        public uchar resource ();
        [CCode (cname = "g_isi_server_send")]
        public int send (GIsi.Message req, void* data, size_t len);
        [CCode (cname = "g_isi_server_vsend")]
        public int vsend (GIsi.Message req, void* iov, size_t iovlen);
    }

    //[Compact]
    [CCode (cheader_filename = "libgisi.h")]
    public struct SubBlockIter
    {
        // FIXME: Expose?
        /*
        public uchar end;
        public bool longhdr;
        public uchar start;
        public uint16 sub_blocks;
        */

        [CCode (cname = "g_isi_sb_iter_get_alpha_tag", cheader_filename = "libgisi.h")]
        public bool get_alpha_tag( out unowned string utf8, size_t len, uint pos );
        [CCode (cname = "g_isi_sb_iter_get_byte", cheader_filename = "libgisi.h")]
        public bool get_byte( uchar byte, uint pos );
        [CCode (cname = "g_isi_sb_iter_get_data", cheader_filename = "libgisi.h")]
        public bool get_data( void* data, uint pos );
        [CCode (cname = "g_isi_sb_iter_get_dword", cheader_filename = "libgisi.h")]
        public bool get_dword( uint32 dword, uint pos );
        [CCode (cname = "g_isi_sb_iter_get_id", cheader_filename = "libgisi.h")]
        public int get_id();
        [CCode (cname = "g_isi_sb_iter_get_latin_tag", cheader_filename = "libgisi.h")]
        public bool get_latin_tag( out unowned string ascii, size_t len, uint pos );
        [CCode (cname = "g_isi_sb_iter_get_len", cheader_filename = "libgisi.h")]
        public size_t get_len();
        [CCode (cname = "g_isi_sb_iter_get_oper_code", cheader_filename = "libgisi.h")]
        public bool get_oper_code( string mcc, string mnc, uint pos );
        [CCode (cname = "g_isi_sb_iter_get_struct", cheader_filename = "libgisi.h")]
        public bool get_struct( void* ptr, size_t len, uint pos );
        [CCode (cname = "g_isi_sb_iter_get_word", cheader_filename = "libgisi.h")]
        public bool get_word( uint16 word, uint pos );
        [CCode (cname = "g_isi_sb_iter_init", cheader_filename = "libgisi.h")]
        public void init( GIsi.Message msg, size_t used );
        [CCode (cname = "g_isi_sb_iter_init_full", cheader_filename = "libgisi.h")]
        public void init_full( GIsi.Message msg, size_t used, bool longhdr, uint16 sub_blocks );
        [CCode (cname = "g_isi_sb_iter_is_valid", cheader_filename = "libgisi.h")]
        public bool is_valid();
        [CCode (cname = "g_isi_sb_iter_next", cheader_filename = "libgisi.h")]
        public bool next();

        /*
        [CCode (cname = "g_isi_sb_subiter_init", cheader_filename = "libgisi.h")]
        public static void sb_subiter_init (GIsi.SubBlockIter outer, GIsi.SubBlockIter inner, size_t used);
        [CCode (cname = "g_isi_sb_subiter_init_full", cheader_filename = "libgisi.h")]
        public static void sb_subiter_init_full (GIsi.SubBlockIter @out, GIsi.SubBlockIter @in, size_t used, bool longhdr, uint16 sub_blocks);
        */







    }


    [Compact]
    [CCode (lower_case_cprefix = "g_isi_msg_", cheader_filename = "libgisi.h")]
    public class Version {
        public int major;
        public int minor;
    }

    /**
     * Enums
     **/

    [CCode (cname = "guchar", cprefix = "PN_DEV_", has_type_id = false, cheader_filename = "libgisi.h")]
    public enum PhonetDevice {
        PC,
        HOST,
        SOS
    }


    [CCode (cprefix = "PN_LINK_", has_type_id = false, cheader_filename = "libgisi.h")]
    public enum PhonetLinkState
    {
        REMOVED,
        DOWN,
        UP
    }

    [CCode (cname = "guchar", cprefix = "PN_", has_type_id = false, cheader_filename = "libgisi.h,call.h,gpds.h,gss.h,info.h,mtc.h,network.h,sim.h,sms.h,ss.h")]
    public enum PhonetSubsystem
    {
        CALL,
        EPOC_INFO,
        GPDS,
        GSS,
        MTC,
        NETWORK,
        PHONE_INFO,
        PEP_TYPE_GPRS,
        SIM,
        SMS,
        SS,
        WRAN
    }

    /**
     * Callbacks
     **/

    [CCode (cheader_filename = "libgisi.h", has_target = false)]
    public delegate void DebugFunc (string fmt);
    //[CCode (cheader_filename = "libgisi.h", has_target = false)]
    //public delegate void NotifyFunc (GIsi.Message msg, void* opaque);
    [CCode (cheader_filename = "libgisi.h")]
    public delegate void NotifyFunc (GIsi.Message msg);
    [CCode (cheader_filename = "libgisi.h", has_target = false)]
    public delegate void PEPCallback (GIsi.PEP pep, void* opaque);
    [CCode (cheader_filename = "libgisi.h")]
    public delegate void PhonetNetlinkFunc (GIsi.Modem modem, GIsi.PhonetLinkState st, string iface);
    [CCode (cheader_filename = "libgisi.h", has_target = false)]
    public delegate void PipeErrorHandler (GIsi.Pipe pipe);
    [CCode (cheader_filename = "libgisi.h", has_target = false)]
    public delegate void PipeHandler (GIsi.Pipe pipe);

    /**
     * Consts
     **/

    [CCode (cheader_filename = "libgisi.h")]
    public const int AF_PHONET;
    [CCode (cheader_filename = "libgisi.h")]
    public const int COMMON_TIMEOUT;
    [CCode (cheader_filename = "libgisi.h")]
    public const int G_ISI_CLIENT_DEFAULT_TIMEOUT;
    [CCode (cheader_filename = "libgisi.h")]
    public const int PNPIPE_ENCAP;
    [CCode (cheader_filename = "libgisi.h")]
    public const int PNPIPE_ENCAP_IP;
    [CCode (cheader_filename = "libgisi.h")]
    public const int PNPIPE_ENCAP_NONE;
    [CCode (cheader_filename = "libgisi.h")]
    public const int PNPIPE_IFINDEX;
    [CCode (cheader_filename = "libgisi.h")]
    public const int PN_COMMGR;
    [CCode (cheader_filename = "libgisi.h")]
    public const int PN_FIREWALL;
    [CCode (cheader_filename = "libgisi.h")]
    public const int PN_NAMESERVICE;
    [CCode (cheader_filename = "libgisi.h")]
    public const int PN_PROTO_PHONET;
    [CCode (cheader_filename = "libgisi.h")]
    public const int PN_PROTO_PIPE;
    [CCode (cheader_filename = "libgisi.h")]
    public const int PN_PROTO_TRANSPORT;
    [CCode (cheader_filename = "libgisi.h")]
    public const int RTNLGRP_PHONET_IFADDR;
    [CCode (cheader_filename = "libgisi.h")]
    public const int SIOCPNADDRESOURCE;
    [CCode (cheader_filename = "libgisi.h")]
    public const int SIOCPNDELRESOURCE;
    [CCode (cheader_filename = "libgisi.h")]
    public const int SIOCPNGETOBJECT;
    [CCode (cheader_filename = "libgisi.h")]
    public const int SOL_PNPIPE;

    // ?
    [CCode (cname = "g_isi_ind_subscribe", cheader_filename = "libgisi.h")]
    public static unowned GIsi.Pending ind_subscribe (GIsi.Modem modem, uchar resource, uchar type, GIsi.NotifyFunc notify, void* data, GLib.DestroyNotify destroy);

    // ?
    [CCode (cname = "g_isi_ntf_subscribe", cheader_filename = "libgisi.h")]
    public static unowned GIsi.Pending ntf_subscribe (GIsi.Modem modem, uchar resource, uchar type, GIsi.NotifyFunc notify, void* data, GLib.DestroyNotify destroy);

    // ?
    [CCode (cname = "g_isi_service_bind", cheader_filename = "libgisi.h")]
    public static unowned GIsi.Pending service_bind (GIsi.Modem modem, uchar resource, uchar type, GIsi.NotifyFunc notify, void* data, GLib.DestroyNotify destroy);


    //FIXME: Move all to PhonetDevice
    [CCode (cname = "g_isi_phonet_new", cheader_filename = "libgisi.h")]
    public static unowned GLib.IOChannel phonet_new (uint ifindex);
    [CCode (cname = "g_isi_phonet_peek_length", cheader_filename = "libgisi.h")]
    public static size_t phonet_peek_length (GLib.IOChannel io);
    [CCode (cname = "g_isi_phonet_read", cheader_filename = "libgisi.h")]
    public static ssize_t phonet_read (GLib.IOChannel io, void* buf, size_t len, void* addr);

    // ?
    [CCode (cname = "g_isi_remove_pending_by_owner", cheader_filename = "libgisi.h")]
    public static void remove_pending_by_owner (GIsi.Modem modem, uchar resource, void* owner);
}

/**
 * @namespace GIsiClient
 *
 * The high level protocol clients
 **/

[CCode (cprefix = "")]
namespace GIsiClient
{

    /**
     * @class SIM
     *
     * SIM Access
     **/
    [Compact]
    [CCode (cname = "GIsiClient", cprefix = "SIM_", free_function = "g_isi_client_destroy", cheader_filename = "libgisi.h,sim.h")]
    public class SIM : GIsi.Client
    {
        private SIM();

        [CCode (cname = "SIM_TIMEOUT", cheader_filename = "sim.h")]
        public const uint TIMEOUT;

        public const int MAX_IMSI_LENGTH;

        [CCode (cprefix = "SIM_", cheader_filename = "sim.h")]
        public enum IsiCause
        {
            SERV_NOT_AVAIL,
            SERV_OK,
            SERV_PIN_VERIFY_REQUIRED,
            SERV_PIN_REQUIRED,
            SERV_SIM_BLOCKED,
            SERV_SIM_PERMANENTLY_BLOCKED,
            SERV_SIM_DISCONNECTED,
            SERV_SIM_REJECTED,
            SERV_LOCK_ACTIVE,
            SERV_AUTOLOCK_CLOSED,
            SERV_AUTOLOCK_ERROR,
            SERV_INIT_OK,
            SERV_INIT_NOT_OK,
            SERV_WRONG_OLD_PIN,
            SERV_PIN_DISABLED,
            SERV_COMMUNICATION_ERROR,
            SERV_UPDATE_IMPOSSIBLE,
            SERV_NO_SECRET_CODE_IN_SIM,
            SERV_PIN_ENABLE_OK,
            SERV_PIN_DISABLE_OK,
            SERV_WRONG_UNBLOCKING_KEY,
            SERV_ILLEGAL_NUMBER,
            SERV_NOT_OK,
            SERV_PN_LIST_ENABLE_OK,
            SERV_PN_LIST_DISABLE_OK,
            SERV_NO_PIN,
            SERV_PIN_VERIFY_OK,
            SERV_PIN_BLOCKED,
            SERV_PIN_PERM_BLOCKED,
            SERV_DATA_NOT_AVAIL,
            SERV_IN_HOME_ZONE,
            SERV_STATE_CHANGED,
            SERV_INF_NBR_READ_OK,
            SERV_INF_NBR_READ_NOT_OK,
            SERV_IMSI_EQUAL,
            SERV_IMSI_NOT_EQUAL,
            SERV_INVALID_LOCATION,
            SERV_STA_SIM_REMOVED,
            SERV_SECOND_SIM_REMOVED_CS,
            SERV_CONNECTED_INDICATION_CS,
            SERV_SECOND_SIM_CONNECTED_CS,
            SERV_PIN_RIGHTS_LOST_IND_CS,
            SERV_PIN_RIGHTS_GRANTED_IND_CS,
            SERV_INIT_OK_CS,
            SERV_INIT_NOT_OK_CS,
            FDN_ENABLED,
            FDN_DISABLED,
            SERV_INVALID_FILE,
            SERV_DATA_AVAIL,
            SERV_ICC_EQUAL,
            SERV_ICC_NOT_EQUAL,
            SERV_SIM_NOT_INITIALISED,
            SERV_SERVICE_NOT_AVAIL,
            SERV_FDN_STATUS_ERROR,
            SERV_FDN_CHECK_PASSED,
            SERV_FDN_CHECK_FAILED,
            SERV_FDN_CHECK_DISABLED,
            SERV_FDN_CHECK_NO_FDN_SIM,
            STA_ISIM_AVAILEBLE_PIN_REQUIRED,
            STA_ISIM_AVAILEBLE,
            STA_USIM_AVAILEBLE,
            STA_SIM_AVAILEBLE,
            STA_ISIM_NOT_INITIALIZED,
            STA_IMS_READY,
            STA_APP_DATA_READ_OK,
            STA_APP_ACTIVATE_OK,
            STA_APP_ACTIVATE_NOT_OK,
            SERV_NOT_DEFINED,
            SERV_NOSERVICE,
            SERV_NOTREADY,
            SERV_ERROR,
            SERV_CIPHERING_INDICATOR_DISPLAY_REQUIRED,
            SERV_CIPHERING_INDICATOR_DISPLAY_NOT_REQUIRED,
            SERV_FILE_NOT_AVAILABLE,
        }

        [CCode (cprefix = "SIM_PB_", cheader_filename = "sim.h")]
        public enum SubblockType
        {
            INFO_REQUEST,
            STATUS,
            LOCATION,
            LOCATION_SEARCH,
        }

        [CCode (cprefix = "SIM_PB_", cheader_filename = "sim.h")]
        public enum PhonebookType
        {
	        ADN,
        }

        [CCode (cprefix = "SIM_PB_", cheader_filename = "sim.h")]
        public enum PhonebookTag
        {
            PB_ANR,
            PB_EMAIL,
            PB_SNE,
        }

        [CCode (cprefix = "SIM_", cheader_filename = "sim.h")]
        public enum MessageType
        {
            NETWORK_INFO_REQ,
            NETWORK_INFO_RESP,
            IMSI_REQ_READ_IMSI,
            IMSI_RESP_READ_IMSI,
            SERV_PROV_NAME_REQ,
            SERV_PROV_NAME_RESP,
            READ_FIELD_REQ,
            READ_FIELD_RESP,
            SMS_REQ,
            SMS_RESP,
            PB_REQ_SIM_PB_READ,
            PB_RESP_SIM_PB_READ,
            IND,
            COMMON_MESSAGE,
        }

        [CCode (cprefix = "", cheader_filename = "sim.h")]
        public enum ServiceType
        {
            SIM_ST_PIN,
            SIM_ST_ALL_SERVICES,
            SIM_ST_INFO,
            SIM_ST_CAT_SUPPORT_ENABLE,
            SIM_ST_CAT_SUPPORT_DISABLE,
            SIM_ST_READ_SERV_PROV_NAME,
            SIM_PB_READ,
            READ_IMSI,
            READ_HPLMN,
            READ_PARAMETER,
            UPDATE_PARAMETER,
            ICC,
        }
    }

    /**
     * @class PhoneInfo
     *
     * Phone Information
     **/
    [Compact]
    [CCode (cname = "GIsiClient", cprefix = "INFO_", free_function = "g_isi_client_destroy", cheader_filename = "libgisi.h,info.h")]
    public class PhoneInfo : GIsi.Client
    {
        private PhoneInfo();

        [CCode (cname = "INFO_TIMEOUT", cheader_filename = "info.h")]
        public const uint TIMEOUT;

        public const int MAX_IMSI_LENGTH;

        [CCode (cprefix = "INFO_", cheader_filename = "info.h")]
        public enum IsiCause
        {
            OK,
            FAIL,
            NO_NUMBER,
            NOT_SUPPORTED,
        }

        [CCode (cprefix = "INFO_", cheader_filename = "info.h")]
        public enum MessageType
        {
            SERIAL_NUMBER_READ_REQ,
            SERIAL_NUMBER_READ_RESP,
            PP_READ_REQ,
            PP_READ_RESP,
            VERSION_READ_REQ,
            VERSION_READ_RESP,
            PRODUCT_INFO_READ_REQ,
            PRODUCT_INFO_READ_RESP,
            COMMON_MESSAGE,
        }

        [CCode (cprefix = "INFO_SB_", cheader_filename = "info.h")]
        public enum SubblockType
        {
            PRODUCT_INFO_NAME,
            PRODUCT_INFO_MANUFACTURER,
            SN_IMEI_PLAIN,
            SN_IMEI_SV_TO_NET,
            PP,
            MCUSW_VERSION,
        }

        [CCode (cprefix = "INFO_PRODUCT_", cheader_filename = "info.h")]
        public enum ProductInfoType
        {
            NAME,
            MANUFACTURER,
        }

        [CCode (cprefix = "INFO_SN_", cheader_filename = "info.h")]
        public enum SerialNumberType
        {
            IMEI_PLAIN,
        }

        [CCode (cprefix = "INFO_", cheader_filename = "info.h")]
        public enum VersionType
        {
            MCUSW,
        }

        [CCode (cprefix = "INFO_PP_", cheader_filename = "info.h")]
        public enum PPFeatureType
        {
            MAX_PDP_CONTEXTS,
        }
    }
}
