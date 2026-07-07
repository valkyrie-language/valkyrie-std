# Atlas.Cloud Wire 注册测试

using atlas.cloud;
using atlas.wire;

[test]
micro `cloud wire defaults to null blob`() {
    let state: AtlasCloudWireState = AtlasCloudWireState::new()
    let blob: NullBlobStorage = require_blob(state)
    let result: BlobResult = blob.put_object("b", "k", "data", "text/plain")
    if result.success {
        panic("null blob should fail")
    }
}

[test]
micro `cloud wire link container`() {
    let mut container: AtlasWireContainer = AtlasWireContainer::new()
    let state: AtlasCloudWireState = AtlasCloudWireState::new()
    container = link_cloud_to_container(container, state)
    if container.contains("AtlasCloudWireState") == false {
        panic("cloud wire key missing")
    }
}

[test]
micro `cloud wire sms null`() {
    let state: AtlasCloudWireState = AtlasCloudWireState::new()
    let sms: NullSmsProvider = require_sms(state)
    let result: SmsResult = sms.send("13800000000", "T001", "sign")
    if result.success {
        panic("null sms should fail")
    }
}
