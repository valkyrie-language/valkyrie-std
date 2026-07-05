# std.network — 阻塞 TCP 传输（平台由 adaptor host_provider 实现）

namespace std.network;

using std.text;

class SocketAddr {
    host: utf8
    port: i32
}

class TcpStream {
    fd: i32
    closed: bool
}

class ListenSocket {
    fd: i32
    host: utf8
    port: i32
    closed: bool
}

[host_contract]
micro net_socket_create(domain: i32, type_: i32, protocol: i32): i32

[host_contract]
micro net_bind(fd: i32, host: utf8, port: i32): i32

[host_contract]
micro net_listen(fd: i32, backlog: i32): i32

[host_contract]
micro net_accept(fd: i32): i32

[host_contract]
micro net_connect(fd: i32, host: utf8, port: i32): i32

[host_contract]
micro net_read(fd: i32, max_len: i32): utf8

[host_contract]
micro net_write(fd: i32, data: utf8): i32

[host_contract]
micro net_close(fd: i32): unit

imply SocketAddr {
    micro parse(host: utf8, port: i32): Self {
        return Self { host: host, port: port }
    }
}

imply TcpStream {
    micro invalid(): Self {
        return Self { fd: -1, closed: true }
    }

    micro from_fd(fd: i32): Self {
        return Self { fd: fd, closed: fd < 0 }
    }

    micro connect(addr: SocketAddr): Self {
        let domain: i32 = 2
        let type_: i32 = 1
        let fd: i32 = net_socket_create(domain, type_, 0)
        if fd < 0 {
            return TcpStream::invalid()
        }
        let rc: i32 = net_connect(fd, addr.host, addr.port)
        if rc < 0 {
            net_close(fd)
            return TcpStream::invalid()
        }
        return TcpStream::from_fd(fd)
    }

    micro read(mut self, max_len: i32): utf8 {
        if self.closed || self.fd < 0 {
            return ""
        }
        return net_read(self.fd, max_len)
    }

    micro write(mut self, data: utf8): i32 {
        if self.closed || self.fd < 0 {
            return -1
        }
        return net_write(self.fd, data)
    }

    micro close(mut self): unit {
        if self.closed == false && self.fd >= 0 {
            net_close(self.fd)
        }
        self.closed = true
        self.fd = -1
    }
}

imply ListenSocket {
    micro bind(host: utf8, port: i32): Self {
        let domain: i32 = 2
        let type_: i32 = 1
        let fd: i32 = net_socket_create(domain, type_, 0)
        if fd < 0 {
            return Self { fd: -1, host: host, port: port, closed: true }
        }
        let rc: i32 = net_bind(fd, host, port)
        if rc < 0 {
            net_close(fd)
            return Self { fd: -1, host: host, port: port, closed: true }
        }
        let listen_rc: i32 = net_listen(fd, 128)
        if listen_rc < 0 {
            net_close(fd)
            return Self { fd: -1, host: host, port: port, closed: true }
        }
        return Self { fd: fd, host: host, port: port, closed: false }
    }

    micro accept(mut self): TcpStream {
        if self.closed || self.fd < 0 {
            return TcpStream::invalid()
        }
        let client_fd: i32 = net_accept(self.fd)
        return TcpStream::from_fd(client_fd)
    }

    micro close(mut self): unit {
        if self.closed == false && self.fd >= 0 {
            net_close(self.fd)
        }
        self.closed = true
        self.fd = -1
    }
}
