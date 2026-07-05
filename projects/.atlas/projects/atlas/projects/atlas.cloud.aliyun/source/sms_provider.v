# 阿里云短信实现（对标 C# Atlas.Cloud.Alibaba.AlibabaSmsProvider）

namespace atlas.cloud.aliyun;

using std.text;
using std.net;
using atlas.cloud;

class AlibabaSmsProvider {
    access_key_id: utf8
    access_key_secret: utf8
    endpoint: utf8
}

imply AlibabaSmsProvider {
    micro new(access_key_id: utf8, access_key_secret: utf8): Self {
        return Self {
            access_key_id: access_key_id,
            access_key_secret: access_key_secret,
            endpoint: "dysmsapi.aliyuncs.com"
        }
    }

    micro build_send_url(self, phone: utf8, template_code: utf8, sign_name: utf8): utf8 {
        let mut url: utf8 = "https://"
        url = url.concat(self.endpoint)
        url = url.concat("/?Action=SendSms&PhoneNumbers=")
        url = url.concat(phone)
        url = url.concat("&TemplateCode=")
        url = url.concat(template_code)
        if sign_name.is_empty() == false {
            url = url.concat("&SignName=")
            url = url.concat(sign_name)
        }
        return url
    }

    micro send(self, phone: utf8, template_code: utf8, sign_name: utf8): SmsResult {
        let url: utf8 = self.build_send_url(phone, template_code, sign_name)
        let response: utf8 = get(url)
        if response.contains("OK") {
            return SmsResult::ok("")
        }
        if response.is_empty() {
            return SmsResult::fail("empty sms response")
        }
        return SmsResult::fail(response)
    }
}
