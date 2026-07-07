namespace gnosis.render.render2d;

# gnosis.render.render2d.trail_renderer: 拖尾渲染器
# 记录某实体的历史位置点，按时间衰减生成带状几何并提交到 DrawList。
# 适用于子弹拖尾、吸附掉落物尾迹等需要随实体移动的连续丝带效果。

⍝ 拖尾采样点，记录某时刻的位置与已存活时间。
structure TrailPoint {
    ⍝ 采样位置（世界空间 XY）。
    position: [f32; 2]
    ⍝ 已存活时间（秒），达到 max_lifetime 时被回收。
    age: f32
}

⍝ 拖尾渲染器，记录实体历史位置并按时间衰减生成带状几何。
class TrailRenderer {
    ⍝ 采样点列表（按记录顺序，最旧在前）。
    _points: [TrailPoint]
    ⍝ 单个采样点的最大寿命（秒）。
    _max_lifetime: f32
    ⍝ 最大采样点数量，超过则丢弃最旧点。
    _max_points: u32
    ⍝ 基准线宽（世界空间单位），按衰减系数缩放。
    _width: f32
    ⍝ 基准颜色（RGBA），alpha 按衰减系数缩放。
    _color: [f32; 4]
}

imply TrailRenderer {
    ⍝ 创建空拖尾渲染器。
    ⍝ max_lifetime 为单点寿命，max_points 为采样上限，width 为基准线宽，color 为基准颜色。
    micro new(max_lifetime: f32, max_points: u32, width: f32, color: [f32; 4]): Self {
        return TrailRenderer {
            _points: [],
            _max_lifetime: max_lifetime,
            _max_points: max_points,
            _width: width,
            _color: color,
        }
    }

    ⍝ 返回当前采样点数量。
    micro point_count(self): u32 {
        return (self._points.length as u32)
    }

    ⍝ 返回单点最大寿命。
    micro max_lifetime(self): f32 {
        return self._max_lifetime
    }

    ⍝ 记录一个新采样点（age=0）。
    ⍝ 若达到 max_points 上限，丢弃最旧的点。
    micro record(mut self, position: [f32; 2]): unit {
        push(self._points, TrailPoint {
            position: [position[0], position[1]],
            age: 0.0,
        })
        let len: usize = self._points.length
        let cap: usize = (self._max_points as usize)
        if len > cap {
            let mut trimmed: [TrailPoint] = []
            let start: usize = len - cap
            let mut i: usize = start
            while i < len {
                push(trimmed, self._points[i])
                i = i + 1
            }
            self._points = trimmed
        }
    }

    ⍝ 推进所有采样点的年龄并回收过期点。
    micro update(mut self, dt: f32): unit {
        let mut alive: [TrailPoint] = []
        let len: usize = self._points.length
        let mut i: usize = 0
        while i < len {
            let mut p: TrailPoint = self._points[i]
            p.age = p.age + dt
            if p.age < self._max_lifetime {
                push(alive, p)
            }
            i = i + 1
        }
        self._points = alive
    }

    ⍝ 将拖尾作为线段序列提交到 draw_list。
    ⍝ 相邻采样点之间提交一条线段，厚度与 alpha 随点年龄衰减。
    ⍝ 使用 Alpha 混合、World 分层，无纹理。
    micro render(self, draw_list: DrawList): unit {
        let len: usize = self._points.length
        if len < 2 {
            return
        }
        draw_list.set_state(Alpha, None)
        let mut i: usize = 0
        while i < len - 1 {
            let a: TrailPoint = self._points[i]
            let b: TrailPoint = self._points[i + 1]
            let t: f32 = a.age / self._max_lifetime
            if t < 1.0 {
                let fade: f32 = 1.0 - t
                let thickness: f32 = self._width * fade
                if thickness > 0.0 {
                    let color: [f32; 4] = [
                        self._color[0],
                        self._color[1],
                        self._color[2],
                        self._color[3] * fade,
                    ]
                    draw_list.push_line(a.position, b.position, color, thickness)
                }
            }
            i = i + 1
        }
    }

    ⍝ 清空所有采样点。
    micro clear(mut self): unit {
        self._points = []
    }
}
