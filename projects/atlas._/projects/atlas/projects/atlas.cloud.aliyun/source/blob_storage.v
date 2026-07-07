# 阿里云 OSS 实现（对标 C# Atlas.Cloud.Alibaba.AlibabaBlobStorage）

namespace atlas.cloud.aliyun;

using std.text;
using std.net;
using atlas.cloud;

class AlibabaBlobStorage {
    access_key_id: utf8
    access_key_secret: utf8
    endpoint: utf8
    region: utf8
}

imply AlibabaBlobStorage {
    micro new(access_key_id: utf8, access_key_secret: utf8, endpoint: utf8, region: utf8): Self {
        return Self {
            access_key_id: access_key_id,
            access_key_secret: access_key_secret,
            endpoint: endpoint,
            region: region
        }
    }

    micro build_object_url(self, bucket: utf8, key: utf8): utf8 {
        let mut url: utf8 = "https://"
        url = url.concat(bucket)
        url = url.concat(".")
        url = url.concat(self.endpoint)
        url = url.concat("/")
        url = url.concat(key)
        return url
    }

    micro put_object(self, bucket: utf8, key: utf8, data: utf8, content_type: utf8): BlobResult {
        let url: utf8 = self.build_object_url(bucket, key)
        let _ct: utf8 = content_type
        let response: utf8 = put(url, data)
        if response.is_empty() {
            return BlobResult::ok("")
        }
        return BlobResult::fail(response)
    }

    micro get_object(self, bucket: utf8, key: utf8): utf8 {
        let url: utf8 = self.build_object_url(bucket, key)
        return get(url)
    }

    micro delete_object(self, bucket: utf8, key: utf8): BlobResult {
        let url: utf8 = self.build_object_url(bucket, key)
        let response: utf8 = delete(url)
        if response.is_empty() {
            return BlobResult::ok("")
        }
        return BlobResult::fail(response)
    }

    micro generate_presigned_url(self, bucket: utf8, key: utf8, expiry_seconds: i32, method: utf8): utf8 {
        let _e: i32 = expiry_seconds
        let _m: utf8 = method
        return self.build_object_url(bucket, key)
    }
}
