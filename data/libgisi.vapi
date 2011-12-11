/*
 *  Vala bindings for GISI
 *
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

/**
 * @namespace Gisi
 *
 * The low level communication services
 **/

[CCode (cprefix = "GIsi", lower_case_cprefix = "g_isi_", cheader_filename = "libgisi.h")]
namespace GIsi
{
    /**
     * @class Client
     *
     * ISI Communication Client (aka Subsystem)
     **/
    [Compact]
    [CCode (free_function = "g_isi_client_destroy", cheader_filename = "libgisi.h")]
    public class Client
    {
        // construction
        [CCode (cname = "g_isi_client_create")]
        public Client( GIsi.Modem modem, GIsi.PhonetSubsystem resource );

        // properties
        public unowned GIsi.Modem modem { [CCode (cname = "g_isi_client_modem")] get; }
        public uint timeout { [CCode (cname = "g_isi_client_set_timeout")] set; }
        public PhonetSubsystem resource { [CCode (cname = "g_isi_client_resource")] get; }

        // subscribe to indications
        [CCode (cname = "g_isi_client_ind_subscribe")]
        public bool ind_subscribe( uchar type, GIsi.NotifyFunc notify );

        // subscribe to notifications
        [CCode (cname = "g_isi_client_ntf_subscribe")]
        public bool ntf_subscribe( uchar type, GIsi.NotifyFunc notify );

        // various
        [CCode (cname = "g_isi_client_reset")]
        public void reset();

        // send a message with the default timeout
        [CCode (cname = "g_isi_client_send")]
        public bool send( uint8[] msg, owned GIsi.NotifyFunc notify );

        // send a message with a special timout
        [CCode (cname = "g_isi_client_send_with_timeout")]
        public bool send_with_timeout( uint8[] msg, uint timeout, owned GIsi.NotifyFunc notify );

        // verify whether a certain client subsystem is reachable
        [CCode (cname = "g_isi_client_verify")]
        public bool verify( owned GIsi.NotifyFunc notify );

        // send io vector with default timeout
        [CCode (cname = "g_isi_client_vsend")]
        public bool vsend( Posix.iovector[] iov, owned GIsi.NotifyFunc notify );

        // send io vector with special timeout
        [CCode (cname = "g_isi_client_vsend_with_timeout")]
        public bool vsend_with_timeout( Posix.iovector[] iov, uint timeout, owned GIsi.NotifyFunc notify );

    }

    /**
     * @class Message
     *
     * ISI Communication Message
     **/
    [Compact]
    [CCode (lower_case_cprefix = "g_isi_msg_", cheader_filename = "libgisi.h,call.h,gpds.h,gss.h,info.h,mtc.h,network.h,sim.h,simauth.h,sms.h,ss.h", free_function = "")]
    public class Message
    {
        [CCode (cname = "g_isi_msg_data_get_byte", cheader_filename = "libgisi.h")]
        public bool data_get_byte( uint offset, out uchar byte );
        [CCode (cname = "g_isi_msg_data_get_struct", cheader_filename = "libgisi.h")]
        public bool data_get_struct( uint offset, out void* ptr, size_t len );
        [CCode (cname = "g_isi_msg_data_get_word", cheader_filename = "libgisi.h")]
        public bool data_get_word( uint offset, out uint16 word );

        // properties
        public void* _data { [CCode (cname = "g_isi_msg_data", cheader_filename = "libgisi.h")] get; }
        public size_t _data_len { [CCode (cname = "g_isi_msg_data_len", cheader_filename = "libgisi.h")] get; }
        public int error { [CCode (cname = "g_isi_msg_error", cheader_filename = "libgisi.h")] get; }
        public uchar id { [CCode (cname = "g_isi_msg_id", cheader_filename = "libgisi.h")] get; }
        public uint16 object { [CCode (cname = "g_isi_msg_object", cheader_filename = "libgisi.h")] get; }
        public PhonetSubsystem resource { [CCode (cname = "g_isi_msg_resource", cheader_filename = "libgisi.h")] get; }
        public unowned string strerror { [CCode (cname = "g_isi_msg_strerror", cheader_filename = "libgisi.h")] get; }
        public uchar utid { [CCode (cname = "g_isi_msg_utid", cheader_filename = "libgisi.h")] get; }
        public int version_major { [CCode (cname = "g_isi_msg_version_major", cheader_filename = "libgisi.h")] get; }
        public int version_minor { [CCode (cname = "g_isi_msg_version_minor", cheader_filename = "libgisi.h")] get; }

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
            return error >= 0;
        }

        public unowned uint8[] data {
            get {
                unowned uint8[] array = (uint8[]) _data;
                array.length = (int)_data_len;
                return array;
            }
        }

        public void dump()
        {
            for ( GIsi.SubBlockIter sbi = subblock_iter_create( 2 ); sbi.is_valid(); sbi.next() )
            {
                GLib.message( @"Have subblock with ID $(sbi.id), length $(sbi.length)" );
            }
        }


