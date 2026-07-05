# 阿里云云服务注册辅助

namespace atlas.cloud.aliyun;

using std.text;
using atlas.cloud;

struct AlibabaCloudOptions {
    access_key_id: utf8
    access_key_secret: utf8
    oss_endpoint: utf8
    oss_region: utf8
}

class AlibabaCloudBundle {
    state: AtlasCloudWireState
    blob: AlibabaBlobStorage
    sms: AlibabaSmsProvider
}

imply AlibabaCloudOptions {
    micro new(access_key_id: utf8, access_key_secret: utf8, oss_endpoint: utf8): Self {
        return Self {
            access_key_id: access_key_id,
            access_key_secret: access_key_secret,
            oss_endpoint: oss_endpoint,
            oss_region: "cn-hangzhou"
        }
    }
}

micro register_alibaba_cloud(mut state: AtlasCloudWireState, opts: AlibabaCloudOptions): AlibabaCloudBundle {
    state = state.use_blob_kind("alibaba")
    state = state.use_sms_kind("alibaba")
    return AlibabaCloudBundle {
        state: state,
        blob: AlibabaBlobStorage::new(opts.access_key_id, opts.access_key_secret, opts.oss_endpoint, opts.oss_region),
        sms: AlibabaSmsProvider::new(opts.access_key_id, opts.access_key_secret)
    }
}
