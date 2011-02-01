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

        public void readManufacturer( StringResultFunc cb )
        {
            var req = new uchar[] { GIsiClient.PhoneInfo.MessageType.PRODUCT_INFO_READ_REQ, GIsiClient.PhoneInfo.SubblockType.PRODUCT_INFO_MANUFACTURER };
            ll.send( req, ( msg ) => {
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

                uchar length;
                if ( !sbi.get_byte( out length, 3 ) )
                {
                    cb( ErrorCode.INVALID_FORMAT, null );
                    return;
                }

                unowned string str = null;
                if ( !sbi.get_latin_tag( out str, length, 4 ) )
                {
                    cb( ErrorCode.INVALID_FORMAT, null );
                    return;
                }

                cb( ErrorCode.OK, str.dup() );
            } );
        }
    }
} /* namespace GIsiComm */

