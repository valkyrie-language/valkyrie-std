# 公共图形栈

## 问题

当前 `valkyrie.v` 在图形学相关能力上存在明显断层：

- 缺少统一的 `GUI / 2D / 3D / compute` 公共抽象
- `layout`、`fonts`、`text shaping` 没有稳定落点
- GPU 相关能力仍处于“零散功能点”状态，没有形成可复用分层
- 结果是 `asgard`、`gnosis`、`titan` 都会重复碰撞同一批基础问题

这会直接卡住：

- `asgard.bifrost` 的跨平台自绘 GUI
- `gnosis` 的 2D/3D 游戏引擎主线
- `titan` 的 GPU compute / 深度学习后端

## 基本判断

这里缺的不是“再加几个 widget”或“再补几个 shader 示例”，而是**缺少一整套公共图形栈**。

这套公共图形栈必须满足两点：

1. 能同时服务 `GUI / game / deep learning`
2. 不能退化成新的统一大 `god graphics ir`

所以正确方向不是把所有东西硬塞进一个超级包，而是拆成稳定契约层。

## 长期分层

建议把公共图形栈放在 `gnosis._` 下面，由 `asgard.bifrost` 与 `titan` 消费。

## 与游戏开发分层的关系

当前更适合把游戏开发看成三层：

| 层级 | 说明 |
|:---|:---|
| **游戏引擎产品层** | `Genesis` 与 `Unity / Godot / Unreal` 按并列产品定位理解；`Cocos` 是否纳入正式并列范围暂未写死 |
| **游戏开发语义层** | 场景、实体、组件、系统、输入、动画、UI、任务、网络、Mod 等开发语义 |
| **游戏基础设施层** | runtime、graphics、asset、scene、physics、toolchain 等共享底座 |

这份文档讨论的是第三层，也就是**游戏基础设施层中的公共图形栈**。

它不直接定义某个具体引擎产品，也不直接定义完整游戏开发 DSL；它只负责为上层产品和语义提供稳定底座。

## 为什么放在 `gnosis._`

这里把共享图形栈放在 `gnosis._`，不是因为“游戏优先”，而是因为它最接近这套能力的自然归属：

- 这套东西本质上是图形基础设施，不是 GUI 语义层；放在 `asgard` 下会让 `layout / text / render / gpu` 被误解成 GUI 私有实现
- 这套东西也不是深度学习领域语义；放在 `titan` 下会让图形与 compute 底座被 AI runtime 反向主导
- `gnosis` 作为元游戏引擎，本来就需要完整消费 `2D / 3D / text / gpu / asset / scene`，因此最适合作为公共图形基础设施的宿主
- `asgard.bifrost` 与 `titan` 都是消费者，而不是这套图形底座的语义拥有者

所以更准确地说：不是 `gnosis` “负责 GUI”，而是 `gnosis._` 负责托管共享图形基础设施，`asgard` 负责 GUI 语义，`titan` 负责 compute / tensor runtime。

## 架构约束

为了避免图形基础设施重新长成一个过宽的大包，这里需要额外写死两条约束：

1. 共享图形栈归引擎基础设施承载，而不是挂到 GUI 或 AI 语义层下面。
2. 共享图形栈必须先拆成窄而稳定的 `gpu / text / layout / render / scene / asset`，不能退化成一个吞掉 `RHI / Shader / Pipeline / Material / Light / PostProcess / Compute` 的超级图形包。

进一步说：

- `asgard` 不能私有化 `layout / text / render / gpu`
- `titan` 不能私有化 `compute / device / memory / sync`
- ECS 通用核心不应被任何单一引擎产品私有化
- 图形后端能力可以逐步扩展，但后端细节不能反向定义公共抽象
- `Widget`、`Game UI`、`3D scene`、`deep learning compute` 都应建立在同一套底座之上，只在各自语义层分叉

## ECS 语言扩展的当前边界

游戏开发相关的 ECS 语言扩展，当前更适合拆成两层：

### 通用核心

这部分更接近跨引擎游戏开发的共同语言能力：

- `component`
- `system`
- `query`
- `resource`
- `event`
- `schedule`

### 引擎专属扩展

这部分更接近具体引擎产品的工作流语义：

- `scene`
- `prefab`
- `quest`
- `dialogue`
- `world`

