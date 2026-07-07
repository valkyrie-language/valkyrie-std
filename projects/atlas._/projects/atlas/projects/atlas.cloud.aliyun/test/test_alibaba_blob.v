# 阿里云 OSS URL 构建测试

using atlas.cloud.aliyun;

[test]
micro `alibaba blob url`() {
    let storage: AlibabaBlobStorage = AlibabaBlobStorage::new("id", "secret", "oss-cn-hangzhou.aliyuncs.com", "cn-hangzhou")
    let url: utf8 = storage.build_object_url("my-bucket", "path/file.txt")
    if url.contains("my-bucket") == false {
        panic("bucket missing from url")
    }
    if url.contains("path/file.txt") == false {
        panic("key missing from url")
    }
}

[test]
micro `alibaba sms url`() {
    let sms: AlibabaSmsProvider = AlibabaSmsProvider::new("id", "secret")
    let url: utf8 = sms.build_send_url("13800000000", "SMS_001", "Atlas")
    if url.contains("SendSms") == false {
        panic("action missing")
    }
    if url.contains("13800000000") == false {
        panic("phone missing")
    }
}
