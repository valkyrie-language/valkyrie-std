# Valkyrie 维护者文档

## 先读什么

如果你要理解 `valkyrie.v` 的长期架构，建议按下面顺序阅读：

1. [架构详解](../developer/architecture.md)
2. [编译管线逐阶段详解](compilation.md)
3. [目标家族契约](target-family-contract.md)
4. [后端概览](backends/index.md)

## 编译主线

```mermaid
flowchart LR
    Source[Source]
    Parse[Parse]
    Meta[Meta]
    Semantics[Semantics]
    HIR[HIR]
    MIR[MIR]
    Optimize[Optimize]
    Partition[Partition]
    Lane[Target Lowering Lane]
    BackendInput[Backend Input]
    Validate[Validate]
    BackendCompile[Backend Compile]
    Encode[Encode]
    Package[Package]
    ArtifactSet[ArtifactSet]

    Source --> Parse --> Meta --> Semantics --> HIR --> MIR --> Optimize --> Partition --> Lane --> BackendInput --> Validate --> BackendCompile --> Encode --> Package --> ArtifactSet

    classDef phase fill:#f6f9fc,stroke:#8a9aad,stroke-width:1.2px,color:#1f2937;
    classDef boundary fill:#fff8e8,stroke:#d6a93d,stroke-width:1.2px,color:#5c4400;
    classDef delivery fill:#f3fbf6,stroke:#7fb77e,stroke-width:1.2px,color:#1f5130;

    class Source,Parse,Meta,Semantics,HIR,MIR,Optimize phase;
    class Partition,Validate boundary;
    class Lane,BackendInput,BackendCompile,Encode,Package,ArtifactSet delivery;
```

核心约束：

- `Parse -> Partition` 是所有 target 共享的语义主线。
- target 分叉从 `Partition` 开始，而不是从后端内部偷偷开始。
- 后端必须先 `validate` 再 `compile`。
- 不允许重新长出统一大 `IR` 或统一大 backend。

## 阅读路径

### 路径 A：理解整体架构

- [编译管线逐阶段详解](compilation.md)
- [目标家族契约](target-family-contract.md)
- [Canonical Target 规范](../developer/target-triples.md)

### 路径 B：理解语言语义如何落入主线

- [类型检查](type-checker.md)
- [HIR 类型](hir-types.md)
- [模式匹配](pattern-case.md)
- [多文件编译](multi-file.md)

### 路径 C：理解目标分流与后端

- [后端概览](backends/index.md)
- [CLR 后端](backends/clr.md)
- [JVM 后端](backends/jvm.md)
- [WASM 后端](backends/wasm.md)
- [Native 后端](backends/native.md)

## 分层约束

| 层级 | 负责什么 | 不负责什么 |
|:---|:---|:---|
| `Semantics` | 名称、类型、语言事实闭合 | 目标 ABI、宿主包装 |
| `HIR/MIR` | 语言语义与中层分析 | 文件格式、sidecar |
| `Partition/Lane` | target family 分流与承接 | 语言级 resolve |
| `Backend` | 指令选择、布局、metadata | 语义补洞 |
| `Encode/Package` | 二进制编码与交付 | 前端语义 |

## 当前长期方向

- 统一语义主线
- target family 分流
- family 专用 `Backend Input`
- 后端 `validate + compile`
- 统一 `ArtifactSet` 交付
