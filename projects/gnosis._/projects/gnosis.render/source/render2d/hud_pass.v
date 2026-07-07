namespace gnosis.render.render2d;

# gnosis.render.render2d.hud_pass: UI 层提交

⍝ UI 层渲染 pass，提取 DrawList 中 Layer::UI 的命令并录制到命令缓冲区。
⍝ UI 层使用屏幕空间正交投影，调用方应传入 identity_view() 作为视图矩阵。
class HudPass {
    ⍝ 图形管线句柄。
    _pipeline: PipelineHandle
    ⍝ 该 pass 负责的分层。
    _layer: Layer
}

imply HudPass {
    ⍝ 创建 UI 层 pass。
    ⍝ pipeline 应配置为 TriangleList 拓扑、支持目标颜色格式与 Alpha 混合。
    micro new(pipeline: PipelineHandle): Self {
        return HudPass {
            _pipeline: pipeline,
            _layer: UI,
        }
    }

    ⍝ 返回该 pass 使用的管线句柄。
    micro pipeline(self): PipelineHandle {
        return self._pipeline
    }

    ⍝ 返回该 pass 负责的分层。
    micro layer(self): Layer {
        return self._layer
    }

    ⍝ 将 DrawList 中 UI 层的命令录制到命令缓冲区。
    ⍝ 调用前命令缓冲区应已 begin 并 begin_render_pass。
    ⍝ vertex_buffer / index_buffer 应已上传 DrawList 的顶点 / 索引数据。
    ⍝ view 为视图矩阵，UI 层通常传入 identity_view()。
    micro submit(mut self, cmd: CommandBuffer, list: DrawList, view: ViewMatrix, vertex_buffer: BufferHandle, vertex_offset: u64, index_buffer: BufferHandle, index_offset: u64, screen_extent: Extent2D): unit {
        cmd.set_viewport(Viewport {
            x: 0.0,
            y: 0.0,
            width: (screen_extent.width as f32),
            height: (screen_extent.height as f32),
            min_depth: 0.0,
            max_depth: 1.0,
        })
        cmd.set_scissor(Scissor {
            x: 0,
            y: 0,
            width: screen_extent.width,
            height: screen_extent.height,
        })
        cmd.bind_pipeline(self._pipeline)

        let view_bytes: [u8] = view_matrix_to_bytes(view)
        cmd.push_constants(VertexFragment, 0, view_bytes)

        cmd.bind_vertex_buffer(0, vertex_buffer, vertex_offset)
        cmd.bind_index_buffer(index_buffer, index_offset, Uint32)

        let target: u32 = layer_order(self._layer)
        let commands: [DrawCommand] = list.commands()
        let count: usize = commands.length

        let mut i: usize = 0
        while i < count {
            let command: DrawCommand = commands[i]
            if layer_order(command.layer) == target {
                cmd.draw_indexed(command.index_count, 1, command.index_offset, (command.vertex_offset as i32), 0)
            }
            i = i + 1
        }
    }
}
