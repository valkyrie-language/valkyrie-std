namespace gnosis.gpu.present;

# gnosis.gpu.present: 表面与交换链
# 提供 surface 创建（绑定平台窗口）、swapchain acquire / present / 重建。
# 配合 sync.v 的 semaphore 实现 acquire → 录制 → present 帧循环。

# ──────────────────────────────────────────────
# 表面
# ──────────────────────────────────────────────

⍝ 创建可呈现表面，绑定到平台原生窗口。
⍝ native_window 为平台窗口句柄的 u64 表示（如 Windows HWND、X11 Window、NSWindow 指针、canvas id）。
⍝ backend 决定如何解释该句柄；通常与设备后端一致。
[host_contract]
micro create_surface(backend: Backend, native_window: u64): SurfaceHandle {
    return SurfaceHandle { id: 0 }
}

⍝ 销毁可呈现表面。
⍝ 调用前应确保所有使用该表面的 swapchain 已销毁。
[host_contract]
micro destroy_surface(surface: SurfaceHandle): unit {
    return
}

# ──────────────────────────────────────────────
# 交换链
# ──────────────────────────────────────────────

⍝ acquire_next_image 的返回结果。
structure AcquireResult {
    ⍝ 获取到的图像索引，对应 image_view_at 取视图。
    image_index: u32
    ⍝ 是否为次优配置（如窗口尺寸变化），调用方应择机 recreate。
    suboptimal: bool
}

⍝ 交换链封装，管理可呈现图像并提供 acquire / present。
⍝ 每个 swapchain 拥有若干图像视图，渲染目标从中获取。
class Swapchain {
    ⍝ 内部交换链句柄。
    _handle: SwapchainHandle
    ⍝ 关联设备句柄。
    _device: DeviceHandle
    ⍝ 创建时使用的配置（extent 可能与实际不同，以 current_extent 为准）。
    _config: SwapchainConfig
}

imply Swapchain {
    ⍝ 创建交换链。
    ⍝ config.surface 必须已由 create_surface 创建并绑定到同一设备后端。
    [host_contract]
    micro new(device: DeviceHandle, config: SwapchainConfig): Self {
        return Swapchain {
            _handle: SwapchainHandle { id: 0 },
            _device: device,
            _config: config,
        }
    }

    ⍝ 返回交换链句柄。
    micro handle(self): SwapchainHandle {
        return self._handle
    }

    ⍝ 返回创建时使用的配置。
    micro config(self): SwapchainConfig {
        return self._config
    }

    ⍝ 返回交换链图像数量。
    [host_contract]
    micro image_count(self): u32 {
        return 0
    }

    ⍝ 返回指定索引的交换链图像视图，作为 begin_render_pass 的颜色附件。
    [host_contract]
    micro image_view_at(self, index: u32): ImageViewHandle {
        return ImageViewHandle { id: 0 }
    }

    ⍝ 返回交换链当前实际范围（可能与配置不同，窗口尺寸变化后由后端更新）。
    [host_contract]
    micro current_extent(self): Extent2D {
        return self._config.extent
    }

    ⍝ 返回交换链当前实际格式。
    [host_contract]
    micro current_format(self): Format {
        return self._config.format
    }

    ⍝ 获取下一张可呈现图像。
    ⍝ signal_semaphore 在图像就绪后被置位，调用方应在提交绘制命令时将其加入 wait_semaphores。
    ⍝ 返回图像索引与次优标志；suboptimal 为 true 时应择机 recreate。
    [host_contract]
    micro acquire_next_image(mut self, signal_semaphore: SemaphoreHandle): AcquireResult {
        return AcquireResult {
            image_index: 0,
            suboptimal: false,
        }
    }

    ⍝ 呈现指定图像到屏幕。
    ⍝ queue 为提交绘制命令的队列；wait_semaphores 在呈现前等待（通常为提交时 signal 的 semaphore）。
    [host_contract]
    micro present(mut self, queue: QueueHandle, image_index: u32, wait_semaphores: [SemaphoreHandle]): unit {
        return
    }

    ⍝ 重建交换链以适配新窗口尺寸或格式变化。
    ⍝ 调用前应确保设备空闲（无正在进行的 acquire / present）。
    ⍝ 重建后图像视图与句柄可能变化，调用方应重新获取。
    [host_contract]
    micro recreate(mut self, extent: Extent2D): unit {
        return
    }

    ⍝ 销毁交换链并释放其图像视图。
    [host_contract]
    micro destroy(mut self): unit {
        return
    }
}
