# CLR 后端

## 定位

`CLR` family 面向 `CLR` 托管宿主、`IL` 和元数据系统。它适合复用 `CLR` 的对象模型、`GC` 和程序集生态，但仍然必须保持 family 边界清晰。

## 输入前提

进入 `CLR` 后端前，应当已经完成：

- 语义闭合（`nyar.language` AST→HIR→MIR）
- `nyar.analyzer` / `nyar.optimizer`
- 适配为中性 **`ExecutableModule`**（全称；禁止 `Exec` / `ExecModule`）
- `Partition` 与 `CLR` family 专属 lane（`nyar.emitter` CLR：`ExecutableModule`→typed MSIL）
- CLR 入口、程序集、元数据与宿主依赖的整理

正式路径不是 `body_source→MSIL` 或 type-name 特判直出。`nyar.vm.clr` 只消费产物，不依赖 language。

## Validate

`Validate` 阶段重点确认：

- 当前输入能否合法映射到 CLR 类型系统和 IL 约束
- 调用语义、尾调用、虚调用和入口方式是否满足 CLR family 契约
- 所需宿主能力是否已经通过 adaptor 或 family 输入明确表达

如果某项能力在 CLR 上没有稳定承载方式，必须编译期失败。

## Compile

`Compile` 阶段负责：

- 生成程序集、类型、方法体和元数据
- 将 family 输入翻译为 IL 与相关结构
- 准备编码和打包所需的目标产物

## Family 特性

- 可以利用 CLR GC 和托管对象模型
- 可以利用程序集、元数据和现成运行时工具链
- 适合生成 `.dll`、`.exe` 等托管交付物

## 交付物

典型交付物包括：

- `.dll`
- `.exe`
- 程序集清单与元数据
- 最终 `ArtifactSet`

## 风险边界

- 禁止让 CLR 专属元数据结构泄漏成公共编译模型
- 禁止把 CLR 能力当成所有后端都必须共享的基础设施
- 禁止在 IL 生成阶段兜底修补上游遗漏的语言语义
