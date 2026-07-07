# Schema Upgrade Plan

## 什么是 UpgradePlan

**UpgradePlan** 是针对**某一份具体数据库**的一次性结构升级方案：比较「仓库里的目标 Hermes schema」与「这台库当前的 schema」，算出差距，生成可审阅、可**有限修改**的执行步骤，确认后 **Apply once**。

它回答的是运维问题：「**这一台库，现在长这样，要变成目标 schema，该执行什么？**」

不是 migrations 文件链，也不是版本表回放。方言 SQL（若采用）来自 Hermes / [Query IR](query-ir.md) 路径上的 **SQL 物化**，面向 MySQL / PostgreSQL / SQLite 等。

## 流程

```text
目标 Hermes schema          当前库上的 schema
（仓库 SoT，最新）            （实测 / 导出 / 内省）
        │                         │
        └────────────┬────────────┘
                     ▼
                SchemaDiff
           （结构化差异：增删改列/表/约束…）
                     ▼
                UpgradePlan
           （有序步骤；常物化为方言 SQL 或混合步骤）
                     ▼
           用户有限修改计划（可选）
                     ▼
                Apply once
           （对这一台库执行该计划）
                     ▼
           （应用侧）RegenBindings 已按目标 schema 对齐
```

日常只改模型、库已经与目标一致时：改目标 schema → `RegenBindings` + [schema 静态 query 检查](schema-static-query-check.md) 即可，**不必**走 Upgrade。

## 各阶段做什么

### SchemaDiff

输入两端都是 schema 形状，不是 migration 版本号。

- **目标**：仓库内最新 Hermes schema（唯一 SoT）；
- **当前**：从该环境库内省或导出的实际形状（含人手热修过的现实）。

输出结构化差异，例如：缺表、缺列、类型变更、可空变更、约束增删、索引差异等。同一目标 schema，空库、落后很远的库、被热修过的库，diff **不同**——这是特性，不是缺陷。

### UpgradePlan

把 diff 编成**这一次**可执行的步骤序列。常见物化形态是方言 SQL；也可以是「SQL + 必要的数据回填说明」等混合步骤，只要人能审、工具能跑。

计划是 **派生物**：目标 schema 变了，应重新 diff / 重新生成计划，而不是把旧计划当第二真源长期维护。

### 有限修改

允许人在 Apply 前调整计划，例如：

- 大表改型拆成多步、加锁策略或维护窗口说明；
- 删列前增加数据导出/回填步骤；
- 跳过已知等价、仅风格差异的噪声变更；
- 修正生成器在特定方言上的不当默认。

「有限」意味着：不能改到与目标 schema 矛盾（例如计划里丢掉目标仍要求存在的列，却声称升级完成）。修改的是**抵达目标的路径**，不是偷偷改目标本身。目标仍以仓库 Hermes schema 为准；若目标错了，应改 schema 再重生计划与绑定。

### Apply once

对**这一台库**执行当前这份计划。成功后，该库形状应与目标 schema 一致（在 diff 语义下）。

- 不写入「再回放一遍历史脚本」的义务；
- 下一次环境落后或目标又变，再做新的 diff → 新计划 → 再一次 Apply；
- 失败时修的是**这一次计划**或中断后的库状态，而不是去改一年前某条不可逆 migration 的语义。

## 为何用 UpgradePlan，而不是 migrations 回放

| | UpgradePlan | migrations 回放 |
|--|-------------|-----------------|
| 真源 | 目标 schema（状态） | 文件链 + 版本表（过程） |
| 对谁生成 | 这一台库的当前形状 | 假定全员同序前进 |
| 人能否改路径 | 有限修改本次计划 | 已回放脚本原则上不可改 |
| 与热修库 | 当前现实进 diff | 版本号绿 ≠ 形状对 |
| 与多分支 | 不依赖全局脚本序号 | 序号与合并易碎 |

migrations 回放的失效机制见 [migrations 回放](migrations-antipattern.md)。UpgradePlan 把「真正管用的那次手写修复」收成正规工作流：看清差距 → 审计划 → 一次性落地。

## 和查询、绑定怎么分工

| 构件 | 职责 |
|------|------|
| 目标 Hermes schema | 结构 SoT |
| RegenBindings | 按目标生成应用侧绑定 |
| schema 静态 query 检查 | 合入前卡 query，依据仍是目标 schema |
| Query IR | 查询执行语义；升级不改它的定义 |
| UpgradePlan | 只负责把**库**拉到目标形状 |

库落后时：**不要**放宽静态检查去迁就旧库；应升级库。否则主线会累积「只对旧库合法」的 query，与过程冒充状态同类。

## 空库、多环境、多租户

- **空库**：diff 接近「全量创建」；计划往往是一整套建表/约束，仍是一次性 Apply，不是回放历史版本故事。
- **多环境**：每个环境各自内省 → 各自计划；禁止假设「跑过同一串版本号就等价」。
- **多租户 / 分片**：按库实例分别出计划；允许进度不同，只要每个实例最终对齐同一目标 SoT。

## 计划中的契约名（planned）

| 名称 | 角色 |
|------|------|
| `SchemaDiff` | 当前 schema vs 目标 schema → 结构化差异 |
| `UpgradePlan` | 由 diff 生成的可有限编辑执行计划 |
| `Apply` | 对指定连接一次性执行计划 |
| `RegenBindings` | 目标 schema → 应用侧绑定（常与升级并行或紧随其后） |

工具入口预期落在 `atlas.tools`；实现未完成前，上述名称是文档契约，不是已发布 CLI 保证。

## 明确不在范围

- 以 migrations 文件链 + 版本表回放为默认升级模型；
- 把 UpgradePlan 历史当成新的 SoT 长期堆积；
- 在 UpgradePlan 里偷偷修改目标 schema 语义（目标变更走 Hermes 源文件）；
- 用 UpgradePlan 代替 query 静态检查或绑定生成。
