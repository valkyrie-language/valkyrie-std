namespace gnosis.tools.debug;

using gnosis.render.render2d;

# gnosis.tools.debug.particle_view: 粒子系统视图
# 非侵入式检视 ParticleSystem 的活跃粒子数与发射器数，并可视化粒子整体边界。
# 通过向临时 DrawList 探测 system.render() 的输出来统计粒子数与位置，
# 不修改上游 ParticleSystem 的公开接口。

⍝ 粒子系统检视结果，记录活跃粒子数与发射器数。
structure ParticleSummary {
    ⍝ 活跃粒子总数（所有发射器存活粒子之和）。
    active_particles: u32
    ⍝ 活跃发射器数量。
    emitter_count: u32
}

⍝ 粒子系统视图，非侵入式检视 ParticleSystem 并绘制粒子边界。
class ParticleView {}

imply ParticleView {
    ⍝ 构造一个空的粒子视图。
    micro new(): Self {
        return ParticleView {}
    }

    ⍝ 检视 system 的活跃粒子数与发射器数。
    ⍝ 通过向临时 DrawList 渲染并计数命令来获取活跃粒子数，
    ⍝ 避免修改上游 ParticleSystem 的公开接口。
    micro inspect(mut self, system: ParticleSystem): ParticleSummary {
        let probe: DrawList = DrawList::new(Debug)
        system.render(probe)
        let commands: [DrawCommand] = probe.commands()
        let active: u32 = (commands.length as u32)
        return ParticleSummary {
            active_particles: active,
            emitter_count: system.emitter_count(),
        }
    }

    ⍝ 向 list 绘制所有活跃粒子的整体边界 AABB。
    ⍝ 通过临时 DrawList 探测粒子顶点位置，计算整体 min/max 并提交四条边线。
    ⍝ list 应为 Debug 层的 DrawList。无活跃粒子时不绘制。
    micro draw_bounds(mut self, list: DrawList, system: ParticleSystem, color: [f32; 4], thickness: f32): unit {
        let probe: DrawList = DrawList::new(Debug)
        system.render(probe)
        let vertices: [Vertex] = probe.vertices()
        let count: usize = vertices.length
        if count == 0 {
            return
        }

        let first: Vertex = vertices[0]
        let mut min_x: f32 = first.position[0]
        let mut max_x: f32 = first.position[0]
        let mut min_y: f32 = first.position[1]
        let mut max_y: f32 = first.position[1]

        let mut i: usize = 1
        while i < count {
            let v: Vertex = vertices[i]
            let px: f32 = v.position[0]
            let py: f32 = v.position[1]
            if px < min_x {
                min_x = px
            }
            if px > max_x {
                max_x = px
            }
            if py < min_y {
                min_y = py
            }
            if py > max_y {
                max_y = py
            }
            i = i + 1
        }

        let tl: [f32; 2] = [min_x, max_y]
        let tr: [f32; 2] = [max_x, max_y]
        let bl: [f32; 2] = [min_x, min_y]
        let br: [f32; 2] = [max_x, min_y]
        list.push_line(tl, tr, color, thickness)
        list.push_line(tr, br, color, thickness)
        list.push_line(br, bl, color, thickness)
        list.push_line(bl, tl, color, thickness)
    }
}
