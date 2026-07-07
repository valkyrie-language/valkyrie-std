namespace gnosis.gpu.types;

# gnosis.gpu.types: GPU 基础类型定义
# 定义跨后端通用的 GPU 句柄、格式、用途标志与几何描述。
# 所有句柄均为不透明 u64 包装，由具体后端 adaptor 赋值，调用方不应解释其数值含义。

# ──────────────────────────────────────────────
# 句柄类型
# ──────────────────────────────────────────────

⍝ 适配器句柄，代表一个物理 GPU 设备。
structure AdapterHandle {
    ⍝ 后端分配的不透明标识。
    id: u64
}

⍝ 逻辑设备句柄，由适配器创建。
structure DeviceHandle {
    ⍝ 后端分配的不透明标识。
    id: u64
}

⍝ 命令提交队列句柄。
structure QueueHandle {
    ⍝ 后端分配的不透明标识。
    id: u64
}

⍝ 命令池句柄，用于分配命令缓冲区。
structure CommandPoolHandle {
    ⍝ 后端分配的不透明标识。
    id: u64
}

⍝ 命令缓冲区句柄，用于录制 GPU 命令。
structure CommandBufferHandle {
    ⍝ 后端分配的不透明标识。
    id: u64
}

⍝ 交换链句柄，管理可呈现图像。
structure SwapchainHandle {
    ⍝ 后端分配的不透明标识。
    id: u64
}

⍝ 可呈现表面句柄，绑定到平台窗口。
structure SurfaceHandle {
    ⍝ 后端分配的不透明标识。
    id: u64
}

⍝ GPU 缓冲区句柄（顶点 / 索引 / 统一 / 存储）。
structure BufferHandle {
    ⍝ 后端分配的不透明标识。
    id: u64
}

⍝ GPU 图像句柄（颜色 / 深度 / 纹理）。
structure ImageHandle {
    ⍝ 后端分配的不透明标识。
    id: u64
}

⍝ 图像视图句柄，描述如何访问图像的子资源范围。
structure ImageViewHandle {
    ⍝ 后端分配的不透明标识。
    id: u64
}

⍝ 着色器模块句柄，持有已编译着色器字节码。
structure ShaderModuleHandle {
    ⍝ 后端分配的不透明标识。
    id: u64
}

⍝ 图形管线句柄（着色器 + 状态）。
structure PipelineHandle {
    ⍝ 后端分配的不透明标识。
    id: u64
}

⍝ Fence 句柄，用于 CPU-GPU 同步。
structure FenceHandle {
    ⍝ 后端分配的不透明标识。
    id: u64
}

⍝ Semaphore 句柄，用于 GPU-GPU 同步（队列间 / acquire-present）。
structure SemaphoreHandle {
    ⍝ 后端分配的不透明标识。
    id: u64
}

# ──────────────────────────────────────────────
# 后端与队列
# ──────────────────────────────────────────────

⍝ 可选的 GPU 后端。
unite Backend {
    ⍝ 自动选择最合适的后端。
    Auto
    ⍝ Vulkan 后端（Windows / Linux / Android）。
    Vulkan
    ⍝ Direct3D 12 后端（Windows / Xbox）。
    D3D12
    ⍝ Metal 后端（macOS / iOS）。
    Metal
    ⍝ WebGPU 后端（浏览器 / WASM）。
    WebGPU
}

⍝ 队列族类型，决定队列支持的命令类别。
unite QueueFamily {
    ⍝ 支持图形 / 计算 / 传输命令。
    Graphics
    ⍝ 支持计算 / 传输命令。
    Compute
    ⍝ 仅支持传输命令。
    Transfer
}

⍝ 创建设备时对队列族的请求。
structure QueueRequest {
    ⍝ 期望的队列族。
    family: QueueFamily
    ⍝ 期望的队列数量。
    count: u32
}

# ──────────────────────────────────────────────
# 格式与布局
# ──────────────────────────────────────────────

⍝ 图像像素格式。
unite Format {
    ⍝ 8 位 RGBA，归一化无符号。
    R8G8B8A8_Unorm
    ⍝ 8 位 BGRA，归一化无符号（常用 swapchain）。
    B8G8R8A8_Unorm
    ⍝ 8 位 RGBA，sRGB 编码。
    R8G8B8A8_Srgb
    ⍝ 8 位 BGRA，sRGB 编码（常用 swapchain）。
    B8G8R8A8_Srgb
    ⍝ 32 位浮点深度。
    D32_Float
    ⍝ 24 位无符号深度 + 8 位模板。
    D24_Unorm_S8_Uint
    ⍝ 16 位浮点红通道（HDR 亮度图）。
    R16_Float
    ⍝ 32 位浮点红通道。
    R32_Float
}

