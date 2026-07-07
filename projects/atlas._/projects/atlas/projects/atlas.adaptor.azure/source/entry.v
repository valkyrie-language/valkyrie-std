# Azure 部署入口 — 原始 HTTP / 函数事件 → AtlasHost

namespace atlas.adaptor.azure;

using atlas.adaptor;
using atlas.core;
using atlas.http;

micro handle_http(mut host: AtlasHost, raw: utf8): AtlasResponse {
    return process_http(host, raw)
}

micro handle_request(mut host: AtlasHost, request: AtlasRequest): AtlasResponse {
    return process_request(host, request)
}
