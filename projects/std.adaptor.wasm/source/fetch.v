# std.web_sdk: Fetch API
# [js_builtin] 直接映射 JS 内置 fetch API，无依赖
# fetch 有副作用（网络 IO），不标注 pure
# 字符串 contract 统一优先使用 utf8，由底层绑定承担宿主桥接

[host_provider(std::net::get)]
micro get(url: utf8): utf8 {
    let host_url: utf16 = utf8_to_utf16(url)
    let handle: i32 = http_fetch(host_url)
    let response: utf16 = response_text(handle)
    return utf16_to_utf8(response)
}

[host_provider(std::net::post)]
micro post(url: utf8, body: utf8): utf8 {
    let host_url: utf16 = utf8_to_utf16(url)
    let handle: i32 = http_fetch(host_url)
    let response: utf16 = response_text(handle)
    return utf16_to_utf8(response)
}

[host_provider(std::net::put)]
micro put(url: utf8, body: utf8): utf8 {
    let host_url: utf16 = utf8_to_utf16(url)
    let handle: i32 = http_fetch(host_url)
    let response: utf16 = response_text(handle)
    return utf16_to_utf8(response)
}

[host_provider(std::net::delete)]
micro delete(url: utf8): utf8 {
    let host_url: utf16 = utf8_to_utf16(url)
    let handle: i32 = http_fetch(host_url)
    let response: utf16 = response_text(handle)
    return utf16_to_utf8(response)
}

#region 请求

[js_builtin("fetch")]
micro http_fetch(url: utf16): i32

[js_builtin("Request")]
micro http_request(url: utf16, options: i32): i32

#endregion

#region 响应

[js_builtin("Response.json")]
micro response_json(handle: i32): i32

[js_builtin("Response.text")]
micro response_text(handle: i32): utf16

[js_builtin("Response.ok")]
micro response_ok(handle: i32): i32

[js_builtin("Response.status")]
micro response_status(handle: i32): i32

[js_builtin("Response.headers")]
micro response_headers(handle: i32): i32

#endregion

#region Headers

[js_builtin("Headers")]
micro headers_new(): i32

[js_builtin("Headers.append")]
micro headers_append(handle: i32, name: utf16, value: utf16): unit

[js_builtin("Headers.get")]
micro headers_get(handle: i32, name: utf16): utf16

#endregion
