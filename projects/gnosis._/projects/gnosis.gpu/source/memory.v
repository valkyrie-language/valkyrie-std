namespace gnosis.gpu.memory;

# gnosis.gpu.memory: 内存与上传路径
# 提供 dynamic buffer（环形上传，每帧 O(1) 分配）与 staging pool（一次性大块上传）。
# 设计目标：支撑 1000+ 动态对象时接口不需要返工。

# ──────────────────────────────────────────────
# 后端映射辅助（内部 host contract）
# ──────────────────────────────────────────────

⍝ 已映射缓冲区创建结果，包含缓冲区句柄与持久映射的 CPU 可写地址。
structure MappedBuffer {
    ⍝ 创建得到的缓冲区句柄。
    buffer: BufferHandle
    ⍝ 持久映射的 CPU 可写基地址（以 u64 表示的原始指针）。
    host_ptr: u64
}

⍝ 创建一个可持久映射的缓冲区，用于 dynamic / staging 上传。
⍝ usage 通常包含 copy_src（dynamic）或 copy_src + vertex/index（直接绑定）。
[host_contract]
micro _create_mapped_buffer(device: DeviceHandle, usage: BufferUsage, size: u64): MappedBuffer {
    return MappedBuffer {
        buffer: BufferHandle { id: 0 },
        host_ptr: 0,
    }
}

⍝ 解除映射并销毁由 _create_mapped_buffer 创建的缓冲区。
[host_contract]
micro _destroy_mapped_buffer(device: DeviceHandle, buffer: BufferHandle): unit {
    return
}

# ──────────────────────────────────────────────
# Dynamic buffer: 环形上传
# ──────────────────────────────────────────────

⍝ 一次动态分配的结果。
⍝ 调用方通过 host_ptr 写入 CPU 数据，通过 buffer + offset 绑定到命令缓冲区。
structure AllocationResult {
    ⍝ 所属缓冲区句柄，用于 bind_vertex_buffer / bind_index_buffer。
    buffer: BufferHandle
    ⍝ GPU 可见偏移（字节），从缓冲区起始计算。
    offset: u64
    ⍝ CPU 可写起始地址（以 u64 表示的原始指针）。
    host_ptr: u64
    ⍝ 实际分配的字节数。
    size: u64
    ⍝ 所属帧槽位索引，便于关联 fence。
    frame_index: u32
}

⍝ 环形动态缓冲区，按帧槽位（frames in flight）复用。
⍝ 每帧从当前槽位线性分配，槽位用尽时由调用方等待对应 fence 后继续。
⍝ 支撑 1000+ 动态对象的顶点 / 索引数据每帧上传，O(1) 单次分配。
class DynamicBuffer {
    ⍝ 底层缓冲区句柄。
    _buffer: BufferHandle
    ⍝ 关联设备句柄。
    _device: DeviceHandle
    ⍝ 每帧可用字节数。
    _frame_capacity: u64
    ⍝ 帧槽位数量（等于 frame_fences 长度）。
    _frames_in_flight: usize
    ⍝ 当前帧槽位索引。
    _frame_index: usize
    ⍝ 当前帧内已分配字节数。
    _frame_offset: u64
    ⍝ 每个帧槽位关联的 fence（由调用方创建并销毁）。
    _frame_fences: [FenceHandle]
    ⍝ 持久映射的 CPU 可写基地址。
    _host_ptr: u64
    ⍝ 缓冲区总容量（frame_capacity * frames_in_flight）。
    _total_capacity: u64
}

