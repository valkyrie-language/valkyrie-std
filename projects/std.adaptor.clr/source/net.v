namespace std.adaptor.clr.net;

# 网络 API

[clr("System.Net.Http.HttpClient", "GetStringAsync")]
micro http_get_string_async(url: utf16): i32

[clr("System.Net.Http.HttpClient", "PostAsync")]
micro http_post_async(url: utf16, content: i32): i32
