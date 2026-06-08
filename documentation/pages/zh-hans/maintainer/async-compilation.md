# async / await 编译

## 概述

Valkyrie 的异步编程通过 `future<T>` 类型和后缀表达式（`.await` / `.awake` / `.block`）实现。编译器将这些高级语义降级为协程状态机和代数效应调用。

## 在管线中的位置

```
AST
  │
  ▼
TypeChecker
  ├── 验证 .await / .awake / .block 的使用上下文
  ├── 检查 future<T> 类型流
  └── 验证 .block 不在禁止的上下文中使用（如 on_update）

SemanticModel

HirBuilder
  ├── .await → HirAwaitNode
  ├── .awake → HirAwakeNode
  └── .block → HirBlockNode

HirToMirLowerer
  ├── .await → perform AsyncWait(future)
  ├── .awake → perform AsyncSpawn(future)
  └── .block → perform AsyncBlock(future)
        │
        ▼
  IKunCatch / IKunResume（通过代数效应框架）

IkunTreeToLirLowerer
  ├── 协程状态机生成
  └── 调度器 API 调用
```

## 三种后缀的编译

### .await

**语义**：挂起当前协程直到 future 完成，返回 `T`。

**类型规则**：`future<T>.await → T`

**编译流程**：

1. HirBuilder 将 `.await` 编码为 `HirAwaitNode(futureExpr)`
2. HirToMirLowerer 展开为 `perform AsyncWait(futureExpr)`
3. 此 `perform` 被挂起的协程注册到调度器
4. future 完成后，调度器通过 `resume` 恢复协程
5. 编译器在包含 `.await` 的函数上生成协程状态机

**状态机生成**：

```
函数 f 包含 .await:
  → 编译器将 f 拆分为多个基本块
  → 每个 .await 处插入挂起点（suspend point）
  → 生成状态枚举（每个挂起点一个状态）
  → 恢复时从对应状态继续执行
```

### .awake

**语义**：触发异步操作后立即返回 `void`，不等待结果。

**类型规则**：`future<T>.awake → void`

**编译流程**：

1. HirToMirLowerer 展开为 `perform AsyncSpawn(futureExpr)`
2. `AsyncSpawn` 将 future 提交到调度器，不注册回调
3. 调用者继续执行
4. 无状态机生成，无挂起点

### .block

**语义**：阻塞当前线程直到 future 完成，返回 `T`。

**类型规则**：`future<T>.block → T`

**编译流程**：

1. HirToMirLowerer 展开为 `perform AsyncBlock(futureExpr)`
2. 生成阻塞等待循环（在允许的上下文中）
3. 编译器在 TypeChecker 阶段验证 `.block` 仅用于同步函数中

## 状态机生成细节

当函数包含 `.await` 时，编译器执行以下变换：

### 状态枚举

```csharp
// 为每个函数生成
enum F_State {
    Start,
    AfterAwait1,
    AfterAwait2,
    // ...
    Done
}
```

### 局部变量提升

所有在 `.await` 前后都存活的局部变量被提升到状态机结构体中：

```csharp
struct F_Frame {
    state: F_State,
    // 跨挂起点存活的局部变量
    var_x: i32,
    var_y: string,
    // future 句柄
    future_1: FutureHandle,
}
```

### 控制流重构

原始函数体被重写为 `loop + match state` 结构：

```text
loop {
    match state {
        Start → {
            // 初始化代码
            state = AfterAwait1;
            return AsyncAction::Suspend(future_handle_1);
        }
        AfterAwait1 → {
            let result = resume_value;
            // 后续代码
            state = Done;
            return AsyncAction::Complete(result);
        }
    }
}
```

## 后端处理

### NyarVM 后端

NyarVM 运行时直接支持协程原语（`CoroutineYield` / `CoroutineResume` / `CoroutineSpawn`）。`.await` 编译为 `CoroutineYield` + `CoroutineResume` 序列，由 NyarVM 调度器驱动。

### WASM 后端

编译为 WASM 时，异步操作通过 JS 桥接层实现。`.await` 被编译为对 `voa-runtime.js` 中调度器的调用，使用 `Promise` 作为底层异步原语。

### JVM 后端

编译为 JVM 字节码时，协程状态机映射为 `class` 实例。`.await` 使用项目 Loom 的虚拟线程（Virtual Thread）或传统线程池。

## 上下文检查

编译器在 TypeChecker 阶段对 `.block` 进行上下文检查：

| 上下文 | `.block` 是否允许 |
|:---|:---|
| `system` 生命周期回调 | 禁止（阻塞主线程导致卡顿） |
| `micro`（非 system） | 允许 |
| `on_load` / `on_unload` | 允许但产生警告 |
| `on_update` | 禁止 |

禁止上下文中使用 `.block` 产生编译错误。