        public string to_string()
        {
            if ( ok() )
            {
                return "<[%s (%d) v%03d.%03d]: OK, id = 0x%0X>".printf( resource.to_string(), (int)resource, version_major, version_minor, id );
            }
            else
            {
                return "<[%s (%d) v%03d.%03d]: ERROR, %s (0x%0X)>".printf( resource.to_string(), (int)resource, version_major, version_minor, strerror, error );
            }
        }
    }

    /**
     * @class Modem
     *
     * Basic class for interacting with a GISI modem
     **/
    [Compact]
    [CCode (free_function = "g_isi_modem_destroy", cheader_filename = "libgisi.h,clients.h")]
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
        public unowned GIsi.PhonetNetlink netlink_start( GIsi.PhonetNetlinkFunc cb ); /* Caution: unowned callback, don't use a closure! */

        [CCode (cname = "g_isi_pn_netlink_set_address", cheader_filename = "libgisi.h")]
        public int netlink_set_address( GIsi.PhonetDevice local );

        //
        // synthesized client factories
        //
        public GIsiClient.SIM sim_client_create()
        {
            return (GIsiClient.SIM) new GIsi.Client( this, GIsi.PhonetSubsystem.SIM );
        }

        public GIsiClient.SIMAuth sim_auth_client_create()
        {
            return (GIsiClient.SIMAuth) new GIsi.Client( this, GIsi.PhonetSubsystem.SIM_AUTH );
        }

        public GIsiClient.PhoneInfo phone_info_client_create()
        {
            return (GIsiClient.PhoneInfo) new GIsi.Client( this, GIsi.PhonetSubsystem.PHONE_INFO );
        }

        public GIsiClient.MTC mtc_client_create()
        {
            return (GIsiClient.MTC) new GIsi.Client( this, GIsi.PhonetSubsystem.MTC );
        }

        public GIsiClient.Network network_client_create()
        {
            return (GIsiClient.Network) new GIsi.Client( this, GIsi.PhonetSubsystem.NETWORK );
        }

        public GIsiClient.Call call_client_create()
        {
            return (GIsiClient.Call) new GIsi.Client( this, GIsi.PhonetSubsystem.CALL );
        }

        public GIsiClient.SMS sms_client_create()
        {
            return (GIsiClient.SMS) new GIsi.Client( this, GIsi.PhonetSubsystem.SMS );
        }

        public GIsiClient.GSS gss_client_create()
        {
            return (GIsiClient.GSS) new GIsi.Client( this, GIsi.PhonetSubsystem.GSS );
        }

        public GIsiClient.SS ss_client_create()
        {
            return (GIsiClient.SS) new GIsi.Client( this, GIsi.PhonetSubsystem.SS );
        }

        public GIsiClient.GPDS gpds_client_create()
        {
            return (GIsiClient.GPDS) new GIsi.Client( this, GIsi.PhonetSubsystem.GPDS );
        }

        // the infoserver factory
        public GIsiServer.EpocInfo info_server_create()
        {
            GIsi.Version ver;
            return (GIsiServer.EpocInfo) new GIsi.Server( this, GIsi.PhonetSubsystem.EPOC_INFO, ver );
        }

        //
        // assorted modem functions
        //
        [CCode (cname = "g_isi_modem_get_userdata")]
        public void* get_userdata ();
        [CCode (cname = "g_ist_modem_flags")]
        public long get_flags ();
        [CCode (cname = "g_isi_modem_set_flags")]
        public void set_flags ( ulong flags );
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
        public int vsend( uchar resource, Posix.iovector[] iov );
        [CCode (cname = "g_isi_modem_vsendto")]
        public int vsendto( void* dst, Posix.iovector[] iov );

        //
        // assorted lowlevel request functions
        //
        [CCode (cname = "g_isi_request_send", cheader_filename = "libgisi.h")]
        public unowned GIsi.Pending request_send( uchar resource, uint8[] buf, uint timeout, owned GIsi.NotifyFunc notify );
        [CCode (cname = "g_isi_request_sendto", cheader_filename = "libgisi.h")]
        public unowned GIsi.Pending request_sendto( void* dst, uint8[] buf, uint timeout, owned GIsi.NotifyFunc notify );
        [CCode (cname = "g_isi_request_utid", cheader_filename = "libgisi.h")]
        public uchar request_utid (GIsi.Pending resp);
        [CCode (cname = "g_isi_request_vsend", cheader_filename = "libgisi.h")]
        public unowned GIsi.Pending request_vsend( uchar resource, Posix.iovector[] iov, uint timeout, owned GIsi.NotifyFunc notify );
        [CCode (cname = "g_isi_request_vsendto", cheader_filename = "libgisi.h")]
        public unowned GIsi.Pending request_vsendto( void* dst, Posix.iovector[] iov, uint timeout, owned GIsi.NotifyFunc notify );
        [CCode (cname = "g_isi_resource_ping", cheader_filename = "libgisi.h")]
        public unowned GIsi.Pending resource_ping( uchar resource, owned GIsi.NotifyFunc notify );
        [CCode (cname = "g_isi_response_send", cheader_filename = "libgisi.h")]
        public int response_send( GIsi.Message req, uint8[] buf );
        [CCode (cname = "g_isi_response_vsend", cheader_filename = "libgisi.h")]
        public int response_vsend( GIsi.Message req, Posix.iovector[] iov );
    }

    /**
     * @class PEP
     *
     * Packet Data Communication Pipe End Point (?)
     **/

    [Compact]
    [CCode (free_function = "g_isi_pep_destroy", cheader_filename = "libgisi.h")]
    public class PEP
    {
        [CCode (cname = "g_isi_pep_create")]
        public static GIsi.PEP create( GIsi.Modem modem, GIsi.PEPCallback cb );
        [CCode (cname = "g_isi_pep_get_ifindex")]
        public uint get_ifindex();
        [CCode (cname = "g_isi_pep_get_ifname")]
        public unowned string get_ifname( string ifname );
        [CCode (cname = "g_isi_pep_get_object")]
        public uint16 get_object();
    }

    /**
     * @class Pending
     *
     * Handle to a pending ISI message
     **/
    [Compact]
    [CCode (free_function = "", cheader_filename = "libgisi.h")]
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
        [CCode (cname = "g_isi_pn_netlink_stop", cheader_filename = "libgisi.h")]
        public void stop();
    }

    /**
     * @class Pipe
     *
     * Packet Data Communication Pipe
     **/
    [Compact]
    [CCode (free_function = "g_isi_pipe_destroy", cheader_filename = "libgisi.h")]
    public class Pipe
    {
        [CCode (cname = "g_isi_pipe_create")]
        public static GIsi.Pipe create( GIsi.Modem modem, GIsi.PipeHandler cb, uint16 obj1, uint16 obj2, uchar type1, uchar type2 );
        [CCode (cname = "g_isi_pipe_get_error")]
        public int get_error();
        [CCode (cname = "g_isi_pipe_get_handle")]
        public uchar get_handle();
        [CCode (cname = "g_isi_pipe_get_userdata")]
        public void* get_userdata();
        [CCode (cname = "g_isi_pipe_set_error_handler")]
        public void set_error_handler( GIsi.PipeErrorHandler cb );
        [CCode (cname = "g_isi_pipe_set_userdata")]
        public void* set_userdata( void* data );
        [CCode (cname = "g_isi_pipe_start")]
        public int start();
    }

    /**
     * @class Server
     *
     * Communication Server for answering questions from the Modem
     **/
    [Compact]
    [CCode (free_function = "g_isi_server_destroy", cheader_filename = "libgisi.h")]
    public class Server
    {
        // construction
        [CCode (cname = "g_isi_server_create")]
        public Server( GIsi.Modem modem, GIsi.PhonetSubsystem resource, GIsi.Version version );

        // properties
        public unowned GIsi.Modem modem { [CCode (cname = "g_isi_server_modem")] get; }
        public PhonetSubsystem resource { [CCode (cname = "g_isi_server_resource")] get; }

        // send a message
        [CCode (cname = "g_isi_server_send")]
        public bool send( GIsi.Message req, uint8[] msg );

        // send a vector of data
        [CCode (cname = "g_isi_server_vsend")]
        public bool vsend( GIsi.Message req, Posix.iovector[] iov );

        // claim to handle a message of a certain type
        [CCode (cname = "g_isi_server_handle")]
        public GIsi.Pending handle( uchar type, GIsi.NotifyFunc notify );

    }

    /**
     * @struct SubBlockIter
     *
     * Iterator for sub blocks, which are the building blocks of (complex) ISI messages
     **/
    [CCode (cheader_filename = "libgisi.h")]
    public struct SubBlockIter
    {
        [CCode (cname = "g_isi_sb_iter_get_alpha_tag", cheader_filename = "libgisi.h")]
        public bool get_alpha_tag( out unowned string utf8, size_t len, uint pos );
        [CCode (cname = "g_isi_sb_iter_get_byte", cheader_filename = "libgisi.h")]
        public bool get_byte( out uchar byte, uint pos );
        [CCode (cname = "g_isi_sb_iter_get_data", cheader_filename = "libgisi.h")]
        public bool get_data( out void* data, uint pos );
        [CCode (cname = "g_isi_sb_iter_get_dword", cheader_filename = "libgisi.h")]
        public bool get_dword( out uint32 dword, uint pos );
        [CCode (cname = "g_isi_sb_iter_get_latin_tag", cheader_filename = "libgisi.h")]
        public bool get_latin_tag( out unowned string ascii, size_t len, uint pos );
        [CCode (cname = "g_isi_sb_iter_get_oper_code", cheader_filename = "libgisi.h")]
        public bool get_oper_code( [CCode (array_length = false)] uint8[] mcc, [CCode (array_length = false)] uint8[] mnc, uint pos );
        [CCode (cname = "g_isi_sb_iter_get_struct", cheader_filename = "libgisi.h")]
        public bool get_struct( void* ptr, size_t len, uint pos );
        [CCode (cname = "g_isi_sb_iter_get_word", cheader_filename = "libgisi.h")]
        public bool get_word( out uint16 word, uint pos );
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

        // properties
        public int id { [CCode (cname = "g_isi_sb_iter_get_id", cheader_filename = "libgisi.h")] get; }
        public size_t length { [CCode (cname = "g_isi_sb_iter_get_len", cheader_filename = "libgisi.h")] get; }

        // synthesized convenience functions
        private void checked( bool predicate ) throws GLib.Error
        {
            if ( !predicate )
            {
                throw new GLib.IOError.INVALID_DATA( @"Invalid data in SubblockIter $this" );
            }
        }

        public string to_string()
        {
            return @"<SubblockIter @ %p: ID=%u, length=%u>".printf( &this, id, (uint)length );
        }

        public bool bool_at_position( uint pos ) throws GLib.Error
        {
            return (bool) byte_at_position( pos );
        }

        public uchar byte_at_position( uint pos ) throws GLib.Error
        {
            uchar result;
            checked( get_byte( out result, pos ) );
            return result;
        }

        public uint16 word_at_position( uint pos ) throws GLib.Error
        {
            uint16 result;
            checked( get_word( out result, pos ) );
            return result;
        }

        public uint32 dword_at_position( uint pos ) throws GLib.Error
        {
            uint32 result;
            checked( get_dword( out result, pos ) );
            return result;
        }

        public string alpha_tag_at_position( size_t length, uint pos ) throws GLib.Error
        {
            string tag;
            checked( get_alpha_tag( out tag, length, pos ) );
            return tag.dup();
        }

        public string latin_tag_at_position( size_t length, uint pos ) throws GLib.Error
        {
            string tag;
            checked( get_latin_tag( out tag, length, pos ) );
            return tag.dup();
        }

        public void oper_code_at_position( out string mcc, out string mnc, uint pos ) throws GLib.Error
        {
            var a = new uint8[4];
            var b = new uint8[4];
            checked( get_oper_code( a, b, pos ) );
            mcc = (string) a;
            mnc = (string) b;
        }
    }

    [Compact]
    [CCode (cheader_filename = "libgisi.h")]
    public class Version
    {
        public int major;
        public int minor;
    }

    /**
     * Enums
     **/

    [CCode (cname = "guchar", cprefix = "PN_DEV_", has_type_id = false, cheader_filename = "libgisi.h")]
    public enum PhonetDevice
    {
        PC,
        HOST,
        SOS
    }


    [CCode (cname = "guchar", cprefix = "PN_LINK_", has_type_id = false, cheader_filename = "libgisi.h")]
    public enum PhonetLinkState
    {
        REMOVED,
        DOWN,
        UP
    }

    [CCode (cname = "guchar", cprefix = "PN_", has_type_id = false, cheader_filename = "libgisi.h,call.h,gpds.h,gss.h,info.h,mtc.h,network.h,sim.h,simauth.h,sms.h,ss.h")]
    public enum PhonetSubsystem
    {
        CALL,
        EPOC_INFO,
        GPDS,
        GSS,
        MTC,
        NETWORK,
        PHONE_INFO,
        SIM,
        SIM_AUTH,
        SMS,
        SS,
        WRAN
    }

    [CCode (cname = "gulong", cprefix = "GISI_MODEM_FLAG_", has_type_id = false, cheader_filename = "modem.h")]
    public enum ModemFlag
    {
        USE_LEGACY_SUBSCRIBE
    }

    /**
     * Callbacks
     **/

    [CCode (cheader_filename = "libgisi.h", has_target = false)]
    public delegate void DebugFunc (string fmt);

    [CCode (cheader_filename = "libgisi.h", has_target = true)]
    public delegate void NotifyFunc (GIsi.Message msg);

    [CCode (cheader_filename = "libgisi.h", has_target = true)]
    public delegate void PEPCallback( GIsi.PEP pep );

    [CCode (cheader_filename = "libgisi.h", has_target = true)]
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

    /**
     * Assorted Static functions
     **/
    // register indication listener
    [CCode (cname = "g_isi_ind_subscribe", cheader_filename = "libgisi.h")]
    public static unowned GIsi.Pending ind_subscribe( GIsi.Modem modem, uchar resource, uchar type, owned GIsi.NotifyFunc notify );

    // register notification listener
    [CCode (cname = "g_isi_ntf_subscribe", cheader_filename = "libgisi.h")]
    public static unowned GIsi.Pending ntf_subscribe( GIsi.Modem modem, uchar resource, uchar type, owned GIsi.NotifyFunc notify );

    // regster service listener
    [CCode (cname = "g_isi_service_bind", cheader_filename = "libgisi.h")]
    public static unowned GIsi.Pending service_bind( GIsi.Modem modem, uchar resource, uchar type, owned GIsi.NotifyFunc notify );

    // Cancel a pending operation
    [CCode (cname = "g_isi_remove_pending_by_owner", cheader_filename = "libgisi.h")]
    public static void remove_pending_by_owner( GIsi.Modem modem, uchar resource, void* owner );

