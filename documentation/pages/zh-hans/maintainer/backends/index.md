# 后端概览

这里的“后端”不是一条统一的大总线，也不是所有 target 共用的一份低层 `IR`。

在 `valkyrie.v` 的长期架构里，后端只负责各自 `target family` 的路线：消费本 family 的 `Backend Input`，先 `validate`，再 `compile`，最后交付 `ArtifactSet`。

## 在管线中的位置

```mermaid
flowchart LR
    Source[Source]
    Parse[Parse]
    Semantics[Semantics]
    HIR[HIR]
    MIR[MIR]
    Optimize[Optimize]
    Partition[Partition]
    Lane[Target Lowering Lane]
    BackendInput[Backend Input]
    Validate[Validate]
    Compile[Compile]
    Encode[Encode]
    Package[Package]
    ArtifactSet[ArtifactSet]

    Source --> Parse --> Semantics --> HIR --> MIR --> Optimize --> Partition --> Lane --> BackendInput --> Validate --> Compile --> Encode --> Package --> ArtifactSet

    classDef phase fill:#f6f9fc,stroke:#8a9aad,stroke-width:1.2px,color:#1f2937;
    classDef boundary fill:#fff8e8,stroke:#d6a93d,stroke-width:1.2px,color:#5c4400;
    classDef delivery fill:#f3fbf6,stroke:#7fb77e,stroke-width:1.2px,color:#1f5130;

    class Source,Parse,Semantics,HIR,MIR,Optimize phase;
    class Partition,Validate boundary;
    class Lane,BackendInput,Compile,Encode,Package,ArtifactSet delivery;
```

维护者需要特别记住：

- `Partition` 之前是共享语义主线
- `Partition` 之后必须按 family 分流
- 后端不再接收“所有 target 都能吃”的兼容壳

## 后端共同契约

所有 family 都必须满足以下规则：

- 只消费自己的 `Backend Input`
- 不重新解释语言语义
- `Validate` 必须先于 `Compile`
- 不支持的语义必须编译期硬失败
- 成功结果必须落到统一的 `ArtifactSet`

更完整的约束见 [target-family-contract.md](../target-family-contract.md)。

## Family 列表

| Family | 典型交付物 | 关注点 | 文档 |
|:---|:---|:---|:---|
| `NyarVM` | VM 可加载产物 | VM 专用对象模型、运行时契约 | [nyar-vm.md](nyar-vm.md) |
| `WASM` | `.wasm` / `.wasi` 及宿主配套文件 | 浏览器 / Node / WASI 宿主边界 | [wasm.md](wasm.md) |
| `JVM` | `.class` / `.jar` | ClassFile、栈机模型、JRE 约束；格式包为 `std.data.binary.class` / `std.data.binary.jar`（勿写 `binary.jvm`） | [jvm.md](jvm.md) |
| `CLR` | `.dll` / `.exe` | IL、元数据、CLR 类型系统 | [clr.md](clr.md) |
| `Native` | 对象文件 / 可执行文件 / 动态库 | 目标文件格式、ABI、链接与打包 | [native.md](native.md) |

`Native` 下面如果继续细分平台差异，应当体现在 `native-windows.md`、`native-linux.md`、`native-darwin.md` 这类子页里，而不是反向抬升成全局统一模型。

## 后端负责什么

- 验证该 family 是否支持当前 `Backend Input`
- 将 family 专属输入编译成目标代码或目标数据结构
- 编码目标格式，或准备进入目标格式编码阶段
- 生成打包和交付所需的产物集合

## 后端不负责什么

- 不负责补做 parser、name resolve、类型检查或 effect 闭合
- 不负责把所有 family 重新揉成同一套低层表示
- 不负责用 emit 逻辑兜底修补上游遗漏的语义事实
- 不负责让一个 target 的特殊需求污染全部公共结构

## 维护原则

当你新增 backend 或扩展某个 family 时，优先检查以下问题：

1. 是否要求公共层新增只对单一 family 有意义的字段。
2. 是否把宿主绑定、编码格式、入口包装混到同一个对象里。
3. 是否偷偷恢复了“统一后端输入接口”的设计。
4. 是否把本应在 `validate` 失败的问题推迟到 `compile` 或运行期。

只要其中任意一项答案是“是”，就说明系统又在向新的 `god ir` 或 `god object` 滑回去。
