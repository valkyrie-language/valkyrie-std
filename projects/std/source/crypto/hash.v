namespace std.crypto;

# std.crypto: hash 模块：哈希与随机数

micro sha256(data: utf8): utf8 {
    return ""
}

micro md5(data: utf8): utf8 {
    return ""
}

micro hmac_sha256(key: utf8, data: utf8): utf8 {
    return ""
}

[host_contract]
micro random_bytes(length: i32): utf8

[host_contract]
micro random_uuid(): utf8
