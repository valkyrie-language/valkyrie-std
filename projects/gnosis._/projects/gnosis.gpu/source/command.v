namespace gnosis.gpu.command;

# gnosis.gpu.command: 命令缓冲区与录制
# 提供 CommandPool（分配 / 重置命令缓冲区）与 CommandBuffer（录制 GPU 命令）。
# 录制接口覆盖 render pass / bind / draw / copy / barrier，足以支撑 2D world pass + HUD pass。

# ──────────────────────────────────────────────
# 命令池
# ──────────────────────────────────────────────

⍝ 命令池封装，用于分配与回收命令缓冲区。
⍝ 通常一个队列族对应一个命令池；同池分配的命令缓冲区可一起 reset。
class CommandPool {
    ⍝ 内部命令池句柄。
    _handle: CommandPoolHandle
    ⍝ 关联设备句柄。
    _device: DeviceHandle
    ⍝ 队列族类型。
    _family: QueueFamily
}

imply CommandPool {
    ⍝ 创建命令池。
    ⍝ family 决定该池分配的命令缓冲区可提交到哪类队列。
    [host_contract]
    micro new(device: DeviceHandle, family: QueueFamily): Self {
        return CommandPool {
            _handle: CommandPoolHandle { id: 0 },
            _device: device,
            _family: family,
        }
    }

    ⍝ 返回命令池句柄。
    micro handle(self): CommandPoolHandle {
        return self._handle
    }

    ⍝ 返回队列族类型。
    micro family(self): QueueFamily {
        return self._family
    }

    ⍝ 分配一个命令缓冲区。
    ⍝ 返回的命令缓冲区初始处于未录制状态，需先调用 begin。
    [host_contract]
    micro allocate(mut self): CommandBuffer {
        return CommandBuffer::new(CommandBufferHandle { id: 0 })
    }

    ⍝ 重置命令池，回收所有由其分配的命令缓冲区。
    ⍝ 调用前必须确保 GPU 不再使用这些命令缓冲区（通过 fence 同步）。
    [host_contract]
    micro reset(mut self): unit {
        return
    }

    ⍝ 销毁命令池及其分配的所有命令缓冲区。
    [host_contract]
    micro destroy(mut self): unit {
        return
    }
}

# ──────────────────────────────────────────────
# 命令缓冲区
# ──────────────────────────────────────────────

⍝ 命令缓冲区封装，用于录制 GPU 命令。
⍝ 典型流程：begin → (begin_render_pass → bind_* → draw* → end_render_pass)* → end → submit。
class CommandBuffer {
    ⍝ 内部命令缓冲区句柄。
    _handle: CommandBufferHandle
}

imply CommandBuffer {
    ⍝ 从已有句柄构造命令缓冲区封装。
    ⍝ 通常由 CommandPool.allocate 内部调用，调用方一般不直接使用。
    micro new(handle: CommandBufferHandle): Self {
        return CommandBuffer {
            _handle: handle,
        }
    }

    ⍝ 返回命令缓冲区句柄，供 Queue.submit 使用。
    micro handle(self): CommandBufferHandle {
        return self._handle
    }

    ⍝ 开始录制命令。
    ⍝ 每次录制必须配对 end，且 begin 前命令缓冲区应处于可用状态。
    [host_contract]
    micro begin(mut self): unit {
        return
    }

    ⍝ 结束录制命令，之后可提交到队列。
    [host_contract]
    micro end(mut self): unit {
        return
    }

    ⍝ 开始一个渲染通道。
    ⍝ color_attachments 至少一个；depth_attachment 为 None 表示该通道无深度附件。
    ⍝ 同一帧内可多次配对调用 begin_render_pass / end_render_pass 以录制多个 pass（如 world pass + HUD pass）。
    [host_contract]
    micro begin_render_pass(mut self, color_attachments: [ColorAttachment], depth_attachment: Option<DepthAttachment>): unit {
        return
    }

    ⍝ 结束当前渲染通道。
    [host_contract]
    micro end_render_pass(mut self): unit {
        return
    }

    ⍝ 绑定图形管线。
    [host_contract]
    micro bind_pipeline(mut self, pipeline: PipelineHandle): unit {
        return
    }

    ⍝ 绑定顶点缓冲区到指定槽位。
    [host_contract]
    micro bind_vertex_buffer(mut self, slot: u32, buffer: BufferHandle, offset: u64): unit {
        return
    }

    ⍝ 绑定索引缓冲区。
    [host_contract]
    micro bind_index_buffer(mut self, buffer: BufferHandle, offset: u64, index_type: IndexType): unit {
        return
    }

    ⍝ 设置视口。
    [host_contract]
    micro set_viewport(mut self, viewport: Viewport): unit {
        return
    }

    ⍝ 设置裁剪矩形。
    [host_contract]
    micro set_scissor(mut self, scissor: Scissor): unit {
        return
    }

    ⍝ 写入 push constants，用于传递每对象变换矩阵等小量数据。
    ⍝ stage 指定可见着色器阶段；offset 为 push constants 区内起始偏移（字节）。
    [host_contract]
    micro push_constants(mut self, stage: ShaderStage, offset: u32, data: [u8]): unit {
        return
    }

    ⍝ 非索引绘制。
    [host_contract]
    micro draw(mut self, vertex_count: u32, instance_count: u32, first_vertex: u32, first_instance: u32): unit {
        return
    }

    ⍝ 索引绘制。
    ⍝ vertex_offset 为索引到顶点索引的偏移。
    [host_contract]
    micro draw_indexed(mut self, index_count: u32, instance_count: u32, first_index: u32, vertex_offset: i32, first_instance: u32): unit {
        return
    }

    ⍝ 缓冲区间拷贝，常用于 staging 上传到 GPU 本地缓冲区。
    [host_contract]
    micro copy_buffer(mut self, src: BufferHandle, dst: BufferHandle, src_offset: u64, dst_offset: u64, size: u64): unit {
        return
    }

    ⍝ 插入管线屏障，用于资源布局转换 / 可见性同步 / 队列所有权转移。
    ⍝ src_stage / dst_stage 描述屏障前后执行的管线阶段；
    ⍝ image_barriers / buffer_barriers 描述受影响的资源转换。
    [host_contract]
    micro pipeline_barrier(mut self, src_stage: PipelineStage, dst_stage: PipelineStage, image_barriers: [ImageMemoryBarrier], buffer_barriers: [BufferMemoryBarrier]): unit {
        return
    }
}
