# HTTP 字节编解码（宿主壳）

namespace atlas.http;

using std.text;

micro parse_http_request(raw: utf8): AtlasRequest {
    if raw.is_empty() {
        return AtlasRequest::new("GET", "/")
    }

    let header_end: i32 = raw.index_of("\r\n\r\n")
    let mut head: utf8 = raw
    let mut body: utf8 = ""
    if header_end >= 0 {
        head = raw.slice(0, header_end)
        let body_start: i32 = header_end + 4
        let body_len: i32 = raw.length() - body_start
        if body_len > 0 {
            body = raw.slice(body_start, body_len)
        }
    } else {
        let alt_end: i32 = raw.index_of("\n\n")
        if alt_end >= 0 {
            head = raw.slice(0, alt_end)
            let body_start: i32 = alt_end + 2
            let body_len: i32 = raw.length() - body_start
            if body_len > 0 {
                body = raw.slice(body_start, body_len)
            }
        }
    }

    let lines: [utf8] = head.split("\n")
    if lines.length == 0 {
        return AtlasRequest::new("GET", "/")
    }

    let request_line: utf8 = strip_cr(lines[0])
    let parts: [utf8] = request_line.split(" ")
    let mut method: utf8 = "GET"
    let mut path: utf8 = "/"
    if parts.length > 0 {
        method = parts[0]
    }
    if parts.length > 1 {
        path = parts[1]
    }

    let path_query: PathQuery = split_path_query(path)
    let mut request: AtlasRequest = AtlasRequest::new(method, path_query.path)
    request.query = path_query.query
    request.body = body

    let mut i: i32 = 1
    while i < lines.length {
        let line: utf8 = strip_cr(lines[i])
        if line.is_empty() == false {
            let colon: i32 = line.index_of(":")
            if colon > 0 {
                let key: utf8 = line.slice(0, colon)
                let value_start: i32 = colon + 1
                let value_len: i32 = line.length() - value_start
                let mut value: utf8 = ""
                if value_len > 0 {
                    value = trim_leading_space(line.slice(value_start, value_len))
                }
                request.set_header(key, value)
            }
        }
        i = i + 1
    }
    return request
}

micro format_http_response(response: AtlasResponse): utf8 {
    let mut out: utf8 = "HTTP/1.1 "
    out = out.concat(i32_to_decimal(response.status_code))
    out = out.concat(" ")
    out = out.concat(status_reason(response.status_code))
    out = out.concat("\r\n")

    let mut i: i32 = 0
    while i < response.headers.length {
        out = out.concat(response.headers[i].key)
        out = out.concat(": ")
        out = out.concat(response.headers[i].value)
        out = out.concat("\r\n")
        i = i + 1
    }

    if response.content_type.is_empty() == false {
        out = out.concat("Content-Type: ")
        out = out.concat(response.content_type)
        out = out.concat("\r\n")
    }

    out = out.concat("Content-Length: ")
    out = out.concat(i32_to_decimal(response.body.byte_length()))
    out = out.concat("\r\n\r\n")
    out = out.concat(response.body)
    return out
}

class PathQuery {
    path: utf8
    query: [AtlasHeaderPair]
}

micro split_path_query(raw_path: utf8): PathQuery {
    let q: i32 = raw_path.index_of("?")
    if q < 0 {
        return PathQuery { path: raw_path, query: [] }
    }
    let path: utf8 = raw_path.slice(0, q)
    let query_start: i32 = q + 1
    let query_len: i32 = raw_path.length() - query_start
    let mut pairs: [AtlasHeaderPair] = []
    if query_len > 0 {
        let query_text: utf8 = raw_path.slice(query_start, query_len)
        let items: [utf8] = query_text.split("&")
        let mut i: i32 = 0
        while i < items.length {
            let item: utf8 = items[i]
            let eq: i32 = item.index_of("=")
            if eq < 0 {
                push(pairs, AtlasHeaderPair { key: item, value: "" })
            } else {
                let key: utf8 = item.slice(0, eq)
                let value_start: i32 = eq + 1
                let value_len: i32 = item.length() - value_start
                let mut value: utf8 = ""
                if value_len > 0 {
                    value = item.slice(value_start, value_len)
                }
                push(pairs, AtlasHeaderPair { key: key, value: value })
            }
            i = i + 1
        }
    }
    return PathQuery { path: path, query: pairs }
}

micro strip_cr(text: utf8): utf8 {
    if text.ends_with("\r") {
        let n: i32 = text.length() - 1
        if n <= 0 {
            return ""
        }
        return text.slice(0, n)
    }
    return text
}

micro trim_leading_space(text: utf8): utf8 {
    if text.starts_with(" ") {
        let n: i32 = text.length() - 1
        if n <= 0 {
            return ""
        }
        return text.slice(1, n)
    }
    return text
}

micro status_reason(code: i32): utf8 {
    if code == 101 {
        return "Switching Protocols"
    }
    if code == 200 {
        return "OK"
    }
    if code == 201 {
        return "Created"
    }
    if code == 204 {
        return "No Content"
    }
    if code == 400 {
        return "Bad Request"
    }
    if code == 404 {
        return "Not Found"
    }
    if code == 500 {
        return "Internal Server Error"
    }
    return "Unknown"
}

micro i32_to_decimal(value: i32): utf8 {
    if value == 0 {
        return "0"
    }
    if value < 0 {
        return "0"
    }
    let mut n: i32 = value
    let mut digits: [utf8] = []
    while n > 0 {
        let d: i32 = n % 10
        push(digits, decimal_digit(d))
        n = n / 10
    }
    let mut out: utf8 = ""
    let mut i: i32 = digits.length - 1
    while i >= 0 {
        out = out.concat(digits[i])
        i = i - 1
    }
    return out
}

micro decimal_digit(d: i32): utf8 {
    if d == 0 { return "0" }
    if d == 1 { return "1" }
    if d == 2 { return "2" }
    if d == 3 { return "3" }
    if d == 4 { return "4" }
    if d == 5 { return "5" }
    if d == 6 { return "6" }
    if d == 7 { return "7" }
    if d == 8 { return "8" }
    return "9"
}
