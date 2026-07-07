# AtlasResult — 统一 Action 执行结果（对标 C# AtlasResult）

namespace atlas.core;

using std.text;
using atlas.http;

class AtlasResult {
    status_code: i32
    body: utf8
    content_type: utf8
}

imply AtlasResult {
    micro ok(): Self {
        return Self {
            status_code: 200,
            body: "",
            content_type: ""
        }
    }

    micro ok_json(body: utf8): Self {
        return Self {
            status_code: 200,
            body: body,
            content_type: "application/json; charset=utf-8"
        }
    }

    micro created(body: utf8): Self {
        return Self {
            status_code: 201,
            body: body,
            content_type: "application/json"
        }
    }

    micro no_content(): Self {
        return Self {
            status_code: 204,
            body: "",
            content_type: ""
        }
    }

    micro bad_request(message: utf8): Self {
        return error_body(400, message)
    }

    micro unauthorized(): Self {
        return error_body(401, "unauthorized")
    }

    micro forbidden(): Self {
        return error_body(403, "forbidden")
    }

    micro not_found(): Self {
        return error_body(404, "not found")
    }

    micro internal_error(): Self {
        return error_body(500, "internal error")
    }

    micro text(status_code: i32, text: utf8): Self {
        return Self {
            status_code: status_code,
            body: text,
            content_type: "text/plain"
        }
    }

    micro apply_to(self, mut context: AtlasRouteContext): unit {
        context.response.status_code = self.status_code
        context.response.body = self.body
        context.response.content_type = self.content_type
    }
}

micro error_body(status_code: i32, message: utf8): AtlasResult {
    return AtlasResult {
        status_code: status_code,
        body: "{error:".concat(message).concat("}"),
        content_type: "application/json"
    }
}