⍝ 图像布局，描述图像资源在 GPU 管线中的当前状态。
unite ImageLayout {
    ⍝ 未定义布局，转换源时可丢弃旧内容。
    Undefined
    ⍝ 通用布局，支持所有访问。
    General
    ⍝ 作为颜色附件。
    ColorAttachment
    ⍝ 作为深度 / 模板附件。
    DepthAttachment
    ⍝ 作为着色器只读资源（纹理）。
    ShaderRead
    ⍝ 作为传输源（copy src）。
    TransferSrc
    ⍝ 作为传输目标（copy dst）。
    TransferDst
    ⍝ 用于呈现到屏幕。
    Present
}

⍝ 图像子资源维度。
unite ImageAspect {
    ⍝ 颜色层面。
    Color
    ⍝ 深度层面。
    Depth
    ⍝ 模板层面。
    Stencil
}

⍝ 交换链呈现模式。
unite PresentMode {
    ⍝ 立即呈现，无垂直同步。
    Immediate
    ⍝ 邮箱模式，低延迟 vsync。
    Mailbox
    ⍝ 先进先出，垂直同步（默认）。
    Fifo
    ⍝ 宽松 FIFO，无新帧时才 vsync。
    FifoRelaxed
}

⍝ 渲染通道附件在开始时的加载策略。
unite LoadOp {
    ⍝ 清除附件为指定值。
    Clear
    ⍝ 保留附件现有内容。
    Load
    ⍝ 不关心现有内容（可丢弃）。
    DontCare
}

⍝ 渲染通道附件在结束时的存储策略。
unite StoreOp {
    ⍝ 存储写入结果。
    Store
    ⍝ 不关心写入结果（可丢弃）。
    DontCare
}

# ──────────────────────────────────────────────
# 用途标志
# ──────────────────────────────────────────────

⍝ 缓冲区用途标志，描述缓冲区在管线中的角色。
structure BufferUsage {
    ⍝ 作为顶点缓冲区。
    vertex: bool
    ⍝ 作为索引缓冲区。
    index: bool
    ⍝ 作为统一缓冲区（constant buffer）。
    uniform: bool
    ⍝ 作为存储缓冲区（SSBO / structured buffer）。
    storage: bool
    ⍝ 可作为传输源（copy src）。
    copy_src: bool
    ⍝ 可作为传输目标（copy dst）。
    copy_dst: bool
}

⍝ 图像用途标志，描述图像在管线中的角色。
structure ImageUsage {
    ⍝ 可被着色器采样（纹理）。
    sampled: bool
    ⍝ 作为颜色附件。
    color_attachment: bool
    ⍝ 作为深度 / 模板附件。
    depth_attachment: bool
    ⍝ 作为存储图像（UAV）。
    storage: bool
    ⍝ 可作为传输源。
    copy_src: bool
    ⍝ 可作为传输目标。
    copy_dst: bool
}

# ──────────────────────────────────────────────
# 几何描述
# ──────────────────────────────────────────────

⍝ 二维范围。
structure Extent2D {
    ⍝ 宽度（像素）。
    width: u32
    ⍝ 高度（像素）。
    height: u32
}

⍝ 三维范围。
structure Extent3D {
    ⍝ 宽度（像素）。
    width: u32
    ⍝ 高度（像素）。
    height: u32
    ⍝ 深度（像素 / 层数）。
    depth: u32
}

⍝ 图像子资源范围，指定 mip / 层切片。
structure SubresourceRange {
    ⍝ 涉及的维度。
    aspect: ImageAspect
    ⍝ 起始 mip 层级。
    base_mip_level: u32
    ⍝ mip 层级数量。
    level_count: u32
    ⍝ 起始数组层。
    base_array_layer: u32
    ⍝ 数组层数量。
    layer_count: u32
}

