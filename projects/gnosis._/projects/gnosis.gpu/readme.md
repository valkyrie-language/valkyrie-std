# gnosis.gpu

`gnosis.gpu` 是 `gnosis._` 工作区下的**跨后端 GPU 抽象最小 contract**。
它定义 adapter / device / queue / memory / command / sync / present 的最小接口，
供 `gnosis.render`、`asgard.bifrost`、`titan` 等上层复用，避免每个图形栈各造一套 device model。

## 设计目标

- **最小 contract**：只定义支撑 2D world pass + HUD pass 所需的接口，不引入渲染器层概念。
- **后端无关**：底层操作以 `[host_contract]` 声明，由各平台 adaptor（Vulkan / D3D12 / Metal / WebGPU）实现。
- **可扩展**：1000 个动态对象时接口不需要返工；dynamic buffer 采用环形上传，每帧 O(1) 分配。
- **通用基建**：不含任何 Geometry Wars 专属逻辑，可被任意 2D / 3D 游戏样板复用。

## 文件布局

| 文件 | 职责 |
|:---|:---|
| `source/types.v` | GPU 句柄、格式、用途标志、几何描述、管线描述 |
| `source/adapter.v` | 后端选择、适配器枚举、逻辑设备创建入口 |
| `source/device.v` | 逻辑设备、队列；GPU 资源（buffer/image/pipeline）创建与销毁 |
| `source/memory.v` | dynamic buffer 环形上传、staging pool 一次性上传 |
| `source/command.v` | 命令池、命令缓冲区录制（render pass / bind / draw / barrier / copy） |
| `source/sync.v` | fence（CPU-GPU）、semaphore（GPU-GPU）、pipeline barrier 类型 |
| `source/present.v` | surface 创建、swapchain acquire / present |

## 能力清单

- 适配器枚举 + 偏好选择 + 逻辑设备创建
- 队列抽象（graphics / compute / transfer），命令提交
- GPU 资源生命周期：buffer / image / image view / shader module / pipeline
- dynamic buffer：每帧环形分配，返回 `(offset, host_ptr, frame_index)`，支撑 1000+ 动态对象
- staging pool：一次性大块上传（纹理初始化、静态 mesh）
- 命令录制：render pass（color + depth 附件）、bind pipeline / vertex / index、push constants、draw / draw_indexed、copy、pipeline barrier
- 同步：fence（reset / wait / status）、semaphore、image / buffer memory barrier
- 帧循环：swapchain acquire → 录制 → submit（signal fence + semaphore）→ present

## 典型帧循环

```
# 每帧
fence = dynamic_buffer.next_frame()       # 取得下一帧槽位对应的 fence
device.wait_for_fences([fence], true, ..) # 等待该槽位 GPU 完成（可复用）
device.reset_fences([fence])

# 分配本帧动态数据
alloc = dynamic_buffer.alloc(vertex_bytes, 16)
# 写入 alloc.host_ptr ...

img_idx = swapchain.acquire_next_image(image_available_sem)
cmd = command_pool.allocate()
cmd.begin()
cmd.begin_render_pass([color_attachment], depth_attachment)
cmd.bind_pipeline(pipeline)
cmd.bind_vertex_buffer(0, dynamic_buffer.handle(), alloc.offset)
cmd.draw(vertex_count, 1, 0, 0)
cmd.end_render_pass()
cmd.end()
queue.submit(cmd.handle(), render_finished_fence, [image_available_sem], [render_finished_sem])
swapchain.present(queue.handle(), img_idx, [render_finished_sem])
```

## 不在范围内

- descriptor set / bind group 绑定（留给后续 `gnosis.render` 或单独包）
- 着色器编译 / 反射（仅接收已编译字节码）
- 资源 RAII / 引用计数（显式 destroy 接口）
- 多线程录制（当前为单线程命令缓冲区模型）