imply DynamicBuffer {
    ⍝ 创建动态缓冲区。
    ⍝ frame_capacity 为每帧可用字节数；frame_fences 长度决定帧槽位数量，
    ⍝ 调用方应按 frames_in_flight 创建对应数量的 fence 并传入。
    micro new(device: DeviceHandle, usage: BufferUsage, frame_capacity: u64, frame_fences: [FenceHandle]): Self {
        let frames: usize = frame_fences.length
        let total: u64 = frame_capacity * (frames as u64)
        let mapped: MappedBuffer = _create_mapped_buffer(device, usage, total)
        return DynamicBuffer {
            _buffer: mapped.buffer,
            _device: device,
            _frame_capacity: frame_capacity,
            _frames_in_flight: frames,
            _frame_index: 0,
            _frame_offset: 0,
            _frame_fences: frame_fences,
            _host_ptr: mapped.host_ptr,
            _total_capacity: total,
        }
    }

    ⍝ 在当前帧槽位分配 size 字节，按 alignment 向上对齐。
    ⍝ 返回 None 表示当前帧槽位已满，调用方应等待 fence 后推进到下一帧或增大 frame_capacity。
    ⍝ 单次分配为 O(1)，不触发任何 GPU 操作。
    micro alloc(mut self, size: u64, alignment: u64): Option<AllocationResult> {
        let aligned: u64 = ((self._frame_offset + alignment - 1) / alignment) * alignment
        if aligned + size > self._frame_capacity {
            return None
        }
        let gpu_offset: u64 = (self._frame_index as u64) * self._frame_capacity + aligned
        let host_ptr: u64 = self._host_ptr + gpu_offset
        self._frame_offset = aligned + size
        return Some::<AllocationResult>(AllocationResult {
            buffer: self._buffer,
            offset: gpu_offset,
            host_ptr: host_ptr,
            size: size,
            frame_index: self._frame_index as u32,
        })
    }

    ⍝ 推进到下一帧槽位，重置该槽位的分配偏移。
    ⍝ 返回该槽位关联的 fence；调用方应等待该 fence 被置位后再写入（确保 GPU 已读完旧数据）。
    ⍝ 推进后通常紧接着 reset_fence 以便本帧提交时复用。
    micro next_frame(mut self): FenceHandle {
        let fence: FenceHandle = self._frame_fences[self._frame_index]
        self._frame_index = (self._frame_index + 1) % self._frames_in_flight
        self._frame_offset = 0
        return fence
    }

    ⍝ 返回当前帧槽位索引。
    micro frame_index(self): usize {
        return self._frame_index
    }

    ⍝ 返回当前帧内已分配字节数。
    micro frame_offset(self): u64 {
        return self._frame_offset
    }

    ⍝ 返回底层缓冲区句柄，用于 bind_vertex_buffer / bind_index_buffer。
    micro handle(self): BufferHandle {
        return self._buffer
    }

    ⍝ 销毁动态缓冲区并解除映射。
    ⍝ 注意：frame_fences 由调用方负责销毁，本方法不处理。
    micro destroy(mut self): unit {
        _destroy_mapped_buffer(self._device, self._buffer)
        return
    }
}

# ──────────────────────────────────────────────
# Staging pool: 一次性大块上传
# ──────────────────────────────────────────────

⍝ 一次 staging 分配的结果。
⍝ 调用方通过 host_ptr 写入数据，通过 buffer + offset 配合 CommandBuffer.copy_buffer 上传到目标。
structure StagingAllocation {
    ⍝ staging 缓冲区句柄。
    buffer: BufferHandle
    ⍝ 分配区间起始偏移（字节）。
    offset: u64
    ⍝ CPU 可写起始地址（以 u64 表示的原始指针）。
    host_ptr: u64
    ⍝ 实际分配的字节数。
    size: u64
}

⍝ 一次性上传缓冲池，用于纹理初始化 / 静态 mesh 上传等非每帧热路径。
⍝ 内部为单块持久映射缓冲区，线性分配；reset 后可复用（需确保 GPU 已完成此前拷贝）。
class StagingPool {
    ⍝ 底层 staging 缓冲区句柄。
    _buffer: BufferHandle
    ⍝ 关联设备句柄。
    _device: DeviceHandle
    ⍝ 缓冲区总容量（字节）。
    _capacity: u64
    ⍝ 当前已分配偏移（字节）。
    _offset: u64
    ⍝ 持久映射的 CPU 可写基地址。
    _host_ptr: u64
}

imply StagingPool {
    ⍝ 创建一个容量为 capacity 字节的 staging 池。
    micro new(device: DeviceHandle, capacity: u64): Self {
        let usage: BufferUsage = BufferUsage {
            vertex: false,
            index: false,
            uniform: false,
            storage: false,
            copy_src: true,
            copy_dst: false,
        }
        let mapped: MappedBuffer = _create_mapped_buffer(device, usage, capacity)
        return StagingPool {
            _buffer: mapped.buffer,
            _device: device,
            _capacity: capacity,
            _offset: 0,
            _host_ptr: mapped.host_ptr,
        }
    }

    ⍝ 分配 size 字节，按 alignment 向上对齐。
    ⍝ 返回 None 表示池已满，调用方应等待 GPU 完成已有拷贝后调用 reset，或创建更大的池。
    micro alloc(mut self, size: u64, alignment: u64): Option<StagingAllocation> {
        let aligned: u64 = ((self._offset + alignment - 1) / alignment) * alignment
        if aligned + size > self._capacity {
            return None
        }
        let host_ptr: u64 = self._host_ptr + aligned
        self._offset = aligned + size
        return Some::<StagingAllocation>(StagingAllocation {
            buffer: self._buffer,
            offset: aligned,
            host_ptr: host_ptr,
            size: size,
        })
    }

    ⍝ 重置分配偏移，使整个池可复用。
    ⍝ 调用前必须确保 GPU 已完成此前由本池发起的所有 copy 命令（通过 fence 同步）。
    micro reset(mut self): unit {
        self._offset = 0
        return
    }

    ⍝ 返回底层 staging 缓冲区句柄。
    micro handle(self): BufferHandle {
        return self._buffer
    }

    ⍝ 销毁 staging 池并解除映射。
    micro destroy(mut self): unit {
        _destroy_mapped_buffer(self._device, self._buffer)
        return
    }
}