⍝ 视口描述。
structure Viewport {
    ⍝ 左下角 x 坐标。
    x: f32
    ⍝ 左下角 y 坐标。
    y: f32
    ⍝ 视口宽度。
    width: f32
    ⍝ 视口高度。
    height: f32
    ⍝ 最小深度。
    min_depth: f32
    ⍝ 最大深度。
    max_depth: f32
}

⍝ 裁剪矩形描述。
structure Scissor {
    ⍝ 左上角 x 坐标。
    x: i32
    ⍝ 左上角 y 坐标。
    y: i32
    ⍝ 矩形宽度。
    width: u32
    ⍝ 矩形高度。
    height: u32
}

# ──────────────────────────────────────────────
# 渲染通道附件（WebGPU 风格的显式附件绑定）
# ──────────────────────────────────────────────

⍝ 颜色附件清除值。
structure ClearColorValue {
    ⍝ 红色分量。
    r: f32
    ⍝ 绿色分量。
    g: f32
    ⍝ 蓝色分量。
    b: f32
    ⍝ Alpha 分量。
    a: f32
}

⍝ 深度 / 模板清除值。
structure ClearDepthStencilValue {
    ⍝ 深度清除值（0.0 = 近平面）。
    depth: f32
    ⍝ 模板清除值。
    stencil: u32
}

⍝ 颜色附件描述，用于 begin_render_pass。
structure ColorAttachment {
    ⍝ 绑定的图像视图。
    view: ImageViewHandle
    ⍝ 开始时的加载策略。
    load_op: LoadOp
    ⍝ 结束时的存储策略。
    store_op: StoreOp
    ⍝ 清除时使用的颜色值。
    clear: ClearColorValue
}

⍝ 深度 / 模板附件描述，用于 begin_render_pass。
structure DepthAttachment {
    ⍝ 绑定的图像视图。
    view: ImageViewHandle
    ⍝ 深度加载策略。
    depth_load_op: LoadOp
    ⍝ 深度存储策略。
    depth_store_op: StoreOp
    ⍝ 模板加载策略。
    stencil_load_op: LoadOp
    ⍝ 模板存储策略。
    stencil_store_op: StoreOp
    ⍝ 清除时使用的深度 / 模板值。
    clear: ClearDepthStencilValue
}

# ──────────────────────────────────────────────
# 管线描述
# ──────────────────────────────────────────────

⍝ 基本图元拓扑。
unite PrimitiveTopology {
    ⍝ 每三个顶点构成一个三角形。
    TriangleList
    ⍝ 顶点按顺序构成三角形带。
    TriangleStrip
    ⍝ 每两个顶点构成一条线段。
    LineList
    ⍝ 顶点按顺序构成线带。
    LineStrip
}

⍝ 索引类型。
unite IndexType {
    ⍝ 16 位无符号索引。
    Uint16
    ⍝ 32 位无符号索引。
    Uint32
}

⍝ 着色器阶段掩码，用于 push constants 等可见性声明。
unite ShaderStage {
    ⍝ 顶点着色器阶段。
    Vertex
    ⍝ 片段着色器阶段。
    Fragment
    ⍝ 顶点 + 片段阶段。
    VertexFragment
}

⍝ 图形管线描述，创建图形管线所需的最小信息。
structure PipelineDescription {
    ⍝ 顶点着色器模块。
    vertex_shader: ShaderModuleHandle
    ⍝ 片段着色器模块。
    fragment_shader: ShaderModuleHandle
    ⍝ 图元拓扑。
    topology: PrimitiveTopology
    ⍝ 目标颜色格式。
    color_format: Format
    ⍝ 目标深度格式，None 表示无深度附件。
    depth_format: Option<Format>
    ⍝ 是否启用深度测试。
    depth_test: bool
    ⍝ 是否启用深度写入。
    depth_write: bool
}

# ──────────────────────────────────────────────
# 交换链配置
# ──────────────────────────────────────────────

⍝ 交换链创建配置。
structure SwapchainConfig {
    ⍝ 绑定的可呈现表面。
    surface: SurfaceHandle
    ⍝ 交换链图像数量（通常为 2 或 3）。
    image_count: u32
    ⍝ 交换链图像格式。
    format: Format
    ⍝ 呈现模式。
    present_mode: PresentMode
    ⍝ 交换链图像范围（像素）。
    extent: Extent2D
    ⍝ CPU 可领先 GPU 的帧数（用于 dynamic buffer 环形槽位）。
    frames_in_flight: u32
}
