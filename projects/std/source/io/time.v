namespace std.io;

# std.io: time - 时间与计时
# 统一时间 contract，由 provider 决定具体宿主来源

[host_contract]
micro now(): i64

[host_contract]
micro monotonic(): i64

[host_contract]
micro sleep(ms: i32): unit

micro elapsed_since(start: i64): i64 {
    return monotonic() - start
}

