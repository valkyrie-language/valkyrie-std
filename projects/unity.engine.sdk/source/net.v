namespace unity.engine.sdk.net;

# Unity 网络能力填充

[fill("std.net.get")]
micro get(url: utf8): utf8 {
    return __unity_request_get(url)
}

# 直接绑定 Unity `UnityWebRequest.SendWebRequest`
# 参数与返回的宿主胶水由编译器自动生成，这里不手写额外桥接层

[clr("UnityEngine.Networking", "UnityEngine.Networking.UnityWebRequest", "SendWebRequest")]
micro __unity_request_get(url: utf8): utf8
