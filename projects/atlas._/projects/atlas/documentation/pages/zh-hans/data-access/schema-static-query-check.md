# schema 静态 query 检查

## 什么是 schema 静态 query 检查

在**编译期 / 合入前**，用 **Hermes schema** 核对应用里的 **query**（默认 Hermes；SQL 亦可，进入同一套 Atlas [Query IR](query-ir.md) 语义后再查）是否仍然合法：引用的模型与字段是否存在、类型与空值是否相容、投影与过滤是否说得通。

- **检查对象**：query（及由其推导的绑定用法），不是「某次 migration 脚本写得对不对」。
- **检查依据**：仓库里的**目标 schema（SoT）**，也就是**最新**那份 Hermes schema。
- **检查时机**：构建与静态分析阶段报错；不指望第一次打到真实库才发现列不存在。

不做运行时探测，不读生产库的版本表，也不按 migrations 历史水位选一份「当时的 schema」来放行。

## 在流水线里站哪

```text
目标 Hermes schema（最新 SoT）
        │
        ├──────────────► RegenBindings（应用侧绑定）
        │
        └──────────────► schema 静态 query 检查
                              ▲
Hermes / SQL query ──► Query IR ─┘
                              │
                              ▼（通过）
                           执行 / 进一步物化 SQL（若需要）
```

需要方言 SQL 字符串时，是 Query IR / Hermes 的 **SQL 物化**；检查发生在 query 语义层，而不是「先打成 SQL 再当类型系统」。

## 具体查什么

### 名字与存在性

- `storage` / `model`（或等价表实体）是否在目标 schema 中声明；
- `select` / 过滤 / 排序 / 连接所引用的字段是否属于该模型；
- 改名、删除字段后，旧 query 必须在合入前失败，而不是带着死名字进仓库。

### 类型与空值

- 比较、赋值、聚合的操作数类型是否与字段类型相容（含 `option<T>` / 可空语义）；
- 非空字段是否被当成可空用、可空字段是否在未处理 `null` 时当非空用；
- 主键、唯一约束字段在 insert / upsert 类语义里是否满足「必给 / 可生成」的约定（与 schema 上 `@@` / `@` 等声明对齐）。

### 投影与形状

- 投影列集合是否都来自合法字段（或合法计算列，若语言支持）；
- query 结果形状是否与调用方绑定类型一致——绑定由最新 schema 经 `RegenBindings` 生成，query 检查与绑定生成必须认**同一份** SoT，否则「绑定是新的、query 按旧的过」会漏漏洞。

### 显式 SQL 路径

SQL 作为二等路径进入 Query IR 后，同样接受存在性与类型约束：不能因为「已经是 SQL 了」就绕过 schema。方言差异（MySQL / PostgreSQL / SQLite）属于物化与执行，不负责任意放宽「列是否存在于目标 schema」。

## 依据为什么必须是最新 schema

目标 schema 是唯一结构真源。静态 query 检查若不用最新，等于类型系统与代码生成各活各的：

| 错误依据 | 会发生什么 |
|----------|------------|
| migrations 链上某个历史版本 | 检查以为旧列名仍合法；`RegenBindings` 已按新名生成 → 绿构建、红运行，或反过来 |
| 环境 migration 版本表水位 | 把运维账本嵌进编译器；每个环境「合法 query」集合不同，合入失去统一标准 |
| 某次 UpgradePlan 的中间态 | 中间态只对那一次运维有意义，不是应用长期契约 |
| 「先按旧 schema 过，库升了再说」 | 旧 API 形状与新 SoT 分叉，债务进主线 |

不用最新，有病：不是文风问题，是双真源。库落后用 [UpgradePlan](upgrade-plan.md) 对齐；代码与 query 始终按最新目标卡死。

## 它不做什么

- **不**代替 SchemaDiff / UpgradePlan：不负责「这台库现在差哪些 DDL」。
- **不**在检查阶段连真实库做探测（那是部署/诊断，不是合入门禁）。
- **不**回放 migrations，也不根据版本表选择检查用的 schema 快照。
- **不**把「能物化出某种方言 SQL」当成类型正确：物化成功 ≠ 对目标 SoT 语义正确。

## 和环境落后怎么共存

预发或生产库还停在旧形状时：

1. **构建 / PR**：仍按最新目标 schema 做静态 query 检查与 `RegenBindings`；
2. **该环境**：用当前库 schema vs 目标 schema 出 UpgradePlan，有限编辑后一次性 Apply；
3. **Apply 之后**：库形状与目标一致，已通过检查的 query 才有资格在该环境执行。

把「库还没升」当成放宽静态检查的理由，等于允许主线累积「只对旧库合法」的 query，和 [migrations 回放](migrations-antipattern.md) 同一类过程冒充状态。

## 和 RegenBindings 的关系

| | schema 静态 query 检查 | RegenBindings |
|--|------------------------|---------------|
| 输入 | 最新 schema + query（→ Query IR） | 最新 schema |
| 输出 | 诊断 / 合入成败 | 应用侧数据绑定代码 |
| 共同前提 | 同一份目标 SoT | 同一份目标 SoT |

改 schema 后：先（或同时）重生绑定，再让所有 query 在新 SoT 下重新过检；只改一边，会留下「绑定新、query 旧」或相反的裂缝。
