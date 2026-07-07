namespace gnosis.render.render2d;

# gnosis.render.render2d.postfx_requests: 后处理请求与队列

⍝ 后处理效果种类。
unite PostFxKind {
    ⍝ 受击闪烁，全屏短时高亮。
    HitFlash
    ⍝ 加法叠加，将指定颜色加法混合到全屏。
    Additive
    ⍝ 辉光，对亮度阈值以上的区域做模糊扩散。
    Bloom
}

⍝ 后处理请求，描述一次后处理效果的参数。
structure PostFxRequest {
    ⍝ 效果种类。
    kind: PostFxKind
    ⍝ 强度（0..1），控制效果混合比例。
    intensity: f32
    ⍝ 持续时间（秒），0 表示单帧瞬发。
    duration: f32
    ⍝ 效果颜色（RGBA），HitFlash / Additive 使用，Bloom 可忽略。
    color: [f32; 4]
}

⍝ 后处理请求队列，按帧累积请求并在帧末取出供后处理 pass 消费。
class PostFxRequestQueue {
    ⍝ 待消费的请求列表。
    _requests: [PostFxRequest]
}

imply PostFxRequestQueue {
    ⍝ 创建空队列。
    micro new(): Self {
        return PostFxRequestQueue {
            _requests: [],
        }
    }

    ⍝ 追加一个后处理请求。
    micro push(mut self, request: PostFxRequest): unit {
        push(self._requests, request)
    }

    ⍝ 追加一个 HitFlash 请求。
    micro push_hit_flash(mut self, intensity: f32, duration: f32, color: [f32; 4]): unit {
        push(self._requests, PostFxRequest {
            kind: HitFlash,
            intensity: intensity,
            duration: duration,
            color: color,
        })
    }

    ⍝ 追加一个 Additive 请求。
    micro push_additive(mut self, intensity: f32, color: [f32; 4]): unit {
        push(self._requests, PostFxRequest {
            kind: Additive,
            intensity: intensity,
            duration: 0.0,
            color: color,
        })
    }

    ⍝ 追加一个 Bloom 请求。
    micro push_bloom(mut self, intensity: f32, duration: f32): unit {
        push(self._requests, PostFxRequest {
            kind: Bloom,
            intensity: intensity,
            duration: duration,
            color: [0.0, 0.0, 0.0, 0.0],
        })
    }

    ⍝ 取出所有请求并清空队列。
    micro drain(mut self): [PostFxRequest] {
        let result: [PostFxRequest] = self._requests
        self._requests = []
        return result
    }

    ⍝ 返回队列是否为空。
    micro is_empty(self): bool {
        return self._requests.length == 0
    }

    ⍝ 清空队列。
    micro clear(mut self): unit {
        self._requests = []
    }
}
