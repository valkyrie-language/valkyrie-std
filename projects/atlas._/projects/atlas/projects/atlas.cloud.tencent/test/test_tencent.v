# 腾讯云 COS URL 构建测试

using atlas.cloud.tencent;

[test]
micro `tencent blob url`() {
    let storage: TencentBlobStorage = TencentBlobStorage::new("sid", "skey", "ap-guangzhou")
    let url: utf8 = storage.build_object_url("my-bucket", "data.json")
    if url.contains("my-bucket.cos.ap-guangzhou.myqcloud.com") == false {
        panic("cos host missing")
    }
    if url.contains("data.json") == false {
        panic("key missing")
    }
}

[test]
micro `tencent sms endpoint`() {
    let sms: TencentSmsProvider = TencentSmsProvider::new("sid", "skey", "1400000000")
    let url: utf8 = sms.build_send_url()
    if url.contains("sms.tencentcloudapi.com") == false {
        panic("sms endpoint missing")
    }
}
