# Azure 云服务测试

using atlas.cloud.azure;

[test]
micro `azure blob url`() {
    let storage: AzureBlobStorage = AzureBlobStorage::new("myaccount", "key")
    let url: utf8 = storage.build_object_url("container", "file.txt")
    if url.contains("myaccount") == false {
        panic("account missing")
    }
    if url.contains("container/file.txt") == false {
        panic("path missing")
    }
}

[test]
micro `azure email endpoint extract`() {
    let conn: utf8 = "endpoint=https://acs.example.com;accesskey=abc"
    let endpoint: utf8 = extract_connection_value(conn, "endpoint")
    if endpoint.contains("acs.example.com") == false {
        panic("endpoint extract failed")
    }
}
