namespace std.adaptor.jvm.net;

# 网络 API

[host_provider("std.net.get")]
micro get(url: utf8): utf8 {
    return __http_get(url)
}

[host_provider("std.net.post")]
micro post(url: utf8, body: utf8): utf8 {
    return __http_post(url, body)
}

[host_provider("std.net.put")]
micro put(url: utf8, body: utf8): utf8 {
    return __http_put(url, body)
}

[host_provider("std.net.delete")]
micro delete(url: utf8): utf8 {
    return __http_delete(url)
}

[jvm("java.net.http.HttpClient", "get")]
private micro __http_get(url: utf8): utf8

[jvm("java.net.http.HttpClient", "post")]
private micro __http_post(url: utf8, body: utf8): utf8

[jvm("java.net.http.HttpClient", "put")]
private micro __http_put(url: utf8, body: utf8): utf8

[jvm("java.net.http.HttpClient", "delete")]
private micro __http_delete(url: utf8): utf8