#if 0
    //FIXME: Move all to PhonetDevice
    [CCode (cname = "g_isi_phonet_new", cheader_filename = "libgisi.h")]
    public static unowned GLib.IOChannel phonet_new( uint ifindex );
    [CCode (cname = "g_isi_phonet_peek_length", cheader_filename = "libgisi.h")]
    public static size_t phonet_peek_length( GLib.IOChannel io );
    [CCode (cname = "g_isi_phonet_read", cheader_filename = "libgisi.h")]
    public static ssize_t phonet_read( GLib.IOChannel io, void* buf, size_t len, void* addr );
#endif
} /* namespace GIsi */

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
     * SIM Information
     **/
    [Compact]
    [CCode (cname = "GIsiClient", cprefix = "SIM_", free_function = "g_isi_client_destroy", cheader_filename = "libgisi.h,sim.h")]
    public class SIM : GIsi.Client
    {
        private SIM();

        [CCode (cname = "SIM_TIMEOUT", cheader_filename = "sim.h")]
        public const uint TIMEOUT;

        public const int MAX_IMSI_LENGTH;

        [CCode (cname = "guint8", cprefix = "SIM_", has_type_id = false, cheader_filename = "sim.h")]
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

        [CCode (cname = "guint8", cprefix = "SIM_PB_", has_type_id = false, cheader_filename = "sim.h")]
        public enum SubblockType
        {
            INFO_REQUEST,
            STATUS,
            LOCATION,
            LOCATION_SEARCH,
        }

        [CCode (cname = "guint8", cprefix = "SIM_PB_", has_type_id = false, cheader_filename = "sim.h")]
        public enum PhonebookType
        {
	        ADN,
        }

        [CCode (cname = "guint8", cprefix = "SIM_PB_", has_type_id = false, cheader_filename = "sim.h")]
        public enum PhonebookTag
        {
            PB_ANR,
            PB_EMAIL,
            PB_SNE,
        }

        [CCode (cname = "guint8", cprefix = "SIM_", has_type_id = false, cheader_filename = "sim.h")]
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

        [CCode (cname = "guint8", cprefix = "", has_type_id = false, cheader_filename = "sim.h")]
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
     * @class SIMAuth
     *
     * SIM Information
     **/
    [Compact]
    [CCode (cname = "GIsiClient", cprefix = "SIM_AUTH_", free_function = "g_isi_client_destroy", cheader_filename = "libgisi.h,simauth.h")]
    public class SIMAuth : GIsi.Client
    {
        private SIMAuth();
        public const uint TIMEOUT;

        [CCode (cname = "SIM_MAX_PIN_LENGTH")]
        public const uint MAX_PIN_LENGTH;
        [CCode (cname = "SIM_MAX_PUK_LENGTH")]
        public const uint MAX_PUK_LENGTH;

        [CCode (cname = "guint8", cprefix = "SIM_AUTH_", has_type_id = false, cheader_filename = "simauth.h")]
        public enum MessageType
        {
            PROTECTED_REQ,
            PROTECTED_RESP,
            UPDATE_REQ,
            UPDATE_SUCCESS_RESP,
            UPDATE_FAIL_RESP,
            REQ,
            SUCCESS_RESP,
            FAIL_RESP,
            STATUS_IND,
            STATUS_REQ,
            STATUS_RESP,
        }

        [CCode (cname = "guint8", cprefix = "SIM_AUTH_", has_type_id = false, cheader_filename = "simauth.h")]
        public enum SubblockType
        {
            REQ_PIN,
            REQ_PUK,
        }

        [CCode (cname = "guint8", cprefix = "SIM_AUTH_ERROR_", has_type_id = false, cheader_filename = "simauth.h")]
        public enum ErrorType
        {
        	INVALID_PW,
	        NEED_PUK,
        }

        [CCode (cname = "guint8", cprefix = "SIM_AUTH_IND_", has_type_id = false, cheader_filename = "simauth.h")]
        public enum Indication
        {
            NEED_AUTH,
            NEED_NO_AUTH,
            VALID,
            INVALID,
            AUTHORIZED,
            CONFIG,
        }

        [CCode (cname = "guint8", cprefix = "SIM_AUTH_IND_", has_type_id = false, cheader_filename = "simauth.h")]
        public enum IndicationType
        {
            PIN,
            PUK,
            OK,
        }

        [CCode (cname = "guint8", cprefix = "SIM_AUTH_IND_CFG_", has_type_id = false, cheader_filename = "simauth.h")]
        public enum Configuration
        {
            UNPROTECTED,
            PROTECTED,
        }

        [CCode (cname = "guint8", cprefix = "SIM_AUTH_STATUS_RESP_", has_type_id = false, cheader_filename = "simauth.h")]
        public enum StatusResponse
        {
            NEED_PIN,
            NEED_PUK,
            RUNNING,
            INIT,
        }

        [CCode (cname = "guint8", cprefix = "SIM_AUTH_STATUS_RESP_RUNNING_", has_type_id = false, cheader_filename = "simauth.h")]
        public enum StatusResponseRunningType
        {
            AUTHORIZED,
            UNPROTECTED,
            NO_SIM,
        }

        [CCode (cname = "guint8", cprefix = "SIM_AUTH_PIN_PROTECTED_", has_type_id = false, cheader_filename = "simauth.h")]
        public enum ProtectionType
        {
            DISABLE,
            ENABLE,
            STATUS,
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

        public const uint TIMEOUT;
        public const int MAX_IMSI_LENGTH;

        [CCode (cname = "guint8", cprefix = "INFO_", has_type_id = false, cheader_filename = "info.h")]
        public enum IsiCause
        {
            OK,
            FAIL,
            NO_NUMBER,
            NOT_SUPPORTED,
        }

        [CCode (cname = "guint8", cprefix = "INFO_", has_type_id = false, cheader_filename = "info.h")]
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

        [CCode (cname = "guint8", cprefix = "INFO_SB_", has_type_id = false, cheader_filename = "info.h")]
        public enum SubblockType
        {
            PRODUCT_INFO_NAME,
            PRODUCT_INFO_MANUFACTURER,
            SN_IMEI_PLAIN,
            SN_IMEI_SV_TO_NET,
            PP,
            MCUSW_VERSION,
        }

        [CCode (cname = "guint8", cprefix = "INFO_PRODUCT_", has_type_id = false, cheader_filename = "info.h")]
        public enum ProductInfoType
        {
            NAME,
            MANUFACTURER,
        }

        [CCode (cname = "guint8", cprefix = "INFO_SN_", has_type_id = false, cheader_filename = "info.h")]
        public enum SerialNumberType
        {
            IMEI_PLAIN,
        }

        [CCode (cname = "guint8", cprefix = "INFO_", has_type_id = false, cheader_filename = "info.h", has_type_id = false)]
        public enum VersionType
        {
            MCUSW,
        }

        [CCode (cname = "guint8", cprefix = "INFO_PP_", has_type_id = false, cheader_filename = "info.h")]
        public enum PPFeatureType
        {
            MAX_PDP_CONTEXTS,
        }
    }

    /**
     * @class MTC
     *
     * Modem Terminal Control
     **/
    [Compact]
    [CCode (cname = "GIsiClient", cprefix = "MTC_", free_function = "g_isi_client_destroy", cheader_filename = "libgisi.h,mtc.h")]
    public class MTC : GIsi.Client
    {
        private MTC();

        public const uint TIMEOUT;
        public const uint STATE_REQ_TIMEOUT;

        [CCode (cname = "guint8", cprefix = "MTC_", has_type_id = false, cheader_filename = "mtc.h")]
        public enum IsiCause
        {
            OK,
            FAIL,
            NOT_ALLOWED,
            STATE_TRANSITION_GOING_ON,
            ALREADY_ACTIVE,
            SERVICE_DISABLED,
            NOT_READY_YET,
            NOT_SUPPORTED,
            TRANSITION_ONGOING,
            RESET_REQUIRED,
        }

        [CCode (cname = "guint8", cprefix = "MTC_", has_type_id = false, cheader_filename = "mtc.h")]
        public enum IsiAction
        {
            START,
            READY,
            NOS_READY,
            SOS_START,
            SOS_READY,
        }

        [CCode (cname = "guint8", cprefix = "MTC_", has_type_id = false, cheader_filename = "mtc.h")]
        public enum MessageType
        {
            STATE_REQ,
            STATE_QUERY_REQ,
            POWER_OFF_REQ,
            POWER_ON_REQ,
            STARTUP_SYNQ_REQ,
            SHUTDOWN_SYNC_REQ,
            STATE_RESP,
            STATE_QUERY_RESP,
            POWER_OFF_RESP,
            POWER_ON_RESP,
            STARTUP_SYNQ_RESP,
            SHUTDOWN_SYNC_RESP,
            STATE_INFO_IND,
            COMMON_MESSAGE,
        }

        [CCode (cname = "guint8", cprefix = "MTC_", has_type_id = false, cheader_filename = "mtc.h")]
        public enum ModemState
        {
            [CCode (cname = "MTC_STATE_NONE")]
            NONE,
            POWER_OFF,
            NORMAL,
            CHARGING,
            ALARM,
            TEST,
            LOCAL,
            WARRANTY,
            RELIABILITY,
            SELFTEST_FAIL,
            SWDL,
            RF_INACTIVE,
            ID_WRITE,
            DISCHARGING,
            DISK_WIPE,
            SW_RESET,
            CMT_ONLY_MODE,
        }
    }

    /**
     * @class Network
     *
     * Network Registration and Status
     **/
    [Compact]
    [CCode (cname = "GIsiClient", cprefix = "NET_", free_function = "g_isi_client_destroy", cheader_filename = "libgisi.h,network.h")]
    public class Network : GIsi.Client
    {
        private Network();

        [CCode (cname = "NETWORK_TIMEOUT", cheader_filename = "network.h")]
        public const uint TIMEOUT;
        [CCode (cname = "NETWORK_SCAN_TIMEOUT", cheader_filename = "network.h")]
        public const uint SCAN_TIMEOUT;
        [CCode (cname = "NETWORK_SET_TIMEOUT", cheader_filename = "network.h")]
        public const uint SET_TIMEOUT;
        [CCode (cname = "NET_INVALID_TIME", cheader_filename = "network.h")]
        public const uint INVALID_TIME;

        [CCode (cname = "guint8", cprefix = "NET_CAUSE_", has_type_id = false, cheader_filename = "network.h")]
        public enum IsiCause
        {
            OK,
            COMMUNICATION_ERROR,
            INVALID_PARAMETER,
            NO_SIM,
            SIM_NOT_YET_READY,
            NET_NOT_FOUND,
            REQUEST_NOT_ALLOWED,
            CALL_ACTIVE,
            SERVER_BUSY,
            SECURITY_CODE_REQUIRED,
            NOTHING_TO_CANCEL,
            UNABLE_TO_CANCEL,
            NETWORK_FORBIDDEN,
            REQUEST_REJECTED,
            CS_NOT_SUPPORTED,
            PAR_INFO_NOT_AVAILABLE,
            NOT_DONE,
            NO_SELECTED_NETWORK,
            REQUEST_INTERRUPTED,
            TOO_BIG_INDEX,
            MEMORY_FULL,
            SERVICE_NOT_ALLOWED,
            NOT_SUPPORTED_IN_TECH,
        }

        [CCode (cname = "guint8", cprefix = "NET_", has_type_id = false, cheader_filename = "network.h")]
        public enum MessageType
        {
            SET_REQ,
            SET_RESP,
            RSSI_GET_REQ,
            RSSI_GET_RESP,
            RSSI_IND,
            TIME_IND,
            RAT_IND,
            RAT_REQ,
            RAT_RESP,
            REG_STATUS_GET_REQ,
            REG_STATUS_GET_RESP,
            REG_STATUS_IND,
            AVAILABLE_GET_REQ,
            AVAILABLE_GET_RESP,
            OPER_NAME_READ_REQ,
            OPER_NAME_READ_RESP,
            COMMON_MESSAGE,
        }

        [CCode (cname = "guint8", cprefix = "NET_", has_type_id = false, cheader_filename = "network.h")]
        public enum SubblockType
        {
            REG_INFO_COMMON,
            OPERATOR_INFO_COMMON,
            RSSI_CURRENT,
            GSM_REG_INFO,
            DETAILED_NETWORK_INFO,
            GSM_OPERATOR_INFO,
            TIME_INFO,
            GSM_BAND_INFO,
            RAT_INFO,
            AVAIL_NETWORK_INFO_COMMON,
            GSM_REG_NETWORK_INFO,
            OPER_NAME_INFO,
        }

        [CCode (cname = "guint8", cprefix = "NET_REG_STATUS_", has_type_id = false, cheader_filename = "network.h")]
        public enum RegistrationStatus
        {
            HOME,
            ROAM,
            ROAM_BLINK,
            NOSERV,
            NOSERV_SEARCHING,
            NOSERV_NOTSEARCHING,
            NOSERV_NOSIM,
            POWER_OFF,
            NSPS,
            NSPS_NO_COVERAGE,
            NOSERV_SIM_REJECTED_BY_NW,
        }

        [CCode (cname = "guint8", cprefix = "NET_OPER_STATUS_", has_type_id = false, cheader_filename = "network.h")]
        public enum OperatorStatus
        {
            UNKNOWN,
            AVAILABLE,
            CURRENT,
            FORBIDDEN,
        }

        [CCode (cname = "guint8", cprefix = "NET_GSM_", has_type_id = false, cheader_filename = "network.h")]
        public enum NetworkPreference
        {
            HOME_PLMN,
            PREFERRED_PLMN,
            FORBIDDEN_PLMN,
            OTHER_PLMN,
            NO_PLMN_AVAIL,
        }

        [CCode (cname = "guint8", cprefix = "NET_UMTS_", has_type_id = false, cheader_filename = "network.h")]
        public enum UmtsAvailable
        {
            NOT_AVAILABLE,
            AVAILABLE,
        }

        [CCode (cname = "guint8", cprefix = "NET_GSM_BAND_", has_type_id = false, cheader_filename = "network.h")]
        public enum GsmBandInfo
        {
            900_1800,
            850_1900,
            INFO_NOT_AVAIL,
            ALL_SUPPORTED_BANDS,
            850_LOCKED,
            900_LOCKED,
            1800_LOCKED,
            1900_LOCKED,
        }

        [CCode (cname = "guint8", cprefix = "NET_GSM_", has_type_id = false, cheader_filename = "network.h")]
        public enum GsmCause
        {
            IMSI_UNKNOWN_IN_HLR,
            ILLEGAL_MS,
            IMSI_UNKNOWN_IN_VLR,
            IMEI_NOT_ACCEPTED,
            ILLEGAL_ME,
            GPRS_SERVICES_NOT_ALLOWED,
            GPRS_AND_NON_GPRS_NA,
            MS_ID_CANNOT_BE_DERIVED,
            IMPLICITLY_DETACHED,
            PLMN_NOT_ALLOWED,
            LA_NOT_ALLOWED,
            ROAMING_NOT_IN_THIS_LA,
            GPRS_SERV_NA_IN_THIS_PLMN,
            NO_SUITABLE_CELLS_IN_LA,
            MSC_TEMP_NOT_REACHABLE,
            NETWORK_FAILURE,
            MAC_FAILURE,
            SYNCH_FAILURE,
            CONGESTION,
            AUTH_UNACCEPTABLE,
            SERV_OPT_NOT_SUPPORTED,
            SERV_OPT_NOT_SUBSCRIBED,
            SERV_TEMP_OUT_OF_ORDER,
            RETRY_ENTRY_NEW_CELL_LOW,
            RETRY_ENTRY_NEW_CELL_HIGH,
            SEMANTICALLY_INCORRECT,
            INVALID_MANDATORY_INFO,
            MSG_TYPE_NONEXISTENT,
            CONDITIONAL_IE_ERROR,
            MSG_TYPE_WRONG_STATE,
            PROTOCOL_ERROR_UNSPECIFIED,
        }

        [CCode (cname = "guint8", cprefix = "NET_CS_", has_type_id = false, cheader_filename = "network.h")]
        public enum CsType
        {
            GSM,
        }

        [CCode (cname = "guint8", cprefix = "NET_", has_type_id = false, cheader_filename = "network.h")]
        public enum RatName
        {
            GSM_RAT,
            UMTS_RAT,
        }

        [CCode (cname = "guint8", cprefix = "NET_", has_type_id = false, cheader_filename = "network.h")]
        public enum RatType
        {
            CURRENT_RAT,
            SUPPORTED_RATS,
        }

        [CCode (cname = "guint8", cprefix = "NET_", has_type_id = false, cheader_filename = "network.h")]
        public enum MeasurementType
        {
            CURRENT_CELL_RSSI,
        }

        [CCode (cname = "guint8", cprefix = "NET_", has_type_id = false, cheader_filename = "network.h")]
        public enum SearchMode
        {
            MANUAL_SEARCH,
        }

        [CCode (cname = "guint8", cprefix = "NET_", has_type_id = false, cheader_filename = "network.h")]
        public enum OperationNameType
        {
            HARDCODED_LATIN_OPER_NAME,
        }

        [CCode (cname = "guint8", cprefix = "NET_SELECT_MODE_", has_type_id = false, cheader_filename = "network.h")]
        public enum OperatorSelectMode
        {
            UNKNOWN,
            MANUAL,
            AUTOMATIC,
            USER_RESELECTION,
            NO_SELECTION,
        }
    }

    /**
     * @class Call
     *
     * Call Handling
     **/
    [Compact]
    [CCode (cname = "GIsiClient", cprefix = "CALL_", free_function = "g_isi_client_destroy", cheader_filename = "libgisi.h,call.h")]
    public class Call : GIsi.Client
    {
        private Call();

        [CCode (cname = "guint8", cprefix = "CALL_", has_type_id = false, cheader_filename = "call.h")]
        public enum MessageType
        {
            CREATE_REQ,
            CREATE_RESP,
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
            PROPERTY_GET_REQ,
            PROPERTY_GET_RESP,
            PROPERTY_SET_REQ,
            PROPERTY_SET_RESP,
            PROPERTY_SET_IND,
            EMERGENCY_NBR_CHECK_REQ,
            EMERGENCY_NBR_CHECK_RESP,
            EMERGENCY_NBR_GET_REQ,
            EMERGENCY_NBR_GET_RESP,
            EMERGENCY_NBR_MODIFY_REQ,
            EMERGENCY_NBR_MODIFY_RESP,
            GSM_NOTIFICATION_IND,
            GSM_USER_TO_USER_REQ,
            GSM_USER_TO_USER_RESP,
            GSM_USER_TO_USER_IND,
            GSM_BLACKLIST_CLEAR_REQ,
            GSM_BLACKLIST_CLEAR_RESP,
            GSM_BLACKLIST_TIMER_IND,
            GSM_DATA_CH_INFO_IND,
            GSM_CCP_GET_REQ,
            GSM_CCP_GET_RESP,
            GSM_CCP_CHECK_REQ,
            GSM_CCP_CHECK_RESP,
            GSM_COMING_REJ_IND,
            GSM_RAB_IND,
            GSM_IMMEDIATE_MODIFY_IND,
            CREATE_NO_SIMATK_REQ,
            GSM_SS_DATA_IND,
            TIMER_REQ,
            TIMER_RESP,
            TIMER_NTF,
            TIMER_IND,
            TIMER_RESET_REQ,
            TIMER_RESET_RESP,
            EMERGENCY_NBR_IND,
            SERVICE_DENIED_IND,
            RELEASE_END_REQ,
            RELEASE_END_RESP,
            USER_CONNECT_IND,
            AUDIO_CONNECT_IND,
            KODIAK_ALLOW_CTRL_REQ,
            KODIAK_ALLOW_CTRL_RESP,
            SERVICE_ACTIVATE_IND,
            SERVICE_ACTIVATE_REQ,
            SERVICE_ACTIVATE_RESP,
            SIM_ATK_IND,
            CONTROL_OPER_IND,
            TEST_STATUS_IND,
            SIM_ATK_INFO_IND,
            SECURITY_IND,
            MEDIA_HANDLE_REQ,
            MEDIA_HANDLE_RESP,
            COMMON_MESSAGE,
        }


        [CCode (cname = "guint8", cprefix = "CALL_", has_type_id = false, cheader_filename = "call.h")]
        public enum SubblockType
        {
            ORIGIN_ADDRESS,
            ORIGIN_SUBADDRESS,
            DESTINATION_ADDRESS,
            DESTINATION_SUBADDRESS,
            DESTINATION_PRE_ADDRESS,
            DESTINATION_POST_ADDRESS,
            MODE,
            CAUSE,
            OPERATION,
            STATUS,
            STATUS_INFO,
            ALERTING_INFO,
            RELEASE_INFO,
            ORIGIN_INFO,
            DTMF_DIGIT,
            DTMF_STRING,
            DTMF_BCD_STRING,
            DTMF_INFO,
            PROPERTY_INFO,
            EMERGENCY_NUMBER,
            DTMF_STATUS,
            DTMF_TONE,
            GSM_CUG_INFO,
            GSM_ALERTING_PATTERN,
            GSM_DEFLECTION_ADDRESS,
            GSM_DEFLECTION_SUBADDRESS,
            GSM_REDIRECTING_ADDRESS,
            GSM_REDIRECTING_SUBADDRESS,
            GSM_REMOTE_ADDRESS,
            GSM_REMOTE_SUBADDRESS,
            GSM_USER_TO_USER_INFO,
            GSM_DIAGNOSTICS,
            GSM_SS_DIAGNOSTICS,
            GSM_NEW_DESTINATION,
            GSM_CCBS_INFO,
            GSM_ADDRESS_OF_B,
            GSM_SUBADDRESS_OF_B,
            GSM_NOTIFY,
            GSM_SS_NOTIFY,
            GSM_SS_CODE,
            GSM_SS_STATUS,
            GSM_SS_NOTIFY_INDICATOR,
            GSM_SS_HOLD_INDICATOR,
            GSM_SS_ECT_INDICATOR,
            GSM_DATA_CH_INFO,
            DESTINATION_CS_ADDRESS,
            GSM_CCP,
            GSM_RAB_INFO,
            GSM_FNUR_INFO,
            GSM_CAUSE_OF_NO_CLI,
            GSM_MM_CAUSE,
            GSM_EVENT_INFO,
            GSM_DETAILED_CAUSE,
            GSM_SS_DATA,
            TIMER,
            GSM_ALS_INFO,
            STATE_AUTO_CHANGE,
            EMERGENCY_NUMBER_INFO,
            STATUS_MODE,
            ADDR_AND_STATUS_INFO,
            DTMF_TIMERS,
            NAS_SYNC_INDICATOR,
            NW_CAUSE,
            TRACFONE_RESULT,
            KODIAK_POC,
            DISPLAY_NUMBER,
            DESTINATION_URI,
            ORIGIN_URI,
            URI,
            SYSTEM_INFO,
            SYSTEMS,
            VOIP_TIMER,
            REDIRECTING_URI,
            REMOTE_URI,
            DEFLECTION_URI,
            TRANSFER_INFO,
            FORWARDING_INFO,
            ID_INFO,
            TEST_CALL,
            AUDIO_CONF_INFO,
            SECURITY_INFO,
            SINGLE_TIMERS,
            MEDIA_INFO,
            MEDIA_HANDLE,
            MODE_CHANGE_INFO,
            ADDITIONAL_PARAMS,
            DSAC_INFO,
        }

        [CCode (cname = "guint8", cprefix = "CALL_STATUS_", has_type_id = false, cheader_filename = "call.h")]
        public enum Status
        {
            IDLE,
            CREATE,
            COMING,
            PROCEEDING,
            MO_ALERTING,
            MT_ALERTING,
            WAITING,
            ANSWERED,
            ACTIVE,
            MO_RELEASE,
            MT_RELEASE,
            HOLD_INITIATED,
            HOLD,
            RETRIEVE_INITIATED,
            RECONNECT_PENDING,
            TERMINATED,
            SWAP_INITIATED,
        }

        [CCode (cname = "guint8", cprefix = "CALL_CAUSE_", has_type_id = false, cheader_filename = "call.h")]
        public enum IsiCause
        {
            NO_CAUSE,
            NO_CALL,
            TIMEOUT,
            RELEASE_BY_USER,
            BUSY_USER_REQUEST,
            ERROR_REQUEST,
            COST_LIMIT_REACHED,
            CALL_ACTIVE,
            NO_CALL_ACTIVE,
            INVALID_CALL_MODE,
            SIGNALLING_FAILURE,
            TOO_LONG_ADDRESS,
            INVALID_ADDRESS,
            EMERGENCY,
            NO_TRAFFIC_CHANNEL,
            NO_COVERAGE,
            CODE_REQUIRED,
            NOT_ALLOWED,
            NO_DTMF,
            CHANNEL_LOSS,
            FDN_NOT_OK,
            USER_TERMINATED,
            BLACKLIST_BLOCKED,
            BLACKLIST_DELAYED,
            NUMBER_NOT_FOUND,
            NUMBER_CANNOT_REMOVE,
            EMERGENCY_FAILURE,
            CS_SUSPENDED,
            DCM_DRIVE_MODE,
            MULTIMEDIA_NOT_ALLOWED,
            SIM_REJECTED,
            NO_SIM,
            SIM_LOCK_OPERATIVE,
            SIMATKCC_REJECTED,
            SIMATKCC_MODIFIED,
            DTMF_INVALID_DIGIT,
            DTMF_SEND_ONGOING,
            CS_INACTIVE,
            SECURITY_MODE,
            TRACFONE_FAILED,
            TRACFONE_WAIT_FAILED,
            TRACFONE_CONF_FAILED,
            TEMPERATURE_LIMIT,
            KODIAK_POC_FAILED,
            NOT_REGISTERED,
            CS_CALLS_ONLY,
            VOIP_CALLS_ONLY,
            LIMITED_CALL_ACTIVE,
            LIMITED_CALL_NOT_ALLOWED,
            SECURE_CALL_NOT_POSSIBLE,
            INTERCEPT,
        }

        [CCode (cname = "guint8", cprefix = "CALL_GSM_CAUSE_", has_type_id = false, cheader_filename = "call.h")]
        public enum GsmCause
        {
            UNASSIGNED_NUMBER,
            NO_ROUTE,
            CH_UNACCEPTABLE,
            OPER_BARRING,
            NORMAL,
            USER_BUSY,
            NO_USER_RESPONSE,
            ALERT_NO_ANSWER,
            CALL_REJECTED,
            NUMBER_CHANGED,
            NON_SELECT_CLEAR,
            DEST_OUT_OF_ORDER,
            INVALID_NUMBER,
            FACILITY_REJECTED,
            RESP_TO_STATUS,
            NORMAL_UNSPECIFIED,
            NO_CHANNEL,
            NETW_OUT_OF_ORDER,
            TEMPORARY_FAILURE,
            CONGESTION,
            ACCESS_INFO_DISC,
            CHANNEL_NA,
            RESOURCES_NA,
            QOS_NA,
            FACILITY_UNSUBS,
            COMING_BARRED_CUG,
            BC_UNAUTHORIZED,
            BC_NA,
            SERVICE_NA,
            BEARER_NOT_IMPL,
            ACM_MAX,
            FACILITY_NOT_IMPL,
            ONLY_RDI_BC,
            SERVICE_NOT_IMPL,
            INVALID_TI,
            NOT_IN_CUG,
            INCOMPATIBLE_DEST,
            INV_TRANS_NET_SEL,
            SEMANTICAL_ERR,
            INVALID_MANDATORY,
            MSG_TYPE_INEXIST,
            MSG_TYPE_INCOMPAT,
            IE_NON_EXISTENT,
            COND_IE_ERROR,
            MSG_INCOMPATIBLE,
            TIMER_EXPIRY,
            PROTOCOL_ERROR,
            INTERWORKING,
        }

        [CCode (cname = "guint8", cprefix = "CALL_CAUSE_TYPE_", has_type_id = false, cheader_filename = "call.h")]
        public enum CauseType
        {
            DEFAULT,
            CLIENT,
            SERVER,
            NETWORK,
        }

        [CCode (cname = "guint8", cprefix = "CALL_ID_", has_type_id = false, cheader_filename = "call.h")]
        public enum Index
        {
            NONE,
            @1,
            @2,
            @3,
            @4,
            @5,
            @6,
            @7,
            CONFERENCE,
            WAITING,
            HOLD,
            ACTIVE,
            ALL,
        }

        [CCode (cname = "guint8", cprefix = "CALL_MODE_", has_type_id = false, cheader_filename = "call.h")]
        public enum Mode
        {
            EMERGENCY,
            SPEECH,
            [CCode (cname = "CALL_GSM_MODE_ALS_LINE_1")]
            GSM_ALS_LINE_1,
            [CCode (cname = "CALL_GSM_MODE_ALS_LINE_2")]
            GSM_ALS_LINE_2,
        }

        [CCode (cname = "guint8", cprefix = "CALL_MODE_INFO_", has_type_id = false, cheader_filename = "call.h")]
        public enum ModeInfo
        {
            NONE,
            [CCode (cname = "CALL_MODE_ORIGINATOR")]
            ORIGINATOR,
        }

        [CCode (cname = "guint8", cprefix = "CALL_PRESENTATION_", has_type_id = false, cheader_filename = "call.h")]
        public enum PresentationType
        {
            ALLOWED,
            RESTRICTED,
            [CCode (cname = "CALL_GSM_PRESENTATION_DEFAULT")]
            GSM_DEFAULT,
        }

        [CCode (cname = "guint8", cprefix = "CALL_OP_", has_type_id = false, cheader_filename = "call.h")]
        public enum Operation
        {
            HOLD,
            RETRIEVE,
            SWAP,
            CONFERENCE_BUILD,
            CONFERENCE_SPLIT,
            DATA_RATE_CHANGE,
            [CCode (cname = "GSM_OP_CUG")]
            GSM_CUG,
            [CCode (cname = "GSM_OP_TRANSFER")]
            GSM_TRANSFER,
            [CCode (cname = "GSM_OP_DEFLECT")]
            GSM_DEFLECT,
            [CCode (cname = "GSM_OP_CCBS")]
            GSM_CCBS,
            [CCode (cname = "GSM_OP_UUS1")]
            GSM_UUS1,
            [CCode (cname = "GSM_OP_UUS2")]
            GSM_UUS2,
            [CCode (cname = "GSM_OP_UUS3")]
            GSM_UUS3,
        }

        /*
        enum {
            CALL_GSM_OP_UUS_REQUIRED,
        }
        */

        [CCode (cname = "guint8", cprefix = "CALL_DTMF_", has_type_id = false, cheader_filename = "call.h")]
        public enum DTMFIndicationType
        {
            ENABLE_TONE_IND_SEND,
            DISABLE_TONE_IND_SEND,
        }

        [CCode (cname = "guint8", cprefix = "CALL_STATUS_MODE_", has_type_id = false, cheader_filename = "call.h")]
        public enum StatusMode
        {
            DEFAULT,
            ADDR,
            ADDR_AND_ORIGIN,
            POC,
            VOIP_ADDR,
        }
    }

    /**
     * @class SMS
     *
     * Short Messages Server
     **/
    [Compact]
    [CCode (cname = "GIsiClient", cprefix = "SMS_", free_function = "g_isi_client_destroy", cheader_filename = "libgisi.h,sms.h")]
    public class SMS : GIsi.Client
    {
        private SMS();
        public const uint TIMEOUT;

        [CCode (cname = "guint8", cprefix = "SMS_", has_type_id = false, cheader_filename = "sms.h")]
        public enum IsiCause
        {
            OK,
            ERR_ROUTING_RELEASED,
            ERR_INVALID_PARAMETER,
            ERR_DEVICE_FAILURE,
            ERR_PP_RESERVED,
            ERR_ROUTE_NOT_AVAILABLE,
            ERR_ROUTE_NOT_ALLOWED,
            ERR_SERVICE_RESERVED,
            ERR_INVALID_LOCATION,
            ERR_NO_SIM,
            ERR_SIM_NOT_READY,
            ERR_NO_NETW_RESPONSE,
            ERR_DEST_ADDR_FDN_RESTRICTED,
            ERR_SMSC_ADDR_FDN_RESTRICTED,
            ERR_RESEND_ALREADY_DONE,
            ERR_SMSC_ADDR_NOT_AVAILABLE,
            ERR_ROUTING_FAILED,
            ERR_CS_INACTIVE,
            ERR_SAT_MO_CONTROL_MODIFIED,
            ERR_SAT_MO_CONTROL_REJECT,
            ERR_TRACFONE_FAILED
        }

        [CCode (cname = "guint8", cprefix = "SMS_", has_type_id = false, cheader_filename = "sms.h")]
        public enum MessageType
        {
            MESSAGE_SEND_REQ,
            MESSAGE_SEND_RESP,
            PP_ROUTING_REQ,
            PP_ROUTING_RESP,
            PP_ROUTING_NTF,
            GSM_RECEIVED_PP_REPORT_REQ,
            GSM_RECEIVED_PP_REPORT_RESP,
            GSM_CB_ROUTING_REQ,
            GSM_CB_ROUTING_RESP,
            GSM_CB_ROUTING_NTF,
            MESSAGE_SEND_STATUS_IND,
            COMMON_MESSAGE
        }

        [CCode (cname = "guint8", cprefix = "SMS_", has_type_id = false, cheader_filename = "sms.h")]
        public enum SubblockType
        {
            GSM_DELIVER,
            GSM_STATUS_REPORT,
            GSM_SUBMIT,
            GSM_COMMAND,
            GSM_DELIVER_REPORT,
            GSM_REPORT,
            GSM_ROUTING,
            GSM_CB_MESSAGE,
            GSM_TPDU,
            COMMON_DATA,
            ADDRESS
        }

        [CCode (cname = "guint8", cprefix = "SMS_", has_type_id = false, cheader_filename = "sms.h")]
        public enum RoutingCommand
        {
            ROUTING_RELEASE,
            ROUTING_SET,
            ROUTING_SUSPEND,
            ROUTING_RESUME,
            ROUTING_UPDATE
        }

        [CCode (cname = "guint8", cprefix = "SMS_GSM_ROUTING_MODE_", has_type_id = false, cheader_filename = "sms.h")]
        public enum RoutingMode
        {
            ALL,
            CB_DDL
        }

        [CCode (cname = "guint8", cprefix = "SMS_GSM_", has_type_id = false, cheader_filename = "sms.h")]
        public enum RoutingType
        {
            TPDU_ROUTING
        }

        [CCode (cname = "guint8", cprefix = "SMS_", has_type_id = false, cheader_filename = "sms.h")]
        public enum RoutePreference
        {
            ROUTE_GPRS_PREF,
            ROUTE_CS,
            ROUTE_GPRS,
            ROUTE_CS_PREF,
            ROUTE_DEFAULT
        }

        [CCode (cname = "guint8", cprefix = "SMS_", has_type_id = false, cheader_filename = "sms.h")]
        public enum SubjectListType
        {
            CB_ALLOWED_IDS_LIST,
            CB_NOT_ALLOWED_IDS_LIST
        }
    }

    /**
     * @class GSS
     *
     * General Stack Server
     **/
    [Compact]
    [CCode (cname = "GIsiClient", cprefix = "GSS_", free_function = "g_isi_client_destroy", cheader_filename = "libgisi.h,gss.h")]
    public class GSS : GIsi.Client
    {
        private GSS();
        public const uint TIMEOUT;

        [CCode (cname = "guint8", cprefix = "GSS_CSS_", has_type_id = false, cheader_filename = "gss.h")]
        public enum MessageType
        {
            SERVICE_REQ,
            SERVICE_RESP,
            SERVICE_FAIL_RESP,
        }

        [CCode (cname = "guint8", cprefix = "GSS_", has_type_id = false, cheader_filename = "gss.h")]
        public enum SubblockType
        {
            RAT_INFO,
        }

        [CCode (cname = "guint8", cprefix = "GSS_", has_type_id = false, cheader_filename = "gss.h")]
        public enum SelectionMode
        {
            DUAL_RAT,
            GSM_RAT,
            UMTS_RAT,
        }

        [CCode (cname = "guint8", cprefix = "GSS_", has_type_id = false, cheader_filename = "gss.h")]
        public enum Operation
        {
            SELECTED_RAT_WRITE,
            SELECTED_RAT_READ,
        }
    }

    /**
     * @class SS
     *
     * Subscriber Services
     **/
    [Compact]
    [CCode (cname = "GIsiClient", cprefix = "SS_", free_function = "g_isi_client_destroy", cheader_filename = "libgisi.h,ss.h")]
    public class SS : GIsi.Client
    {
        private SS();
        public const uint TIMEOUT;
        public const uint MAX_USSD_LENGTH;

        [CCode (cname = "guint8", cprefix = "SS_", has_type_id = false, cheader_filename = "ss.h")]
        public enum MessageType
        {
            SERVICE_REQ,
            SERVICE_COMPLETED_RESP,
            SERVICE_FAILED_RESP,
            GSM_USSD_SEND_REQ,
            GSM_USSD_SEND_RESP,
            GSM_USSD_RECEIVE_IND,
            STATUS_IND,
            COMMON_MESSAGE,
        }

        [CCode (cname = "guint8", cprefix = "SS_", has_type_id = false, cheader_filename = "ss.h")]
        public enum SubblockType
        {
            FORWARDING,
            STATUS_RESULT,
            GSM_PASSWORD,
            GSM_FORWARDING_INFO,
            GSM_FORWARDING_FEATURE,
            GSM_DATA,
            GSM_BSC_INFO,
            GSM_PASSWORD_INFO,
            GSM_INDICATE_PASSWORD_ERROR,
            GSM_INDICATE_ERROR,
            GSM_ADDITIONAL_INFO,
            GSM_USSD_STRING,
        }

        [CCode (cname = "guint8", cprefix = "SS_", has_type_id = false, cheader_filename = "ss.h")]
        public enum IsiCause
        {
            GSM_ACTIVE,
            GSM_REGISTERED,
            GSM_PROVISIONED,
            GSM_QUIESCENT,
        }

        [CCode (cname = "guint8", cprefix = "", has_type_id = false, cheader_filename = "ss.h")]
        public enum UssdType
        {
            GSM_USSD_MT_REPLY,
            GSM_USSD_COMMAND,
            GSM_USSD_REQUEST,
            GSM_USSD_NOTIFY,
            GSM_USSD_END =			0x05
        }

        [CCode (cname = "guint8", cprefix = "", has_type_id = false, cheader_filename = "ss.h")]
        public enum UssdStatus
        {
            GSM_STATUS_REQUEST_USSD_START,
            GSM_STATUS_REQUEST_USSD_STOP,
            GSM_STATUS_REQUEST_USSD_FAILED,
        }

        [CCode (cname = "guint8", cprefix = "", has_type_id = false, cheader_filename = "ss.h")]
        public enum Operation
        {
            ACTIVATION,
            DEACTIVATION,
            REGISTRATION,
            ERASURE,
            INTERROGATION,
            GSM_PASSWORD_REGISTRATION,
        }

        [CCode (cname = "guint8", cprefix = "", has_type_id = false, cheader_filename = "ss.h")]
        public enum BasicServiceCode
        {
            ALL_TELE_AND_BEARER,
            GSM_ALL_TELE,
            GSM_TELEPHONY,
            GSM_ALL_DATA_TELE,
            GSM_FACSIMILE,
            GSM_SMS,
            GSM_VOICE_GROUP,
            GSM_ALL_TELE_EXC_SMS,
            GSM_ALL_BEARER,
            GSM_ALL_ASYNC,
            GSM_ALL_SYNC,
            GSM_ALL_DATA_CIRCUIT_SYNC,
            GSM_ALL_DATA_CIRCUIT_ASYNC,
            GSM_ALL_DATA_PACKET_SYNC,
            GSM_ALL_PAD_ACCESS,
        }

        [CCode (cname = "guint8", cprefix = "", has_type_id = false, cheader_filename = "ss.h")]
        public enum Code
        {
            GSM_ALL_FORWARDINGS,
            GSM_ALL_COND_FORWARDINGS,
            GSM_FORW_UNCONDITIONAL,
            GSM_BARR_ALL_OUT,
            GSM_OUTGOING_BARR_SERV,
            GSM_INCOMING_BARR_SERV,
            GSM_BARR_ALL_IN,
            GSM_CALL_WAITING,
            GSM_FORW_NO_REPLY,
            GSM_FORW_NO_REACH,
            GSM_FORW_BUSY,
            GSM_ALL_BARRINGS,
            GSM_BARR_OUT_INTER,
            GSM_BARR_OUT_INTER_EXC_HOME,
            GSM_BARR_ALL_IN_ROAM,
        }

        [CCode (cname = "guint8", cprefix = "", has_type_id = false, cheader_filename = "ss.h")]
        public enum ResponseData
        {
            SEND_ADDITIONAL_INFO,
        }
    }

    /**
     * @class GPDS
     *
     * General Packat Data Server
     **/
    [Compact]
    [CCode (cname = "GIsiClient", cprefix = "SS_", free_function = "g_isi_client_destroy", cheader_filename = "libgisi.h,gpds.h")]
    public class GPDS : GIsi.Client
    {
        private GPDS();

        [CCode (cprefix = "PN_", has_type_id = false, cheader_filename = "gpds.h")]
        public const uchar PEP_TYPE_GPRS;

        [CCode (cprefix = "PN_", has_type_id = false, cheader_filename = "gpds.h")]
        public const uchar WRAN;

        [CCode (cname = "guint8", cprefix = "GPDS_", has_type_id = false, cheader_filename = "gpds.h")]
        public enum MessageType
        {
	        LL_CONFIGURE_REQ,
	        LL_CONFIGURE_RESP,
	        CONTEXT_ID_CREATE_REQ,
	        CONTEXT_ID_CREATE_RESP,
	        CONTEXT_ID_CREATE_IND,
	        CONTEXT_ID_DELETE_IND,
	        CONTEXT_CONFIGURE_REQ,
	        CONTEXT_CONFIGURE_RESP,
	        CONTEXT_ACTIVATE_REQ,
	        CONTEXT_ACTIVATE_RESP,
	        CONTEXT_ACTIVATE_IND,
	        CONTEXT_DEACTIVATE_REQ,
	        CONTEXT_DEACTIVATE_RESP,
	        CONTEXT_DEACTIVATE_IND,
	        CONTEXT_MWI_ACT_REQUEST_IND,
	        CONTEXT_NWI_ACT_REJECT_REQ,
	        CONTEXT_NWI_ACT_REJECT_RESP,
	        CONFIGURE_REQ,
	        CONFIGURE_RESP,
	        ATTACH_REQ,
	        ATTACH_RESP,
	        ATTACH_IND,
	        DETACH_REQ,
	        DETACH_RESP,
	        DETACH_IND,
	        STATUS_REQ,
	        STATUS_RESP,
	        SMS_PDU_SEND_REQ,
	        SMS_PDU_SEND_RESP,
	        SMS_PDU_RECEIVE_IND,
	        TRANSFER_STATUS_IND,
	        CONTEXT_ACTIVATE_FAIL_IND,
	        LL_BIND_REQ,
	        LL_BIND_RESP,
	        CONTEXT_STATUS_REQ,
	        CONTEXT_STATUS_RESP,
	        CONTEXT_STATUS_IND,
	        CONTEXT_ACTIVATING_IND,
	        CONTEXT_MODIFY_REQ,
	        CONTEXT_MODIFY_RESP,
	        CONTEXT_MODIFY_IND,
	        ATTACH_FAIL_IND,
	        CONTEXT_DEACTIVATING_IND,
	        CONFIGURATION_INFO_REQ,
	        CONFIGURATION_INFO_RESP,
	        CONFIGURATION_INFO_IND,
	        CONTEXT_AUTH_REQ,
	        CONTEXT_AUTH_RESP,
	        TEST_MODE_REQ,
	        TEST_MODE_RESP,
	        RADIO_ACTIVITY_IND,
	        FORCED_READY_STATE_REQ,
	        FORCED_READY_STATE_RESP,
	        CONTEXTS_CLEAR_REQ,
	        CONTEXTS_CLEAR_RESP,
	        MBMS_SERVICE_SELECTION_REQ,
	        MBMS_SERVICE_SELECTION_RESP,
	        MBMS_STATUS_IND,
	        MBMS_CONTEXT_CREATE_REQ,
	        MBMS_CONTEXT_CREATE_RESP,
	        MBMS_CONTEXT_ACTIVATE_REQ,
	        MBMS_CONTEXT_ACTIVATE_RESP,
	        MBMS_CONTEXT_DELETE_REQ,
	        MBMS_CONTEXT_DELETE_RESP,
	        MBMS_CONTEXT_DELETE_IND,
	        MBMS_SERVICE_SELECTION_IND,
	        MBMS_SERVICE_AVAILABLE_IND,
	        TEST_REQ,
	        TEST_RESP,
            COMMON_MESSAGE,
        }

        [CCode (cname = "guint8", cprefix = "GPDS_", has_type_id = false, cheader_filename = "gpds.h")]
        public enum SubblockType
        {
	        COMP_INFO,
	        QOS_REQ_INFO,
	        QOS_MIN_INFO,
	        QOS_NEG_INFO,
	        PDP_ADDRESS_INFO,
	        APN_INFO,
	        QOS99_REQ_INFO,
	        QOS99_MIN_INFO,
	        QOS99_NEG_INFO,
	        TFT_INFO,
	        TFT_FILTER_INFO,
	        USER_NAME_INFO,
	        PASSWORD_INFO,
	        PDNS_ADDRESS_INFO,
	        SDNS_ADDRESS_INFO,
	        CHALLENGE_INFO,
	        DNS_ADDRESS_REQ_INFO,
        }

        [CCode (cname = "guint8", cprefix = "GPDS_", has_type_id = false, cheader_filename = "gpds.h")]
        public enum Status
        {
	        ERROR,
	        OK,
	        FAIL,
        }

        [CCode (cname = "guint8", cprefix = "GPDS_", has_type_id = false, cheader_filename = "sim.h")]
        public enum IsiCause
        {
	        CAUSE_UNKNOWN,
	        CAUSE_IMSI,
	        CAUSE_MS_ILLEGAL,
	        CAUSE_ME_ILLEGAL,
	        CAUSE_GPRS_NOT_ALLOWED,
	        NOT_ALLOWED,
	        CAUSE_MS_IDENTITY,
	        CAUSE_DETACH,
	        PLMN_NOT_ALLOWED,
	        LA_NOT_ALLOWED,
	        ROAMING_NOT_ALLOWED,
	        CAUSE_GPRS_NOT_ALLOWED_IN_PLMN,
	        CAUSE_MSC_NOT_REACH,
	        CAUSE_PLMN_FAIL,
	        CAUSE_NETWORK_CONGESTION,
	        CAUSE_MBMS_BEARER_CAPABILITY_INSUFFICIENT,
	        CAUSE_LLC_SNDCP_FAILURE,
	        CAUSE_RESOURCE_INSUFF,
	        CAUSE_APN,
	        CAUSE_PDP_UNKNOWN,
	        CAUSE_AUTHENTICATION,
	        CAUSE_ACT_REJECT_GGSN,
	        CAUSE_ACT_REJECT,
	        CAUSE_SERV_OPT_NOT_SUPPORTED,
	        CAUSE_SERV_OPT_NOT_SUBSCRIBED,
	        CAUSE_SERV_OPT_OUT_OF_ORDER,
	        CAUSE_NSAPI_ALREADY_USED,
	        CAUSE_DEACT_REGULAR,
	        CAUSE_QOS,
	        CAUSE_NETWORK_FAIL,
	        CAUSE_REACTIVATION_REQ,
	        CAUSE_FEAT_NOT_SUPPORTED,
	        CAUSE_TFT_SEMANTIC_ERROR,
	        CAUSE_TFT_SYNTAX_ERROR,
	        CAUSE_CONTEXT_UNKNOWN,
	        CAUSE_FILTER_SEMANTIC_ERROR,
	        CAUSE_FILTER_SYNTAX_ERROR,
	        CAUSE_CONT_WITHOUT_TFT,
	        CAUSE_MULTICAST_MEMBERSHIP_TIMEOUT,
	        CAUSE_INVALID_MANDATORY_INFO,
	        CAUSE_MSG_TYPE_NON_EXISTENTOR_NOT_IMPLTD,
	        CAUSE_MSG_TYPE_NOT_COMPATIBLE_WITH_PROTOCOL_STATE,
	        CAUSE_IE_NON_EXISTENT_OR_NOT_IMPLEMENTED,
	        CAUSE_CONDITIONAL_IE_ERROR,
	        CUASEMSG_NOT_COMPATIBLE_WITH_PROTOCOL_STATE,
	        CAUSE_UNSPECIFIED,
	        CAUSE_APN_INCOMPATIBLE_WITH_CURR_CTXT,
	        CAUSE_FDN,
	        CAUSE_USER_ABORT,
	        CAUSE_CS_INACTIVE,
	        CAUSE_CSD_OVERRIDE,
	        CAUSE_APN_CONTROL,
	        CAUSE_CALL_CONTROL,
	        CAUSE_TEMPERATURE_LIMIT,
	        CAUSE_RETRY_COUNTER_EXPIRED,
	        CAUSE_NO_CONNECTION,
	        CAUSE_DETACHED,
	        CAUSE_NO_SERVICE_POWER_SAVE,
	        CAUSE_SIM_REMOVED,
	        CAUSE_POWER_OFF,
	        CAUSE_LAI_FORBIDDEN_NATIONAL_ROAM_LIST,
	        CAUSE_LAI_FORBIDDEN_REG_PROVISION_LIST,
	        CAUSE_ACCESS_BARRED,
	        CAUSE_FATAL_FAILURE,
	        CAUSE_AUT_FAILURE,
        }

        [CCode (cname = "guint8", cprefix = "GPDS_TRANSFER_", has_type_id = false, cheader_filename = "gpds.h")]
        public enum TransferStatus
        {
	        NOT_AVAIL,
	        AVAIL,
        }

        [CCode (cname = "guint8", cprefix = "GPDS_TRANSFER_CAUSE_", has_type_id = false, cheader_filename = "gpds.h")]
        public enum TransferCause
        {
	        ATTACHED,
	        DETACHED,
	        RESUMED,
	        SUSPENDED_NO_COVERAGE,
	        SUSPENDED_CALL_SMS,
	        SUSPENDED_CALL,
	        SUSPENDED_RAU,
	        SUSPENDED_LU,
	        DSAC_RESTRICTION,
        }

        [CCode (cname = "guint8", cprefix = "GPDS_CONT_TYPE_", has_type_id = false, cheader_filename = "gpds.h")]
        public enum ContextType
        {
	        NORMAL,
	        NWI,
	        SEC,
        }

        [CCode (cname = "guint8", cprefix = "GPDS_LL_", has_type_id = false, cheader_filename = "gpds.h")]
        public enum PppMode
        {
	        FRAMED_PPP,
	        NONFRAMED_PPP,
	        PLAIN,
        }

        [CCode (cname = "guint8", cprefix = "GPDS_PDP_TYPE_", has_type_id = false, cheader_filename = "gpds.h")]
        public enum PdpType
        {
	        PPP,
	        IPV4,
	        IPV6,
	        DEFAULT,
        }

        [CCode (cname = "guint8", cprefix = "GPDS_", has_type_id = false, cheader_filename = "gpds.h")]
        public enum RequestMode
        {
	        FOLLOW_OFF,
	        FOLLOW_ON,
        }

        [CCode (cname = "guint8", cprefix = "GPDS_", has_type_id = false, cheader_filename = "gpds.h")]
        public enum AttachStatus
        {
	        DETACHED,
	        ATTACHED,
        }

        [CCode (cname = "guint8", cprefix = "GPDS_ATTACH_MODE_", has_type_id = false, cheader_filename = "gpds.h")]
        public enum AttachMode
        {
	        MANUAL,
	        AUTOMATIC,
	        DEFAULT,
        }

        [CCode (cname = "guint8", cprefix = "GPDS_MT_ACT_MODE_", has_type_id = false, cheader_filename = "gpds.h")]
        public enum MtActMode
        {
	        REJECT,
	        ACCEPT,
	        DEFAULT,
        }

        [CCode (cname = "guint8", cprefix = "GPDS_CLASSC_MODE_", has_type_id = false, cheader_filename = "gpds.h")]
        public enum ClassCMode
        {
	        GPRS,
	        GSM,
	        DEFAULT,
        }

        [CCode (cname = "guint8", cprefix = "GPDS_AOL_CTX_", has_type_id = false, cheader_filename = "gpds.h")]
        public enum AolContext
        {
	        NOT_ACTIVE,
	        HPLMN_ACTIVE,
	        VPLMN_ACTIVE,
	        ACTIVE,
	        DEFAULT,
        }
    }

} /* namespace GIsiClient */


/**
 * @namespace GIsiServer
 *
 * The high level protocol servers
 **/

[CCode (cprefix = "")]
namespace GIsiServer
{
    /**
     * @class EpocInfo
     *
     * EPOC Info Server
     **/
    [Compact]
    [CCode (cname = "GIsiServer", cprefix = "INFO_", free_function = "g_isi_server_destroy", cheader_filename = "libgisi.h,info.h")]
    public class EpocInfo : GIsi.Server
    {
        private EpocInfo();

        [CCode (cname = "guint8", cprefix = "INFO_", has_type_id = false, cheader_filename = "info.h")]
        public enum IsiCause
        {
            OK,
            FAIL,
            NO_NUMBER,
            NOT_SUPPORTED,
        }

        [CCode (cname = "guint8", cprefix = "INFO_", has_type_id = false, cheader_filename = "info.h")]
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
        }

        [CCode (cname = "guint8", cprefix = "INFO_SB_", has_type_id = false, cheader_filename = "info.h")]
        public enum SubblockType
        {
            MODEMSW_VERSION,
            PRODUCT_INFO_NAME,
            PRODUCT_INFO_MANUFACTURER,
            SN_IMEI_PLAIN,
            SN_IMEI_SV_TO_NET,
            PP,
            MCUSW_VERSION,
        }

    }

} /* namespace GIsiServer */

// vim:ts=4:sw=4:expandtab
