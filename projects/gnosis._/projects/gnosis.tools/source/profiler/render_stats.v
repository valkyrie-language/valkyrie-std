namespace gnosis.tools.profiler;

# gnosis.tools.profiler.render_stats: 渲染提交统计
# 在渲染路径各埋点累加 draw calls / 顶点数 / 三角形数 / 粒子数 / 可见对象数，
# 每帧开始时 reset，帧结束时供 FrameStats.to_snapshot 读取。

⍝ 渲染提交统计器，累加每帧渲染路径的关键计数。
class RenderStats {
    ⍝ 本帧提交的绘制调用次数。
    _draw_calls: u32
    ⍝ 本帧提交的顶点总数。
    _vertices: u32
    ⍝ 本帧提交的三角形总数。
    _triangles: u32
    ⍝ 本帧活跃的粒子总数。
    _particle_count: u32
    ⍝ 本帧可见对象数量。
    _visible_objects: u32
}

imply RenderStats {
    ⍝ 构造一个所有计数为零的渲染统计器。
    micro new(): Self {
        return RenderStats {
            _draw_calls: 0,
            _vertices: 0,
            _triangles: 0,
            _particle_count: 0,
            _visible_objects: 0,
        }
    }

    ⍝ 记录一次绘制调用，累加 draw calls、顶点数与三角形数。
    micro record_draw_call(mut self, vertices: u32, triangles: u32): unit {
        self._draw_calls = self._draw_calls + 1
        self._vertices = self._vertices + vertices
        self._triangles = self._triangles + triangles
    }

    ⍝ 记录活跃粒子数（累加，通常在遍历粒子系统后调用）。
    micro record_particle(mut self, count: u32): unit {
        self._particle_count = self._particle_count + count
    }

    ⍝ 记录可见对象数（累加，通常在可见性剔除后调用）。
    micro record_visible(mut self, count: u32): unit {
        self._visible_objects = self._visible_objects + count
    }

    ⍝ 返回本帧绘制调用次数。
    micro draw_calls(self): u32 {
        return self._draw_calls
    }

    ⍝ 返回本帧顶点总数。
    micro vertices(self): u32 {
        return self._vertices
    }

    ⍝ 返回本帧三角形总数。
    micro triangles(self): u32 {
        return self._triangles
    }

    ⍝ 返回本帧活跃粒子总数。
    micro particle_count(self): u32 {
        return self._particle_count
    }

    ⍝ 返回本帧可见对象数量。
    micro visible_objects(self): u32 {
        return self._visible_objects
    }

    ⍝ 重置所有计数器到零，每帧开始时调用。
    micro reset(mut self): unit {
        self._draw_calls = 0
        self._vertices = 0
        self._triangles = 0
        self._particle_count = 0
        self._visible_objects = 0
    }
}
