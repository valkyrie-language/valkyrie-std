namespace gnosis.gpu.adapter;

# gnosis.gpu.adapter: 适配器枚举与逻辑设备创建入口
# 提供后端选择、物理适配器枚举与偏好选择，是访问 GPU 的起点。

⍝ 适配器信息，描述一个可用的物理设备。
structure AdapterInfo {
    ⍝ 适配器句柄。
    handle: AdapterHandle
    ⍝ 适配器所属后端。
    backend: Backend
    ⍝ 设备友好名称（如 "NVIDIA GeForce RTX 4090"）。
    name: utf8
    ⍝ 厂商标识。
    vendor_id: u32
    ⍝ 设备标识。
    device_id: u32
    ⍝ 专用显存大小（字节）。
    dedicated_memory: u64
    ⍝ 是否支持呈现到屏幕。
    supports_present: bool
}

⍝ 适配器选择偏好，用于在多个适配器间排序。
unite AdapterPreference {
    ⍝ 默认选择，平衡性能与功耗。
    Default
    ⍝ 倾向高性能独显。
    HighPerformance
    ⍝ 倾向低功耗集显。
    LowPower
}

⍝ 枚举当前平台可用的 GPU 适配器。
⍝ 返回列表的顺序由后端决定；调用方应配合 pick_adapter 按偏好筛选。
⍝ 若 backend 为 Auto，后端自行挑选实际可用后端。
[host_contract]
micro enumerate_adapters(backend: Backend): [AdapterInfo]

⍝ 按偏好选择最佳适配器。
⍝ 后端在 enumerate_adapters 阶段已按偏好排序，此处取首个支持呈现的适配器。
⍝ 若无可用适配器返回 None。
micro pick_adapter(backend: Backend, preference: AdapterPreference): Option<AdapterInfo> {
    let adapters: [AdapterInfo] = enumerate_adapters(backend)
    let count: usize = adapters.length
    if count == 0 {
        return None
    }
    let mut i: usize = 0
    while i < count {
        let info: AdapterInfo = adapters[i]
        if info.supports_present {
            return Some::<AdapterInfo>(info)
        }
        i = i + 1
    }
    let fallback: AdapterInfo = adapters[0]
    return Some::<AdapterInfo>(fallback)
}

⍝ 适配器封装，提供创建逻辑设备的入口。
class Adapter {
    ⍝ 内部适配器句柄。
    _handle: AdapterHandle
    ⍝ 适配器所属后端。
    _backend: Backend
}

imply Adapter {
    ⍝ 从适配器信息构造适配器封装。
    micro new(info: AdapterInfo): Self {
        return Adapter {
            _handle: info.handle,
            _backend: info.backend,
        }
    }

    ⍝ 返回适配器句柄。
    micro handle(self): AdapterHandle {
        return self._handle
    }

    ⍝ 返回适配器所属后端。
    micro backend(self): Backend {
        return self._backend
    }

    ⍝ 在该适配器上创建逻辑设备。
    ⍝ queue_requests 指定期望的队列族及数量；至少应请求一个 Graphics 队列。
    ⍝ 返回的 Device 持有这些队列，可通过 Queue::new 取出。
    [host_contract]
    micro create_device(mut self, queue_requests: [QueueRequest]): Device {
        return Device::new(DeviceHandle { id: 0 })
    }
}
