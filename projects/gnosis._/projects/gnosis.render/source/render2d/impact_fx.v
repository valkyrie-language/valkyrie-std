namespace gnosis.render.render2d;

# gnosis.render.render2d.impact_fx: 命中 / 死亡 / 拾取反馈预设
# 提供 gameplay 友好的预设函数，构造 ParticleRequest 交由 ParticleSystem 消费。
# gameplay 层只调用本预设库并提交 request，不直接拼装粒子细节。

# 返回 atan2(y, x)（弧度）。
# 该函数为 host contract：具体实现由宿主运行时提供。
[host_contract]
micro atan2(y: f64, x: f64): f64

⍝ ImpactFx 预设库，构造各类反馈效果的 ParticleRequest。
class ImpactFx {}

imply ImpactFx {
    ⍝ 命中反馈：小型径向火花，短寿命、中等初速。
    ⍝ 返回请求供 ParticleSystem::submit_request 消费。
    micro spawn_hit(position: [f32; 2], color: [f32; 4]): ParticleRequest {
        return ParticleRequest {
            kind: Burst,
            position: [position[0], position[1]],
            angle: 0.0,
            spread: 6.2831853,
            count: 12,
            lifetime_range: [0.15, 0.35],
            speed_range: [80.0, 160.0],
            size_range: [1.5, 3.0],
            color_start: color,
            color_end: [color[0] * 0.3, color[1] * 0.3, color[2] * 0.3, 0.0],
        }
    }

    ⍝ 死亡反馈：大型径向爆发，较长寿命，颜色向暗色衰减。
    micro spawn_death(position: [f32; 2], color: [f32; 4]): ParticleRequest {
        return ParticleRequest {
            kind: Explosion,
            position: [position[0], position[1]],
            angle: 0.0,
            spread: 6.2831853,
            count: 32,
            lifetime_range: [0.5, 1.0],
            speed_range: [60.0, 180.0],
            size_range: [2.0, 5.0],
            color_start: color,
            color_end: [color[0] * 0.15, color[1] * 0.15, color[2] * 0.15, 0.0],
        }
    }

    ⍝ 拾取吸附尾迹：从 position 朝向 toward 的定向粒子流，模拟被吸引的尾迹。
    micro spawn_pickup_magnet(position: [f32; 2], toward: [f32; 2], color: [f32; 4]): ParticleRequest {
        let dx: f32 = toward[0] - position[0]
        let dy: f32 = toward[1] - position[1]
        let angle: f32 = atan2(dy, dx)
        return ParticleRequest {
            kind: Trail,
            position: [position[0], position[1]],
            angle: angle,
            spread: 0.4,
            count: 6,
            lifetime_range: [0.2, 0.45],
            speed_range: [40.0, 100.0],
            size_range: [1.0, 2.5],
            color_start: color,
            color_end: [color[0], color[1], color[2], 0.0],
        }
    }

    ⍝ 通用爆炸：以 radius 缩放初速度的大范围径向爆发。
    micro spawn_explosion(position: [f32; 2], radius: f32, color: [f32; 4]): ParticleRequest {
        return ParticleRequest {
            kind: Explosion,
            position: [position[0], position[1]],
            angle: 0.0,
            spread: 6.2831853,
            count: 28,
            lifetime_range: [0.35, 0.8],
            speed_range: [radius * 0.6, radius * 1.6],
            size_range: [2.0, 4.5],
            color_start: color,
            color_end: [color[0] * 0.2, color[1] * 0.2, color[2] * 0.2, 0.0],
        }
    }

    ⍝ 拖尾烟尘：沿 angle 方向的小型定向粒子流，用于子弹尾迹等。
    micro spawn_trail_puff(position: [f32; 2], angle: f32, color: [f32; 4]): ParticleRequest {
        return ParticleRequest {
            kind: Trail,
            position: [position[0], position[1]],
            angle: angle,
            spread: 0.3,
            count: 5,
            lifetime_range: [0.15, 0.35],
            speed_range: [20.0, 60.0],
            size_range: [1.5, 3.0],
            color_start: color,
            color_end: [color[0], color[1], color[2], 0.0],
        }
    }
}