当前不把这些引擎层语义直接并入公共图形栈，也暂时不写死为 `Genesis` 私有；更稳妥的方向是先稳定通用 ECS 核心，再由具体产品层追加自己的工作流扩展。

## 现在需要更细的分层

上面的 `gpu / text / layout / render / scene / asset` 只是第一层目录边界；真正能指导实现的，还要再往下拆。

如果不继续细化，后面很容易再次落回三种坏结果：

- `HAL` 变成一个什么都往里塞的大词
- `render` 同时承担 2D immediate、3D frame graph、present、shader binding，最后没有一个边界是真的
- `text / layout` 继续挂在 GUI 包里，无法被 game / visualization / compute tooling 复用

下面是我认为当前应该直接写死的更细分层。

## `HAL` 不是一个包

这里最需要先纠偏的是：`HAL` 不是一个统一大层。

至少要拆成三类：

### 1. Host HAL

负责宿主窗口系统与平台交互，不负责 GPU device 本体：

- window
- display / monitor
- surface creation
- input bridge
- IME
- clipboard
- cursor
- accessibility bridge

这层更接近 `asgard host` / 桌面宿主 / 移动宿主，不能和 `gnosis.gpu` 混成一个接口。

### 2. GPU HAL

负责 GPU 设备、资源、命令、同步、present 契约。

这是 `gnosis.gpu` 的核心，但它自己还要继续拆层，不能再是一个平铺大包。

### 3. Compute HAL

负责 headless compute 视角下的 device / queue / memory / kernel execution。

它不应该成为独立第二套实现，而应该是 `gnosis.gpu` 里不依赖 surface / present 的那部分能力视图，供 `titan` 直接消费。

换句话说：

- `asgard` 更关心 Host HAL + Surface
- `gnosis` 需要完整 GPU HAL
- `titan` 只需要 Compute HAL 视图

## `gnosis.gpu` 需要再拆 7 层

### 1. `gnosis.gpu.adapter`

负责物理设备发现与能力查询：

- adapter enumeration
- feature flags
- limits
- memory classes
- queue family exposure
- format capability query

这里的关键观点是：**能力查询必须先于抽象承诺**。  
不要先设计一个“理论上统一”的接口，再让每个后端偷偷降级。

### 2. `gnosis.gpu.device`

负责逻辑设备与队列创建：

- device creation
- queue acquisition
- queue role (`graphics / compute / transfer / present`)
- device lost
- debug label / marker

这里必须明确：`Device` 不等于 `Surface`。  
`titan` 的 headless compute device 不应被 swapchain / present 语义污染。

### 3. `gnosis.gpu.memory`

负责资源与内存模型：

- buffer
- texture
- sampler
- upload heap / staging buffer
- readback
- residency / lifetime
- transient resource
- aliasing policy

我自己的判断是：**真正难的不是创建资源，而是资源生存期与上传路径**。  
如果这里不先立住，GUI atlas、3D streaming、tensor buffer 最后都会各搞一套 uploader。

### 4. `gnosis.gpu.shader`

负责 shader module 与 pipeline layout 契约：

- shader module
- entry point
- descriptor / bind layout
- push constants / root constants
- specialization constants
- reflection metadata

这里必须避免重新做一个“统一大 shader ir”。  
需要的是稳定的 shader module contract 和 reflection contract，而不是一个试图替代所有后端的万能 IR。

### 5. `gnosis.gpu.pipeline`

负责 pipeline object 与状态对象：

- render pipeline
- compute pipeline
- pipeline layout
- render state
- blend / depth / stencil
- cache key
- pipeline cache

我的观点是：pipeline cache 必须从第一天就是正式能力，不是后补优化。  
GUI、3D、compute 都会被 pipeline 抖动直接拖垮。

### 6. `gnosis.gpu.command`

负责命令录制与提交：

- command encoder
- command buffer
- render pass encoding
- compute pass encoding
- copy / blit / resolve
- queue submit
- indirect dispatch / draw

这里不能把 render graph 和 command encoder 混成一层。  
`render graph` 是上层调度模型，`command` 是底层执行录制模型。

### 7. `gnosis.gpu.sync`

负责同步与状态迁移：

- fence
- semaphore
- timeline semaphore / timeline fence
- barrier
- resource state transition
- ownership transfer
- frame pacing

