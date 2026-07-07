# 平台部署入口 — Atlas HTTP 原生桥接（无 VOA 依赖）

namespace atlas.adaptor;

using std.text;
using atlas.http;
using atlas.core;

micro process_request(mut host: AtlasHost, request: AtlasRequest): AtlasResponse {
    return host.process(request)
}

micro process_http(mut host: AtlasHost, raw: utf8): AtlasResponse {
    let request: AtlasRequest = parse_http_request(raw)
    return host.process(request)
}

micro to_response_body(response: AtlasResponse): utf8 {
    return response.body
}
