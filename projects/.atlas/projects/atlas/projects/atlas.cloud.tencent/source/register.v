# 腾讯云云服务注册辅助

namespace atlas.cloud.tencent;

using std.text;
using atlas.cloud;

struct TencentCloudOptions {
    secret_id: utf8
    secret_key: utf8
    sms_app_id: utf8
    region: utf8
}

class TencentCloudBundle {
    state: AtlasCloudWireState
    blob: TencentBlobStorage
    sms: TencentSmsProvider
}

imply TencentCloudOptions {
    micro new(secret_id: utf8, secret_key: utf8, sms_app_id: utf8, region: utf8): Self {
        return Self {
            secret_id: secret_id,
            secret_key: secret_key,
            sms_app_id: sms_app_id,
            region: region
        }
    }
}

micro register_tencent_cloud(mut state: AtlasCloudWireState, opts: TencentCloudOptions): TencentCloudBundle {
    state = state.use_blob_kind("tencent")
    state = state.use_sms_kind("tencent")
    return TencentCloudBundle {
        state: state,
        blob: TencentBlobStorage::new(opts.secret_id, opts.secret_key, opts.region),
        sms: TencentSmsProvider::new(opts.secret_id, opts.secret_key, opts.sms_app_id)
    }
}