这一层是过去最容易被“先能跑起来”跳过的地方，但我认为它恰恰是公共 GPU 契约里最不能糊涂的一层。  
`asgard.bifrost` 的帧循环、`gnosis` 的多 pass 渲染、`titan` 的 compute execution，最后都会在这里汇合。

## `surface / present` 应单独建边界

`Surface` 和 `Present` 不该埋在 `Device` 里。

建议把它们视为 `gnosis.gpu.present` 这一层能力：

- swapchain
- surface capabilities
- present mode
- frame acquire
- frame present
- resize / recreate
- vsync / frame pacing

这样做的原因很直接：

- GUI / game 需要 present
- compute 不需要 present
- headless renderer 可能需要 offscreen target，但不需要 window surface

如果 `present` 不独立，`titan` 就会被图形窗口语义污染；如果 `surface` 不独立，桌面宿主和 GPU device 会互相绑死。

### 1. `gnosis.gpu`

负责最底层 GPU / 图形设备抽象：

- `Device`
- `Surface`
- `Queue`
- `Buffer`
- `Texture`
- `Sampler`
- `Shader`
- `BindGroup`
- `RenderPipeline`
- `ComputePipeline`
- `CommandEncoder`
- `RenderPass`
- `ComputePass`

这是所有图形与计算能力的共同底座。

更准确地说，`gnosis.gpu` 应该是上述 `adapter / device / memory / shader / pipeline / command / sync / present` 的总入口，而不是一个把所有实现文件平铺在一起的目录。

### 2. `gnosis.text`

负责文本与字体系统：

- font collection / font fallback
- 字体度量
- text shaping
- bidi / script 分段
- glyph atlas
- 文本行分割
- 段落布局

这个层必须独立存在，不能让 GUI、游戏 HUD、数据可视化、深度学习可视化各做一份。

这层我认为至少还要再拆成 4 块：

- `font`：font source、font collection、fallback、packing
- `shaping`：script split、bidi、glyph shaping、cluster mapping
- `paragraph`：line break、alignment、wrap、truncate、selection
- `atlas`：glyph atlas、cache eviction、raster strategy、SDF / bitmap policy

这里真正的难点不是“画文字”，而是让文本测量在 GUI、HUD、图表标注里一致。

### 3. `gnosis.layout`

负责布局系统：

- constraints
- intrinsic size
- flex
- grid
- stack / flow
- scroll viewport
- text measure 对接

它不等于 GUI widget，本质上是**通用布局引擎**。

这层至少应细分为：

- `measure`：约束传播、intrinsic size、baseline
- `arrange`：box placement、alignment、overflow
- `flow`：flex / grid / wrap / stack
- `viewport`：scroll、clip、sticky、virtualization hooks
- `hit-test`：layout box 与 input geometry

我的看法是：layout 最大的坑不是算法名，而是 measure contract。  
只要 `text measure`、`intrinsic size`、`baseline` 没写死，后面所有复杂组件都会变成特判地狱。

### 4. `gnosis.render`

负责统一渲染抽象：

- 2D draw list
- 3D render graph
- material / pass / attachment
- batched draw
- scene submission
- render graph / frame graph

它消费 `gnosis.gpu`，但不替代 `gnosis.scene`。

这一层建议内部就分成两个视角：

- `render2d`：path / quad / image / text / clip / layer / compositor
- `render3d`：frame graph、pass scheduling、material submission、visibility input

不要一开始就把 2D 和 3D 重新合成一个万能 draw API。  
它们共享底层 GPU，但上层调度模型并不相同。

### 5. `gnosis.scene`

负责 2D / 3D 场景表达：

- transform tree
- camera
- light
- mesh / sprite / text node
- visibility / culling
- scene submission

而且 `scene` 不该承担 render graph，也不该承担 asset loading。  
它只负责“场景表达”和“可提交视图”。

### 6. `gnosis.asset`

负责图形资源：

- mesh
- image
- texture
- material
- font
- shader module
- pipeline cache

我倾向于把 `pipeline cache` 最终从 `asset` 里拆到 `gpu.pipeline` 附近，只把可持久化缓存结果通过 `asset` 体系管理；否则很容易把“资源资产”和“运行时状态缓存”重新混起来。

## 各生态如何消费

### `asgard.bifrost`

`asgard.bifrost` 不应该自己重写一套 GPU / text / layout 栈，而应该：

