# 腾讯云短信实现（对标 C# TencentSmsProvider）

namespace atlas.cloud.tencent;

using std.text;
using std.net;
using atlas.cloud;

class TencentSmsProvider {
    secret_id: utf8
    secret_key: utf8
    app_id: utf8
    endpoint: utf8
}

imply TencentSmsProvider {
    micro new(secret_id: utf8, secret_key: utf8, app_id: utf8): Self {
        return Self {
            secret_id: secret_id,
            secret_key: secret_key,
            app_id: app_id,
            endpoint: "sms.tencentcloudapi.com"
        }
    }

    micro build_send_url(self): utf8 {
        let mut url: utf8 = "https://"
        url = url.concat(self.endpoint)
        return url
    }

    micro send(self, phone: utf8, template_code: utf8, sign_name: utf8): SmsResult {
        let url: utf8 = self.build_send_url()
        let mut payload: utf8 = "{\"PhoneNumberSet\":[\"+86"
        payload = payload.concat(phone)
        payload = payload.concat("\"],\"SmsSdkAppId\":\"")
        payload = payload.concat(self.app_id)
        payload = payload.concat("\",\"TemplateId\":\"")
        payload = payload.concat(template_code)
        payload = payload.concat("\"")
        if sign_name.is_empty() == false {
            payload = payload.concat(",\"SignName\":\"")
            payload = payload.concat(sign_name)
            payload = payload.concat("\"")
        }
        payload = payload.concat("}")
        let response: utf8 = post(url, payload)
        if response.contains("Ok") || response.contains("ok") {
            return SmsResult::ok("")
        }
        if response.is_empty() {
            return SmsResult::fail("empty sms response")
        }
        return SmsResult::fail(response)
    }
}
