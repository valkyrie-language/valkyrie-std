# AtlasResult smoke tests

using atlas.core;
using atlas.http;

[test]
micro `ok sets status 200`() {
    let result: AtlasResult = AtlasResult::ok()
    if result.status_code != 200 {
        panic("ok should be 200")
    }
}

[test]
micro `ok_json sets content type`() {
    let result: AtlasResult = AtlasResult::ok_json("n-1")
    if result.status_code != 200 {
        panic("ok_json status")
    }
    if result.content_type.starts_with("application/json") == false {
        panic("ok_json content-type")
    }
}

[test]
micro `created is 201`() {
    let result: AtlasResult = AtlasResult::created("id-1")
    if result.status_code != 201 {
        panic("created status")
    }
}

[test]
micro `no_content is 204`() {
    let result: AtlasResult = AtlasResult::no_content()
    if result.status_code != 204 {
        panic("no_content status")
    }
}

[test]
micro `bad_request wraps error`() {
    let result: AtlasResult = AtlasResult::bad_request("invalid")
    if result.status_code != 400 {
        panic("bad_request status")
    }
    if result.body.contains("invalid") == false {
        panic("bad_request body")
    }
}

[test]
micro `apply_to writes response`() {
    let result: AtlasResult = AtlasResult::ok_json("ok-true")
    let request_http: AtlasRequest = AtlasRequest::new("GET", "/health")
    let mut context: AtlasRouteContext = AtlasRouteContext::from_request(request_http)
    result.apply_to(context)
    if context.response.status_code != 200 {
        panic("apply_to status")
    }
}