- 用 `gnosis.layout` 解决布局
- 用 `gnosis.text` 解决字体、排版、字形问题
- 用 `gnosis.render` + `gnosis.gpu` 做自绘

`asgard.bifrost` 自己只负责：

- 把 `asgard.ui` 视图树翻译成布局树
- 把交互语义翻译成渲染命令
- 处理 GUI 特有的事件命中、焦点、输入法、无障碍边界

### `gnosis`

`gnosis` 自己消费完整图形栈：

- `gnosis.gpu`
- `gnosis.text`
- `gnosis.layout`
- `gnosis.render`
- `gnosis.scene`
- `gnosis.asset`

它是图形基础设施本体，不只是“一个游戏包”。

### `titan`

`titan` 不应拥有自己的 GPU 设备抽象。

它应该直接消费：

- `gnosis.gpu` 的 compute / buffer / texture / queue / sync 能力

必要时可有自己的：

- `titan.compute`
- `titan.device`

但这些应建立在共享 GPU 契约之上，而不是重新定义第二套 device model。

更细一点：

- `titan.device`：device policy、memory planner、execution capability profile
- `titan.compute`：kernel dispatch、graph executor、stream scheduling
- `titan.tensor`：tensor storage / view / dtype / shape / layout

其中只有 `tensor` 是 Titan 领域语义；下面的 device / queue / sync / memory 不应该再私有化。

## 最难的问题不能回避

### Layout

`layout` 不是 widget 皮肤问题，而是整套图形栈里的硬骨头。

必须明确：

- 测量协议
- 约束传播
- intrinsic size
- text measure 接口
- overflow / clip / scroll

否则 GUI 一直停留在“页面模板能跑”，进不了真正的 native/self-draw runtime。

### Fonts / Text

字体系统不能再继续依赖宿主“差不多有个 font-family 就行”。

必须解决：

- 字体发现与打包
- fallback chain
- shaping
- glyph cache
- 文本测量一致性
- 多脚本与复杂文字

否则：

- GUI 文本不稳定
- 游戏 UI/HUD 不稳定
- 数据可视化轴标签、图例、注释不稳定

### GPU

GPU 现在最缺的是**分层与能力契约**，不是 shader 语法糖。

至少要把以下边界明确：

- resource lifetime
- upload / staging
- render / compute pass
- synchronization
- pipeline cache
- backend capability query

除此之外，我认为 GPU 还有三个必须提前定的点：

- **feature profile**：不能只做 bool feature list，要有可组合 capability profile
- **fallback policy**：哪些能力允许降级，哪些能力必须硬失败
- **escape hatch**：允许少量 backend-specific extension，但必须隔离在明确边界内，不能污染公共接口

否则抽象会在两头一起坏掉：要么过于最低公分母，要么被某个后端绑架。

没有这些，后面无论是 GUI 自绘、3D 渲染，还是深度学习 compute，都会各自重复踩坑。

## 推荐施工顺序

### Phase 1

先补最小公共底座：

- `gnosis.gpu.adapter/device/memory/command/sync`
- `gnosis.text`
- `gnosis.layout`

### Phase 2

在底座之上补：

- `gnosis.render`（先 2D，后 3D）
- `asgard.bifrost` 接入

### Phase 3

再补：

- `gnosis.scene`
- `gnosis.asset`
- `titan` 的共享 GPU compute 后端

## 目录建议

`gnosis._` 最终建议至少包含：

- `projects/gnosis`
- `projects/gnosis.gpu`
- `projects/gnosis.text`
- `projects/gnosis.layout`
- `projects/gnosis.render`
- `projects/gnosis.scene`
- `projects/gnosis.physics`
- `projects/gnosis.asset`
- `projects/gnosis.tools`

`titan._` 建议补出：

- `projects/titan.compute`
- `projects/titan.device`

## 结论

当前真正卡住 `gui / game / deep learning` 的，不是某个单点功能，而是**缺少公共图形栈**。

最关键的不是先选 `Skia / WGPU / FemtoVG` 哪个名字，而是先把下面这些边界立住：

- GPU
- text / fonts
- layout
- render
- scene

一旦这五层立住，`asgard.bifrost`、`gnosis`、`titan` 就都能继续推进；不然三边都会反复造轮子，而且越造越耦合。
