namespace gnosis.render.render2d;

# gnosis.render.render2d.draw_list: 顶点 / 图元 / DrawCommand / DrawList

⍝ 2D 顶点数据，包含位置、颜色与纹理坐标。
structure Vertex {
    ⍝ 顶点位置（世界或屏幕空间，XY 分量）。
    position: [f32; 2]
    ⍝ 顶点颜色（RGBA，线性空间，0..1）。
    color: [f32; 4]
    ⍝ 纹理坐标（UV）。
    uv: [f32; 2]
}

⍝ 图元种类，记录 DrawCommand 对应的原始几何类型。
unite PrimitiveKind {
    ⍝ 四边形（两个三角形）。
    Quad
    ⍝ 线段（展开为四边形以支持厚度）。
    Line
    ⍝ 圆形（三角形扇）。
    Circle
    ⍝ 多边形（扇形三角化）。
    Polygon
}

⍝ 绘制命令，描述一段连续的顶点 / 索引区间及其渲染状态。
structure DrawCommand {
    ⍝ 图元种类。
    kind: PrimitiveKind
    ⍝ 顶点缓冲区起始偏移。
    vertex_offset: u32
    ⍝ 顶点数量。
    vertex_count: u32
    ⍝ 索引缓冲区起始偏移。
    index_offset: u32
    ⍝ 索引数量。
    index_count: u32
    ⍝ 混合模式。
    blend_mode: BlendMode
    ⍝ 渲染分层。
    layer: Layer
    ⍝ 绑定的纹理句柄。
    texture: Option<ImageHandle>
}

⍝ 绘制列表，按帧累积顶点 / 索引 / 命令，是渲染管线的入口。
class DrawList {
    ⍝ 该列表所属的渲染分层。
    _layer: Layer
    ⍝ 当前混合模式（push 时写入每条命令）。
    _blend_mode: BlendMode
    ⍝ 当前纹理句柄（push 时写入每条命令）。
    _texture: Option<ImageHandle>
    ⍝ 顶点数组。
    _vertices: [Vertex]
    ⍝ 索引数组。
    _indices: [u32]
    ⍝ 命令数组。
    _commands: [DrawCommand]
    ⍝ 已追加的顶点数（用于计算偏移）。
    _vertex_count: u32
    ⍝ 已追加的索引数（用于计算偏移）。
    _index_count: u32
}

