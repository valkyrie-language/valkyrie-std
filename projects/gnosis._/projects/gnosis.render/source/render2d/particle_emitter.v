namespace gnosis.render.render2d;

# gnosis.render.render2d.particle_emitter: 粒子与发射器
# 定义单个粒子状态、发射器配置与发射器，支持爆发式与连续式发射。

# 返回 [0, 1) 范围内的伪随机 f32。
# 该函数为 host contract：具体随机源由宿主运行时提供。
[host_contract]
micro random_f32(): f32

⍝ 单个粒子状态，记录位置、速度、颜色、生命周期与当前年龄。
structure Particle {
    ⍝ 当前世界空间位置（XY）。
    position: [f32; 2]
    ⍝ 当前速度向量（XY，单位/秒）。
    velocity: [f32; 2]
    ⍝ 当前颜色（RGBA，线性空间，0..1）。
    color: [f32; 4]
    ⍝ 总生命周期（秒），到 age >= lifetime 时消亡。
    lifetime: f32
    ⍝ 已存活时间（秒）。
    age: f32
    ⍝ 当前尺寸（世界空间单位，宽=高）。
    size: f32
}

⍝ 发射器配置，描述粒子生成参数。
structure EmitterConfig {
    ⍝ 连续发射速率（粒子/秒），emit_continuous 使用。
    rate: f32
    ⍝ 单次爆发数量，emit_burst 使用。
    count: u32
    ⍝ 发射角度散布（弧度），相对 base_angle 对称展开。
    spread: f32
    ⍝ 生命周期范围 [min, max]（秒）。
    lifetime_range: [f32; 2]
    ⍝ 初速度范围 [min, max]（单位/秒）。
    speed_range: [f32; 2]
    ⍝ 尺寸范围 [min, max]（世界空间单位）。
    size_range: [f32; 2]
    ⍝ 起始颜色（RGBA，age=0 时的颜色）。
    color_start: [f32; 4]
    ⍝ 结束颜色（RGBA，age=lifetime 时的颜色）。
    color_end: [f32; 4]
}

⍝ 粒子发射器，持有粒子池与配置，支持爆发式 / 连续式发射。
class ParticleEmitter {
    ⍝ 当前粒子池（含已死粒子，由 update 回收）。
    _particles: [Particle]
    ⍝ 发射器配置。
    _config: EmitterConfig
    ⍝ 连续发射累加器（秒），累积到 >= 1/rate 时发射一个。
    _accumulator: f32
}

imply ParticleEmitter {
    ⍝ 创建空发射器。
    micro new(config: EmitterConfig): Self {
        return ParticleEmitter {
            _particles: [],
            _config: config,
            _accumulator: 0.0,
        }
    }

    ⍝ 返回发射器配置。
    micro config(self): EmitterConfig {
        return self._config
    }

    ⍝ 返回粒子池。
    micro particles(self): [Particle] {
        return self._particles
    }

    ⍝ 返回当前存活粒子数（age < lifetime）。
    micro alive_count(self): u32 {
        let mut count: u32 = 0
        let len: usize = self._particles.length
        let mut i: usize = 0
        while i < len {
            let p: Particle = self._particles[i]
            if p.age < p.lifetime {
                count = count + 1
            }
            i = i + 1
        }
        return count
    }

    ⍝ 在 position 处以 base_angle 为中心爆发一批粒子。
    ⍝ 数量由配置的 count 决定，角度在 base_angle ± spread/2 内散布。
    micro emit_burst(mut self, position: [f32; 2], base_angle: f32): unit {
        let mut i: u32 = 0
        while i < self._config.count {
            self.spawn_one(position, base_angle)
            i = i + 1
        }
    }

    ⍝ 按 dt 推进连续发射累加器并按 rate 发射粒子。
    ⍝ position / base_angle 为本次发射的基准点与方向。
    micro emit_continuous(mut self, dt: f32, position: [f32; 2], base_angle: f32): unit {
        if self._config.rate <= 0.0 {
            return
        }
        self._accumulator = self._accumulator + dt * self._config.rate
        while self._accumulator >= 1.0 {
            self._accumulator = self._accumulator - 1.0
            self.spawn_one(position, base_angle)
        }
    }

    ⍝ 生成单个粒子并加入池。
    ⍝ 速度方向由 base_angle 加随机散布决定，速度 / 寿命 / 尺寸在配置范围内随机。
    micro spawn_one(mut self, position: [f32; 2], base_angle: f32): unit {
        let r_angle: f32 = (random_f32() - 0.5) * self._config.spread
        let angle: f32 = base_angle + r_angle
        let speed: f32 = lerp_f32(self._config.speed_range[0], self._config.speed_range[1], random_f32())
        let vx: f32 = cos(angle) * speed
        let vy: f32 = sin(angle) * speed
        let lt: f32 = lerp_f32(self._config.lifetime_range[0], self._config.lifetime_range[1], random_f32())
        let sz: f32 = lerp_f32(self._config.size_range[0], self._config.size_range[1], random_f32())
        push(self._particles, Particle {
            position: [position[0], position[1]],
            velocity: [vx, vy],
            color: self._config.color_start,
            lifetime: lt,
            age: 0.0,
            size: sz,
        })
    }

    ⍝ 推进所有粒子：位置积分、年龄累加、颜色插值，回收已死粒子。
    micro update(mut self, dt: f32): unit {
        let mut alive: [Particle] = []
        let len: usize = self._particles.length
        let mut i: usize = 0
        while i < len {
            let mut p: Particle = self._particles[i]
            p.age = p.age + dt
            if p.age < p.lifetime {
                p.position = [p.position[0] + p.velocity[0] * dt, p.position[1] + p.velocity[1] * dt]
                let t: f32 = p.age / p.lifetime
                p.color = lerp_color(self._config.color_start, self._config.color_end, t)
                push(alive, p)
            }
            i = i + 1
        }
        self._particles = alive
    }

    ⍝ 清空粒子池并重置累加器。
    micro clear(mut self): unit {
        self._particles = []
        self._accumulator = 0.0
    }
}

⍝ f32 线性插值，t 限定在 [0, 1]。
micro lerp_f32(a: f32, b: f32, t: f32): f32 {
    return a + (b - a) * t
}

⍝ RGBA 颜色逐通道线性插值，t 限定在 [0, 1]。
micro lerp_color(a: [f32; 4], b: [f32; 4], t: f32): [f32; 4] {
    return [
        a[0] + (b[0] - a[0]) * t,
        a[1] + (b[1] - a[1]) * t,
        a[2] + (b[2] - a[2]) * t,
        a[3] + (b[3] - a[3]) * t,
    ]
}
