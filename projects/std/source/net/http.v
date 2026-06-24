namespace std.net;

# std.net: http - HTTP 客户端
# 稳定 contract 优先使用 utf8，由宿主 provider 负责下沉到底层绑定

[host_contract]
micro get(url: utf8): utf8

[host_contract]
micro post(url: utf8, body: utf8): utf8

[host_contract]
micro put(url: utf8, body: utf8): utf8

[host_contract]
micro delete(url: utf8): utf8

micro get_json(url: utf8): Option<Value> {
    let text: utf8 = get(url)
    if text == "" {
        return None
    }
    let val: Value = parse(text)
    return Some(val)
}

micro post_json(url: utf8, body: Value): utf8 {
    let text: utf8 = stringify(body)
    return post(url, text)
}
