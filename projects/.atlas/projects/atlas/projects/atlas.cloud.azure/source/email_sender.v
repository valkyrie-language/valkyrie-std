# Azure Communication Services 邮件（对标 C# AzureEmailSender）

namespace atlas.cloud.azure;

using std.text;
using std.net;
using atlas.cloud;

class AzureEmailSender {
    connection_string: utf8
    from_address: utf8
    endpoint: utf8
}

imply AzureEmailSender {
    micro new(connection_string: utf8, from_address: utf8): Self {
        return Self {
            connection_string: connection_string,
            from_address: from_address,
            endpoint: extract_connection_value(connection_string, "endpoint")
        }
    }

    micro send(self, to: utf8, subject: utf8, body: utf8): unit {
        let mut url: utf8 = self.endpoint
        url = url.concat("/emails:send?api-version=2023-03-31")
        let mut payload: utf8 = "{\"senderAddress\":\""
        payload = payload.concat(self.from_address)
        payload = payload.concat("\",\"content\":{\"subject\":\"")
        payload = payload.concat(subject)
        payload = payload.concat("\",\"plainText\":\"")
        payload = payload.concat(body)
        payload = payload.concat("\"},\"recipients\":{\"to\":[{\"address\":\"")
        payload = payload.concat(to)
        payload = payload.concat("\"}]}}")
        let _response: utf8 = post(url, payload)
    }
}

micro extract_connection_value(conn_str: utf8, key: utf8): utf8 {
    let mut i: i32 = 0
    while i < conn_str.length() {
        if conn_str.slice(i, key.length()).equals(key) {
            let start: i32 = i + key.length() + 1
            let mut end: i32 = start
            while end < conn_str.length() {
                let ch: utf8 = conn_str.slice(end, 1)
                if ch.equals(";") {
                    return conn_str.slice(start, end - start)
                }
                end = end + 1
            }
            return conn_str.slice(start, conn_str.length() - start)
        }
        i = i + 1
    }
    return "https://communication.azure.com"
}
