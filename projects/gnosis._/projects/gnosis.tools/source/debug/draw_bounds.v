namespace gnosis.tools.debug;

using gnosis.render.render2d;

# gnosis.tools.debug.draw_bounds: 调试边界绘制
# 提供开关控制的 AABB / 圆形线框绘制，通过 push_line 提交到 DrawList 的 Debug 层。
# 调用方负责传入 Debug 层的 DrawList 并预先 set_state；未启用时所有 draw 方法为零开销空操作。

⍝ 调试边界绘制器，通过 enabled 开关控制是否实际提交线框。
class DrawBounds {
    ⍝ 是否启用调试绘制。关闭时所有 draw 方法立即返回。
    _enabled: bool
}

imply DrawBounds {
    ⍝ 构造一个默认关闭的调试边界绘制器。
    micro new(): Self {
        return DrawBounds {
            _enabled: false,
        }
    }

    ⍝ 返回是否启用调试绘制。
    micro enabled(self): bool {
        return self._enabled
    }

    ⍝ 设置调试绘制开关。
    micro set_enabled(mut self, value: bool): unit {
        self._enabled = value
    }

    ⍝ 向 list 提交一个 AABB 线框（四条边）。
    ⍝ min 为左下角坐标，max 为右上角坐标，color 为线框颜色，thickness 为线宽。
    ⍝ list 应为 Debug 层的 DrawList；未启用时为空操作。
    micro draw_aabb(mut self, list: DrawList, min: [f32; 2], max: [f32; 2], color: [f32; 4], thickness: f32): unit {
        if !self._enabled {
            return
        }
        let tl: [f32; 2] = [min[0], max[1]]
        let tr: [f32; 2] = [max[0], max[1]]
        let bl: [f32; 2] = [min[0], min[1]]
        let br: [f32; 2] = [max[0], min[1]]
        list.push_line(tl, tr, color, thickness)
        list.push_line(tr, br, color, thickness)
        list.push_line(br, bl, color, thickness)
        list.push_line(bl, tl, color, thickness)
    }

    ⍝ 向 list 提交一个圆形线框（segments 段折线近似）。
    ⍝ center 为圆心，radius 为半径，color 为线框颜色，thickness 为线宽。
    ⍝ list 应为 Debug 层的 DrawList；未启用时为空操作。
    micro draw_circle(mut self, list: DrawList, center: [f32; 2], radius: f32, color: [f32; 4], thickness: f32, segments: u32): unit {
        if !self._enabled {
            return
        }
        if segments == 0 {
            return
        }
        let mut i: u32 = 0
        while i < segments {
            let a0: f32 = 2.0 * 3.14159265 * (i as f32) / (segments as f32)
            let a1: f32 = 2.0 * 3.14159265 * ((i + 1) as f32) / (segments as f32)
            let p0: [f32; 2] = [center[0] + cos(a0) * radius, center[1] + sin(a0) * radius]
            let p1: [f32; 2] = [center[0] + cos(a1) * radius, center[1] + sin(a1) * radius]
            list.push_line(p0, p1, color, thickness)
            i = i + 1
        }
    }
}
