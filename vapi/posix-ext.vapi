namespace Posix
{
	[CCode (cheader_filename = "arpa/inet.h")]
	unowned string inet_ntop (int af, void* src, uint8[] dst);

    [CCode (has_type_id = false, cheader_filename = "netinet/in.h")]
    const int INET_ADDRSTRLEN;
    const int INET6_ADDRSTRLEN;
}

// vim:ts=4:sw=4:expandtab
