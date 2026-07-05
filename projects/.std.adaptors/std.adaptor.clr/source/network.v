# CLR stub network host_provider for std.network (managed test targets)

[host_provider(std::network::net_socket_create)]
micro net_socket_create(domain: i32, type_: i32, protocol: i32): i32 {
    let _d: i32 = domain
    let _t: i32 = type_
    let _p: i32 = protocol
    return 1
}

[host_provider(std::network::net_bind)]
micro net_bind(fd: i32, host: utf8, port: i32): i32 {
    let _fd: i32 = fd
    let _host: utf8 = host
    let _port: i32 = port
    return 0
}

[host_provider(std::network::net_listen)]
micro net_listen(fd: i32, backlog: i32): i32 {
    let _fd: i32 = fd
    let _b: i32 = backlog
    return 0
}

[host_provider(std::network::net_accept)]
micro net_accept(fd: i32): i32 {
    let _fd: i32 = fd
    return 2
}

[host_provider(std::network::net_connect)]
micro net_connect(fd: i32, host: utf8, port: i32): i32 {
    let _fd: i32 = fd
    let _host: utf8 = host
    let _port: i32 = port
    return 0
}

[host_provider(std::network::net_read)]
micro net_read(fd: i32, max_len: i32): utf8 {
    let _fd: i32 = fd
    let _max: i32 = max_len
    return ""
}

[host_provider(std::network::net_write)]
micro net_write(fd: i32, data: utf8): i32 {
    let _fd: i32 = fd
    let _data: utf8 = data
    return data.length()
}

[host_provider(std::network::net_close)]
micro net_close(fd: i32): unit {
    let _fd: i32 = fd
}

[host_provider(std::network::tls::tls_wrap_server)]
micro tls_wrap_server(stream_fd: i32, cert_path: utf8, key_path: utf8, min_version: utf8): i32 {
    let _cert: utf8 = cert_path
    let _key: utf8 = key_path
    let _min: utf8 = min_version
    return stream_fd
}

[host_provider(std::network::tls::tls_wrap_client)]
micro tls_wrap_client(stream_fd: i32, min_version: utf8): i32 {
    let _min: utf8 = min_version
    return stream_fd
}

[host_provider(std::network::tls::tls_read)]
micro tls_read(handle: i32, max_len: i32): utf8 {
    let _h: i32 = handle
    let _max: i32 = max_len
    return ""
}

[host_provider(std::network::tls::tls_write)]
micro tls_write(handle: i32, data: utf8): i32 {
    let _h: i32 = handle
    let _data: utf8 = data
    return 0
}

[host_provider(std::network::tls::tls_close)]
micro tls_close(handle: i32): unit {
    let _h: i32 = handle
}