imply DrawList {
    ⍝ 创建属于指定分层的空绘制列表。
    micro new(layer: Layer): Self {
        return DrawList {
            _layer: layer,
            _blend_mode: Opaque,
            _texture: None,
            _vertices: [],
            _indices: [],
            _commands: [],
            _vertex_count: 0,
            _index_count: 0,
        }
    }

    ⍝ 返回该列表所属的渲染分层。
    micro layer(self): Layer {
        return self._layer
    }

    ⍝ 设置后续 push 操作使用的混合模式与纹理。
    micro set_state(mut self, blend_mode: BlendMode, texture: Option<ImageHandle>): unit {
        self._blend_mode = blend_mode
        self._texture = texture
    }

    ⍝ 返回顶点数组（供 Batcher / Pass 读取）。
    micro vertices(self): [Vertex] {
        return self._vertices
    }

    ⍝ 返回索引数组（供 Batcher / Pass 读取）。
    micro indices(self): [u32] {
        return self._indices
    }

    ⍝ 返回命令数组（供 Batcher / Pass 读取）。
    micro commands(self): [DrawCommand] {
        return self._commands
    }

    ⍝ 返回顶点数量。
    micro vertex_count(self): u32 {
        return self._vertex_count
    }

    ⍝ 返回索引数量。
    micro index_count(self): u32 {
        return self._index_count
    }

    ⍝ 追加一个四边形（两个三角形）。
    ⍝ position 为左上角坐标，size 为宽高，uv_rect 为 (u_min, v_min, u_max, v_max)。
    micro push_quad(mut self, position: [f32; 2], size: [f32; 2], color: [f32; 4], uv_rect: [f32; 4]): unit {
        let vertex_offset: u32 = self._vertex_count
        let index_offset: u32 = self._index_count

        push(self._vertices, Vertex { position: [position[0], position[1]], color: color, uv: [uv_rect[0], uv_rect[1]] })
        push(self._vertices, Vertex { position: [position[0] + size[0], position[1]], color: color, uv: [uv_rect[2], uv_rect[1]] })
        push(self._vertices, Vertex { position: [position[0] + size[0], position[1] + size[1]], color: color, uv: [uv_rect[2], uv_rect[3]] })
        push(self._vertices, Vertex { position: [position[0], position[1] + size[1]], color: color, uv: [uv_rect[0], uv_rect[3]] })
        self._vertex_count = self._vertex_count + 4

        push(self._indices, vertex_offset + 0)
        push(self._indices, vertex_offset + 1)
        push(self._indices, vertex_offset + 2)
        push(self._indices, vertex_offset + 0)
        push(self._indices, vertex_offset + 2)
        push(self._indices, vertex_offset + 3)
        self._index_count = self._index_count + 6

        push(self._commands, DrawCommand {
            kind: Quad,
            vertex_offset: vertex_offset,
            vertex_count: 4,
            index_offset: index_offset,
            index_count: 6,
            blend_mode: self._blend_mode,
            layer: self._layer,
            texture: self._texture,
        })
    }

    ⍝ 追加一条线段（展开为四边形以支持厚度）。
    micro push_line(mut self, start: [f32; 2], end: [f32; 2], color: [f32; 4], thickness: f32): unit {
        let dx: f32 = end[0] - start[0]
        let dy: f32 = end[1] - start[1]
        let len: f32 = sqrt(dx * dx + dy * dy)
        if len == 0.0 {
            return
        }
        let half: f32 = thickness * 0.5
        let nx: f32 = (-dy / len) * half
        let ny: f32 = (dx / len) * half

        let vertex_offset: u32 = self._vertex_count
        let index_offset: u32 = self._index_count

        push(self._vertices, Vertex { position: [start[0] - nx, start[1] - ny], color: color, uv: [0.0, 0.0] })
        push(self._vertices, Vertex { position: [start[0] + nx, start[1] + ny], color: color, uv: [1.0, 0.0] })
        push(self._vertices, Vertex { position: [end[0] + nx, end[1] + ny], color: color, uv: [1.0, 1.0] })
        push(self._vertices, Vertex { position: [end[0] - nx, end[1] - ny], color: color, uv: [0.0, 1.0] })
        self._vertex_count = self._vertex_count + 4

        push(self._indices, vertex_offset + 0)
        push(self._indices, vertex_offset + 1)
        push(self._indices, vertex_offset + 2)
        push(self._indices, vertex_offset + 0)
        push(self._indices, vertex_offset + 2)
        push(self._indices, vertex_offset + 3)
        self._index_count = self._index_count + 6

        push(self._commands, DrawCommand {
            kind: Line,
            vertex_offset: vertex_offset,
            vertex_count: 4,
            index_offset: index_offset,
            index_count: 6,
            blend_mode: self._blend_mode,
            layer: self._layer,
            texture: self._texture,
        })
    }

    ⍝ 追加一个填充圆（三角形扇）。
    ⍝ segments 控制圆弧分段数，值越大越平滑。
    micro push_circle(mut self, center: [f32; 2], radius: f32, color: [f32; 4], segments: u32): unit {
        if segments == 0 {
            return
        }

        let vertex_offset: u32 = self._vertex_count
        let index_offset: u32 = self._index_count

        push(self._vertices, Vertex { position: [center[0], center[1]], color: color, uv: [0.5, 0.5] })
        self._vertex_count = self._vertex_count + 1

        let mut i: u32 = 0
        while i < segments {
            let angle: f32 = 2.0 * 3.14159265 * (i as f32) / (segments as f32)
            let dx: f32 = cos(angle) * radius
            let dy: f32 = sin(angle) * radius
            push(self._vertices, Vertex { position: [center[0] + dx, center[1] + dy], color: color, uv: [(cos(angle) + 1.0) * 0.5, (sin(angle) + 1.0) * 0.5] })
            self._vertex_count = self._vertex_count + 1
            i = i + 1
        }

        let mut j: u32 = 0
        while j < segments {
            let next: u32 = (j + 1) % segments
            push(self._indices, vertex_offset + 0)
            push(self._indices, vertex_offset + 1 + j)
            push(self._indices, vertex_offset + 1 + next)
            self._index_count = self._index_count + 3
            j = j + 1
        }

        push(self._commands, DrawCommand {
            kind: Circle,
            vertex_offset: vertex_offset,
            vertex_count: segments + 1,
            index_offset: index_offset,
            index_count: segments * 3,
            blend_mode: self._blend_mode,
            layer: self._layer,
            texture: self._texture,
        })
    }

    ⍝ 追加一个凸多边形（扇形三角化）。
    ⍝ points 为外轮廓顶点列表，至少 3 个点。
    micro push_polygon(mut self, points: [[f32; 2]], color: [f32; 4]): unit {
        let point_count: usize = points.length
        if point_count < 3 {
            return
        }

        let vertex_offset: u32 = self._vertex_count
        let index_offset: u32 = self._index_count

        let mut i: usize = 0
        while i < point_count {
            let point: [f32; 2] = points[i]
            push(self._vertices, Vertex { position: [point[0], point[1]], color: color, uv: [0.0, 0.0] })
            self._vertex_count = self._vertex_count + 1
            i = i + 1
        }

        let mut j: usize = 1
        while j < point_count - 1 {
            push(self._indices, vertex_offset + 0)
            push(self._indices, vertex_offset + (j as u32))
            push(self._indices, vertex_offset + ((j + 1) as u32))
            self._index_count = self._index_count + 3
            j = j + 1
        }

        let tri_count: u32 = ((point_count - 2) as u32)
        push(self._commands, DrawCommand {
            kind: Polygon,
            vertex_offset: vertex_offset,
            vertex_count: (point_count as u32),
            index_offset: index_offset,
            index_count: tri_count * 3,
            blend_mode: self._blend_mode,
            layer: self._layer,
            texture: self._texture,
        })
    }

    ⍝ 清空所有顶点 / 索引 / 命令，保留分层与当前状态。
    micro clear(mut self): unit {
        self._vertices = []
        self._indices = []
        self._commands = []
        self._vertex_count = 0
        self._index_count = 0
    }
}
