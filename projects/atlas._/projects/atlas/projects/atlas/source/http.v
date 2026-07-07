# Atlas HTTP 请求 / 响应模型

namespace atlas.http;

using std.text;

class AtlasHeaderPair {
    key: utf8
    value: utf8
}

class AtlasRequest {
    method: utf8
    path: utf8
    headers: [AtlasHeaderPair]
    query: [AtlasHeaderPair]
    params: [AtlasHeaderPair]
    body: utf8
    connection_id: utf8
    is_hijacked: bool
    connection_fd: i32
}

class AtlasResponse {
    status_code: i32
    headers: [AtlasHeaderPair]
    body: utf8
    content_type: utf8
}

class AtlasRouteContext {
    request: AtlasRequest
    response: AtlasResponse
    short_circuit: bool
    is_hijacked: bool
    connection_id: utf8
    ws_handler_id: utf8
    connection_fd: i32
}

imply AtlasRequest {
    micro new(method: utf8, path: utf8): Self {
        return Self {
            method: method,
            path: path,
            headers: [],
            query: [],
            params: [],
            body: "",
            connection_id: "",
            is_hijacked: false,
            connection_fd: -1
        }
    }

    micro get_header(self, key: utf8): utf8 {
        return find_pair(self.headers, key)
    }

    micro set_header(mut self, key: utf8, value: utf8): unit {
        push(self.headers, AtlasHeaderPair { key: key, value: value })
    }

    micro get_param(self, key: utf8): utf8 {
        return find_pair(self.params, key)
    }

    micro get_query(self, key: utf8): utf8 {
        return find_pair(self.query, key)
    }
}

imply AtlasResponse {
    micro empty(status_code: i32): Self {
        return Self {
            status_code: status_code,
            headers: [],
            body: "",
            content_type: ""
        }
    }

    micro with_body(status_code: i32, body: utf8, content_type: utf8): Self {
        return Self {
            status_code: status_code,
            headers: [],
            body: body,
            content_type: content_type
        }
    }

    micro set_header(mut self, key: utf8, value: utf8): unit {
        push(self.headers, AtlasHeaderPair { key: key, value: value })
    }
}

imply AtlasRouteContext {
    micro from_request(request: AtlasRequest): Self {
        return Self {
            request: request,
            response: AtlasResponse::empty(200),
            short_circuit: false,
            is_hijacked: false,
            connection_id: "",
            ws_handler_id: "",
            connection_fd: request.connection_fd
        }
    }
}

micro find_pair(pairs: [AtlasHeaderPair], key: utf8): utf8 {
    let mut i: i32 = 0
    while i < pairs.length {
        if pairs[i].key.equals(key) {
            return pairs[i].value
        }
        i = i + 1
    }
    return ""
}

micro status_ok(): i32 { return 200 }
micro status_created(): i32 { return 201 }
micro status_no_content(): i32 { return 204 }
micro status_bad_request(): i32 { return 400 }
micro status_unauthorized(): i32 { return 401 }
micro status_forbidden(): i32 { return 403 }
micro status_not_found(): i32 { return 404 }
micro status_internal_error(): i32 { return 500 }
