# AtlasController — 入站适配器辅助

namespace atlas.core;

using std.text;

micro ok_body(body: utf8): AtlasResult {
    return AtlasResult::ok_json(body)
}

micro created_body(body: utf8): AtlasResult {
    return AtlasResult::created(body)
}

micro fail_body(message: utf8): AtlasResult {
    return AtlasResult::bad_request(message)
}
