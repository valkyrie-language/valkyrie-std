namespace gnosis.gpu.sync;

# gnosis.gpu.sync: 同步原语
# 提供 fence（CPU-GPU 同步）、semaphore（GPU-GPU 同步）与 pipeline barrier 类型。
# fence / semaphore 句柄定义在 types.v，本模块封装其面向调用方的生命周期与操作。

# ──────────────────────────────────────────────
# Pipeline 阶段与屏障
# ──────────────────────────────────────────────

⍝ 管线阶段，用于 pipeline_barrier 的源 / 目标阶段声明。
unite PipelineStage {
    ⍝ 管线顶部，等价于任何命令之前。
    TopOfPipe
    ⍝ 顶点输入阶段。
    VertexInput
    ⍝ 顶点着色器阶段。
    VertexShader
    ⍝ 早期片段测试（深度 / 模板）。
    EarlyFragmentTests
    ⍝ 片段着色器阶段。
    FragmentShader
    ⍝ 晚期片段测试（深度 / 模板）。
    LateFragmentTests
    ⍝ 颜色附件输出阶段。
    ColorAttachmentOutput
    ⍝ 传输阶段（copy）。
    Transfer
    ⍝ 所有图形阶段。
    AllGraphics
    ⍝ 所有命令阶段。
    AllCommands
    ⍝ 管线底部，等价于任何命令之后。
    BottomOfPipe
}

⍝ 图像内存屏障，描述图像布局 / 队列所有权转换。
structure ImageMemoryBarrier {
    ⍝ 受影响的图像视图。
    view: ImageViewHandle
    ⍝ 转换前的布局。
    old_layout: ImageLayout
    ⍝ 转换后的布局。
    new_layout: ImageLayout
    ⍝ 受影响的子资源范围。
    range: SubresourceRange
}

⍝ 缓冲区内存屏障，描述缓冲区可见性 / 队列所有权转换。
structure BufferMemoryBarrier {
    ⍝ 受影响的缓冲区。
    buffer: BufferHandle
    ⍝ 受影响区间起始偏移（字节）。
    offset: u64
    ⍝ 受影响区间长度（字节），0 表示到缓冲区末尾。
    size: u64
}

# ──────────────────────────────────────────────
# Fence: CPU-GPU 同步
# ──────────────────────────────────────────────

⍝ Fence 封装，用于 CPU 等待 GPU 完成一批命令。
⍝ 由 GPU 在队列提交时置位，由 CPU 通过 wait / is_signaled 查询并重置。
class Fence {
    ⍝ 内部 fence 句柄。
    _handle: FenceHandle
    ⍝ 关联的逻辑设备句柄。
    _device: DeviceHandle
}

imply Fence {
    ⍝ 创建一个 fence。
    ⍝ signaled 为 true 时初始处于已置位状态，便于首帧直接使用。
    [host_contract]
    micro new(device: DeviceHandle, signaled: bool): Self {
        return Fence {
            _handle: FenceHandle { id: 0 },
            _device: device,
        }
    }

    ⍝ 返回 fence 句柄。
    micro handle(self): FenceHandle {
        return self._handle
    }

    ⍝ 将 fence 重置为未置位状态，以便再次提交时复用。
    ⍝ 调用前应确保 GPU 已发出对应的置位信号，否则行为未定义。
    [host_contract]
    micro reset(mut self): unit {
        return
    }

    ⍝ 阻塞 CPU 直到 fence 被置位或超时。
    ⍝ timeout_ns 为纳秒级超时；返回 true 表示已置位，false 表示超时。
    [host_contract]
    micro wait(mut self, timeout_ns: u64): bool {
        return true
    }

    ⍝ 查询 fence 是否已被置位，非阻塞。
    ⍝ 返回 true 表示 GPU 已完成对应提交。
    [host_contract]
    micro is_signaled(self): bool {
        return true
    }

    ⍝ 销毁 fence 并释放后端资源。
    [host_contract]
    micro destroy(mut self): unit {
        return
    }
}

# ──────────────────────────────────────────────
# Semaphore: GPU-GPU 同步
# ──────────────────────────────────────────────

⍝ Semaphore 封装，用于 GPU 内部时序同步。
⍝ 典型用途：swapchain acquire 信号一个 semaphore，present 等待该 semaphore。
class Semaphore {
    ⍝ 内部 semaphore 句柄。
    _handle: SemaphoreHandle
    ⍝ 关联的逻辑设备句柄。
    _device: DeviceHandle
}

imply Semaphore {
    ⍝ 创建一个未置位的 semaphore。
    [host_contract]
    micro new(device: DeviceHandle): Self {
        return Semaphore {
            _handle: SemaphoreHandle { id: 0 },
            _device: device,
        }
    }

    ⍝ 返回 semaphore 句柄。
    micro handle(self): SemaphoreHandle {
        return self._handle
    }

    ⍝ 销毁 semaphore 并释放后端资源。
    [host_contract]
    micro destroy(mut self): unit {
        return
    }
}
