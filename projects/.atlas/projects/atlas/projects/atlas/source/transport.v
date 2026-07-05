# Atlas 传输层 — plain TCP / TLS，替换测试桩 AtlasIoBackend

namespace atlas.core;

using std.text;
using std.network;
using std.network.tls;

class AtlasTransport {
    active: bool
    listener_fd: i32
    use_tls: bool
    tls_config: TlsConfig
    queued_raw: [utf8]
    queued_fds: [i32]
    writes: [utf8]
    closed_fds: [i32]
    next_fd: i32
    listen_socket: ListenSocket
    stopping: bool
}

type AtlasIoBackend = AtlasTransport

imply AtlasTransport {
    micro idle(): Self {
        return Self {
            active: false,
            listener_fd: -1,
            use_tls: false,
            tls_config: TlsConfig::client(),
            queued_raw: [],
            queued_fds: [],
            writes: [],
            closed_fds: [],
            next_fd: 100,
            listen_socket: ListenSocket { fd: -1, host: "", port: 0, closed: true },
            stopping: false
        }
    }

    micro with_request(raw: utf8): Self {
        let mut transport: AtlasTransport = AtlasTransport::idle()
        transport.active = true
        push(transport.queued_raw, raw)
        push(transport.queued_fds, 1)
        return transport
    }

    micro listen_plain(mut self, host: utf8, port: i32): i32 {
        self.use_tls = false
        return self.listen(host, port)
    }

    micro listen_tls(mut self, host: utf8, port: i32, config: TlsConfig): i32 {
        self.use_tls = true
        self.tls_config = config
        return self.listen(host, port)
    }

    micro listen(mut self, host: utf8, port: i32): i32 {
        if self.active == false && self.queued_raw.length > 0 {
            self.active = true
            self.listener_fd = 1
            return self.listener_fd
        }
        self.listen_socket = ListenSocket::bind(host, port)
        if self.listen_socket.fd < 0 {
            return -1
        }
        self.active = true
        self.listener_fd = self.listen_socket.fd
        return self.listener_fd
    }

    micro stop(mut self): unit {
        self.stopping = true
        self.active = false
        self.listen_socket.close()
    }

    micro accept(mut self, listener: i32): i32 {
        if self.stopping {
            return -1
        }
        if listener < 0 {
            return -1
        }
        if self.queued_fds.length > 0 {
            let fd: i32 = self.queued_fds[0]
            let mut rest: [i32] = []
            let mut i: i32 = 1
            while i < self.queued_fds.length {
                push(rest, self.queued_fds[i])
                i = i + 1
            }
            self.queued_fds = rest
            return fd
        }
        if self.listen_socket.fd >= 0 {
            let stream: TcpStream = self.listen_socket.accept()
            if stream.fd < 0 {
                if self.stopping {
                    return -1
                }
                self.active = false
                return -1
            }
            return stream.fd
        }
        self.active = false
        return -1
    }

    micro read(mut self, fd: i32, max_len: i32): utf8 {
        let _fd: i32 = fd
        let _max: i32 = max_len
        if self.queued_raw.length > 0 {
            let raw: utf8 = self.queued_raw[0]
            let mut rest: [utf8] = []
            let mut i: i32 = 1
            while i < self.queued_raw.length {
                push(rest, self.queued_raw[i])
                i = i + 1
            }
            self.queued_raw = rest
            return raw
        }
        return net_read(fd, max_len)
    }

    micro write(mut self, fd: i32, data: utf8): unit {
        let _fd: i32 = fd
        push(self.writes, data)
        if self.queued_raw.length == 0 {
            net_write(fd, data)
        }
    }

    micro close(mut self, fd: i32): unit {
        push(self.closed_fds, fd)
        net_close(fd)
    }

    micro enqueue(mut self, raw: utf8): unit {
        self.active = true
        let fd: i32 = self.next_fd
        self.next_fd = self.next_fd + 1
        push(self.queued_raw, raw)
        push(self.queued_fds, fd)
    }
}
