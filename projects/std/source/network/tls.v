# std.network.tls — 一手 native TLS（OpenSSL / Schannel / Secure Transport）

namespace std.network.tls;

using std.text;
using std.network;

class TlsConfig {
    cert_path: utf8
    key_path: utf8
    min_version: utf8
    server_mode: bool
}

class TlsStream {
    fd: i32
    tls_handle: i32
    closed: bool
}

class TlsError {
    message: utf8
}

[host_contract]
micro tls_wrap_server(stream_fd: i32, cert_path: utf8, key_path: utf8, min_version: utf8): i32

[host_contract]
micro tls_wrap_client(stream_fd: i32, min_version: utf8): i32

[host_contract]
micro tls_read(handle: i32, max_len: i32): utf8

[host_contract]
micro tls_write(handle: i32, data: utf8): i32

[host_contract]
micro tls_close(handle: i32): unit

imply TlsConfig {
    micro server(cert_path: utf8, key_path: utf8): Self {
        return Self {
            cert_path: cert_path,
            key_path: key_path,
            min_version: "1.2",
            server_mode: true
        }
    }

    micro client(): Self {
        return Self {
            cert_path: "",
            key_path: "",
            min_version: "1.2",
            server_mode: false
        }
    }
}

imply TlsStream {
    micro invalid(): Self {
        return Self { fd: -1, tls_handle: -1, closed: true }
    }

    micro read(mut self, max_len: i32): utf8 {
        if self.closed || self.tls_handle < 0 {
            return ""
        }
        return tls_read(self.tls_handle, max_len)
    }

    micro write(mut self, data: utf8): i32 {
        if self.closed || self.tls_handle < 0 {
            return -1
        }
        return tls_write(self.tls_handle, data)
    }

    micro close(mut self): unit {
        if self.closed == false && self.tls_handle >= 0 {
            tls_close(self.tls_handle)
        }
        self.closed = true
        self.tls_handle = -1
    }
}

micro wrap_tls(stream: TcpStream, config: TlsConfig): TlsStream {
    if stream.closed || stream.fd < 0 {
        return TlsStream::invalid()
    }
    let handle: i32
    if config.server_mode {
        handle = tls_wrap_server(stream.fd, config.cert_path, config.key_path, config.min_version)
    } else {
        handle = tls_wrap_client(stream.fd, config.min_version)
    }
    if handle < 0 {
        stream.close()
        return TlsStream::invalid()
    }
    return TlsStream { fd: stream.fd, tls_handle: handle, closed: false }
}
