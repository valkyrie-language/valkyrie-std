namespace std.net;

# std.net: http client contracts
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
        return option_none::<Value>()
    }
    let val: Value = parse(text)
    return Some(val)
}

micro post_json(url: utf8, body: Value): utf8 {
    let text: utf8 = stringify(body)
    return post(url, text)
}
