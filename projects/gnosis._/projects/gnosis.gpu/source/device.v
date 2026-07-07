namespace gnosis.gpu.device;

# gnosis.gpu.device: 逻辑设备与命令队列
# Device 是 GPU 资源工厂，负责创建 / 销毁 buffer / image / shader / pipeline。
# Queue 负责提交命令缓冲区并关联 fence / semaphore 同步。

# ──────────────────────────────────────────────
# 逻辑设备
# ──────────────────────────────────────────────

⍝ 逻辑设备封装，持有 GPU 资源工厂能力。
⍝ 由 Adapter.create_device 创建；调用方通过它创建所有 GPU 资源。
class Device {
    ⍝ 内部设备句柄。
    _handle: DeviceHandle
}

imply Device {
    ⍝ 从已有设备句柄构造封装。
    ⍝ 通常由 Adapter.create_device 内部调用，调用方一般不直接使用。
    micro new(handle: DeviceHandle): Self {
        return Device {
            _handle: handle,
        }
    }

    ⍝ 返回设备句柄，供 Queue / CommandPool / Fence / Swapchain 等构造时使用。
    micro handle(self): DeviceHandle {
        return self._handle
    }

    ⍝ 创建一个 GPU 缓冲区。
    ⍝ usage 决定其在管线中的角色；size 为字节数。
    [host_contract]
    micro create_buffer(mut self, usage: BufferUsage, size: u64): BufferHandle {
        return BufferHandle { id: 0 }
    }

    ⍝ 创建一个 GPU 图像。
    ⍝ mip_levels 为 1 表示仅基础层级。
    [host_contract]
    micro create_image(mut self, usage: ImageUsage, format: Format, extent: Extent3D, mip_levels: u32): ImageHandle {
        return ImageHandle { id: 0 }
    }

    ⍝ 创建图像视图，描述如何访问图像的子资源范围。
    [host_contract]
    micro create_image_view(mut self, image: ImageHandle, format: Format, range: SubresourceRange): ImageViewHandle {
        return ImageViewHandle { id: 0 }
    }

    ⍝ 创建着色器模块。
    ⍝ code 为后端相关已编译字节码；entry_name 为入口函数名（如 "main" / "vs_main"）。
    [host_contract]
    micro create_shader_module(mut self, code: [u8], entry_name: utf8): ShaderModuleHandle {
        return ShaderModuleHandle { id: 0 }
    }

    ⍝ 创建图形管线。
    [host_contract]
    micro create_pipeline(mut self, desc: PipelineDescription): PipelineHandle {
        return PipelineHandle { id: 0 }
    }

    ⍝ 等待设备上所有队列空闲。
    ⍝ 用于资源销毁 / 窗口重建前的同步，开销较大，不应在帧循环热路径调用。
    [host_contract]
    micro wait_idle(mut self): unit {
        return
    }

    ⍝ 销毁缓冲区。
    [host_contract]
    micro destroy_buffer(mut self, buffer: BufferHandle): unit {
        return
    }

    ⍝ 销毁图像。
    [host_contract]
    micro destroy_image(mut self, image: ImageHandle): unit {
        return
    }

    ⍝ 销毁图像视图。
    [host_contract]
    micro destroy_image_view(mut self, view: ImageViewHandle): unit {
        return
    }

    ⍝ 销毁着色器模块。
    [host_contract]
    micro destroy_shader_module(mut self, module: ShaderModuleHandle): unit {
        return
    }

    ⍝ 销毁图形管线。
    [host_contract]
    micro destroy_pipeline(mut self, pipeline: PipelineHandle): unit {
        return
    }

    ⍝ 销毁逻辑设备。
    ⍝ 调用前应确保所有由该设备创建的资源已各自销毁，且队列已空闲。
    [host_contract]
    micro destroy(mut self): unit {
        return
    }
}

# ──────────────────────────────────────────────
# 命令队列
# ──────────────────────────────────────────────

⍝ 命令提交队列封装。
⍝ 设备创建时应已请求对应队列族；Queue::new 取出对应队列供提交使用。
class Queue {
    ⍝ 内部队列句柄。
    _handle: QueueHandle
    ⍝ 队列所属设备句柄。
    _device: DeviceHandle
    ⍝ 队列族类型。
    _family: QueueFamily
}

imply Queue {
    ⍝ 取出设备上指定队列族的队列。
    ⍝ 设备创建时必须已请求该队列族；至少 Graphics 队列族总是可用。
    [host_contract]
    micro new(device: DeviceHandle, family: QueueFamily): Self {
        return Queue {
            _handle: QueueHandle { id: 0 },
            _device: device,
            _family: family,
        }
    }

    ⍝ 返回队列句柄，供 Swapchain.present 使用。
    micro handle(self): QueueHandle {
        return self._handle
    }

    ⍝ 返回队列族类型。
    micro family(self): QueueFamily {
        return self._family
    }

    ⍝ 提交一批命令缓冲区到队列。
    ⍝ wait_semaphores 在命令执行前等待；signal_semaphores 在命令完成后置位；
    ⍝ signal_fence 在命令完成后置位（None 表示不需要 fence 同步）。
    [host_contract]
    micro submit(mut self, command_buffer: CommandBufferHandle, signal_fence: Option<FenceHandle>, wait_semaphores: [SemaphoreHandle], signal_semaphores: [SemaphoreHandle]): unit {
        return
    }
}
