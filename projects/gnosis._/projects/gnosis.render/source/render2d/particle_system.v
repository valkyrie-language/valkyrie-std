namespace gnosis.render.render2d;

# gnosis.render.render2d.particle_system: 粒子系统
# 管理多个发射器，按帧推进粒子并将存活粒子作为 quad 提交到 DrawList。
# 对外提供 request 队列与 spawn_explosion / spawn_trail 便捷接口，
# gameplay 层只需提交 ParticleRequest 或调用便捷接口，不直接拼装特效细节。

⍝ 粒子请求种类，标记请求的意图，便于日志与后续扩展。
unite ParticleRequestKind {
    ⍝ 爆炸：径向全向爆发。
    Explosion
    ⍝ 拖尾：沿方向的小型定向粒子流。
    Trail
    ⍝ 通用爆发：自定义参数。
    Burst
}

⍝ 粒子请求，由 ImpactFx 预设或上层 gameplay 构造后提交给 ParticleSystem。
structure ParticleRequest {
    ⍝ 请求种类（意图标记）。
    kind: ParticleRequestKind
    ⍝ 发射世界空间位置。
    position: [f32; 2]
    ⍝ 基准方向角度（弧度）。
    angle: f32
    ⍝ 角度散布（弧度），Explosion 通常为 2π。
    spread: f32
    ⍝ 爆发粒子数量。
    count: u32
    ⍝ 生命周期范围 [min, max]（秒）。
    lifetime_range: [f32; 2]
    ⍝ 初速度范围 [min, max]（单位/秒）。
    speed_range: [f32; 2]
    ⍝ 尺寸范围 [min, max]（世界空间单位）。
    size_range: [f32; 2]
    ⍝ 起始颜色（RGBA）。
    color_start: [f32; 4]
    ⍝ 结束颜色（RGBA）。
    color_end: [f32; 4]
}

⍝ 粒子系统，管理发射器列表与待处理请求队列。
class ParticleSystem {
    ⍝ 活跃发射器列表。
    _emitters: [ParticleEmitter]
    ⍝ 待处理请求队列，update 时取出并实例化为发射器。
    _requests: [ParticleRequest]
}

imply ParticleSystem {
    ⍝ 创建空粒子系统。
    micro new(): Self {
        return ParticleSystem {
            _emitters: [],
            _requests: [],
        }
    }

    ⍝ 追加一个粒子请求到队列，将在下次 update 时实例化。
    micro submit_request(mut self, request: ParticleRequest): unit {
        push(self._requests, request)
    }

    ⍝ 便捷接口：在 position 处生成径向爆炸。
    ⍝ radius 影响粒子初速度，color 为起始颜色，结束颜色衰减为暗色。
    micro spawn_explosion(mut self, position: [f32; 2], radius: f32, color: [f32; 4]): unit {
        let req: ParticleRequest = ParticleRequest {
            kind: Explosion,
            position: [position[0], position[1]],
            angle: 0.0,
            spread: 6.2831853,
            count: 24,
            lifetime_range: [0.3, 0.7],
            speed_range: [radius * 0.5, radius * 1.5],
            size_range: [2.0, 4.0],
            color_start: color,
            color_end: [color[0] * 0.2, color[1] * 0.2, color[2] * 0.2, 0.0],
        }
        self.submit_request(req)
    }

    ⍝ 便捷接口：在 position 处沿 angle 方向生成小型拖尾粒子流。
    micro spawn_trail(mut self, position: [f32; 2], angle: f32, color: [f32; 4]): unit {
        let req: ParticleRequest = ParticleRequest {
            kind: Trail,
            position: [position[0], position[1]],
            angle: angle,
            spread: 0.3,
            count: 4,
            lifetime_range: [0.15, 0.35],
            speed_range: [20.0, 60.0],
            size_range: [1.5, 3.0],
            color_start: color,
            color_end: [color[0], color[1], color[2], 0.0],
        }
        self.submit_request(req)
    }

    ⍝ 推进一帧：取出待处理请求实例化为发射器，随后更新所有发射器并回收空发射器。
    micro update(mut self, dt: f32): unit {
        let requests: [ParticleRequest] = self._requests
        self._requests = []
        let rlen: usize = requests.length
        let mut ri: usize = 0
        while ri < rlen {
            let req: ParticleRequest = requests[ri]
            let config: EmitterConfig = emitter_config_from_request(req)
            let mut emitter: ParticleEmitter = ParticleEmitter::new(config)
            emitter.emit_burst(req.position, req.angle)
            push(self._emitters, emitter)
            ri = ri + 1
        }

        let mut updated: [ParticleEmitter] = []
        let elen: usize = self._emitters.length
        let mut ei: usize = 0
        while ei < elen {
            let mut emitter: ParticleEmitter = self._emitters[ei]
            emitter.update(dt)
            if emitter.alive_count() > 0 {
                push(updated, emitter)
            }
            ei = ei + 1
        }
        self._emitters = updated
    }

    ⍝ 将所有存活粒子作为 quad 提交到 draw_list。
    ⍝ 使用 Additive 混合、World 分层，无纹理。
    micro render(self, draw_list: DrawList): unit {
        draw_list.set_state(Additive, None)
        let elen: usize = self._emitters.length
        let mut ei: usize = 0
        while ei < elen {
            let emitter: ParticleEmitter = self._emitters[ei]
            let particles: [Particle] = emitter.particles()
            let plen: usize = particles.length
            let mut pi: usize = 0
            while pi < plen {
                let p: Particle = particles[pi]
                let half: f32 = p.size * 0.5
                draw_list.push_quad(
                    [p.position[0] - half, p.position[1] - half],
                    [p.size, p.size],
                    p.color,
                    [0.0, 0.0, 1.0, 1.0]
                )
                pi = pi + 1
            }
            ei = ei + 1
        }
    }

    ⍝ 返回活跃发射器数量。
    micro emitter_count(self): u32 {
        return (self._emitters.length as u32)
    }

    ⍝ 返回待处理请求数量。
    micro pending_request_count(self): u32 {
        return (self._requests.length as u32)
    }

    ⍝ 清空所有发射器与请求。
    micro clear(mut self): unit {
        self._emitters = []
        self._requests = []
    }
}

⍝ 由 ParticleRequest 构造 EmitterConfig，rate 置 0（请求驱动为单次爆发）。
micro emitter_config_from_request(req: ParticleRequest): EmitterConfig {
    return EmitterConfig {
        rate: 0.0,
        count: req.count,
        spread: req.spread,
        lifetime_range: req.lifetime_range,
        speed_range: req.speed_range,
        size_range: req.size_range,
        color_start: req.color_start,
        color_end: req.color_end,
    }
}
