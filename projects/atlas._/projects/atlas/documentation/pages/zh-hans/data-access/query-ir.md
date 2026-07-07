# Query IR

## 什么是 Query IR

**Query IR** 是 Atlas 数据访问里，查询进入执行与静态分析之前的**查询语义表示**。应用默认用 Hermes 写 query，也可以写 SQL；两条入口都归一到 Query IR，再交给：

- [schema 静态 query 检查](schema-static-query-check.md)（对照最新目标 schema）；
- 查询执行（得到结果行）；
- 在需要时做 **SQL 物化**（得到方言 SQL 字符串，供升级计划、显式 SQL 后端、调试等）。

「IR」只是便于理解的说法；**nyar 里没有 god IR**。Query IR 不是万能中间层，更不是「先变成 SQL 再执行」的必经神器。

## 入口与出口

```text
Hermes query（默认）  ──►  Query IR  ──►  静态检查 ──►  执行（结果行）
SQL 文本（可选）      ──►  Query IR  ──┘         │
                                                  │（仅当需要 SQL 文本）
                                                  ▼
                                            SQL 物化（方言字符串）
```

| 方向 | 内容 |
|------|------|
| **进** | Hermes 查询 AST / 文本，或 SQL 文本（解析进同一查询语义） |
| **出（热路径）** | 可执行的查询计划 / 驱动调用 → 结果行 |
| **出（物化）** | MySQL / PostgreSQL / SQLite 等方言的 SQL 字符串 |

Schema 真源始终是 Hermes 目标 schema；Query IR 描述的是「这次要问什么」，不是「库应该长什么样」。库形状由 schema + [UpgradePlan](upgrade-plan.md) 负责。

## 它承载什么语义

Query IR 至少要能表达（随语言能力扩展，不限于今日 `std-data` 竖切）：

- **读**：投影列、来源模型（表/实体）、过滤、排序、限制条数；
- **与 schema 的挂钩**：引用的是哪些 `storage` / `model` / 字段，供静态检查核对；
- **字面量与参数**：常量过滤、绑定参数占位（具体参数协议可演进）；
- **写路径（演进）**：insert / update / delete 等与模型字段对齐的变更语义——仍先对最新 schema 做静态检查，再执行或物化。

DDL（建表、改列）不属于日常 query 热路径；结构变更走目标 schema 与 UpgradePlan。把「建表语句」偶发投进物化打印机，是工具/演示用途，不要和线上 query 执行混为一谈。

## Hermes 默认、SQL 可选

| | Hermes | SQL |
|--|--------|-----|
| 地位 | 默认 query 语言，且 schema DSL 同源 | 二等可选路径 |
| 进 Query IR | 解析 Hermes query → 查询语义 | 解析 SQL → 同一套查询语义（能映射的子集） |
| 静态检查 | 必须过，依据最新 schema | 进入 Query IR 后同样必须过，不能「是 SQL 就免检」 |
| 物化 | 需要字符串时再生成方言 SQL | 已是 SQL 时，物化可能接近原样或按方言规范化 |

Hermes **可以**生成 SQL，不表示执行必须先生成 SQL。原生/驱动若能直接吃 Query IR 或 Hermes 语义，热路径不必经过字符串。

## 与 SQL 物化的边界

**SQL 物化**：把 Query IR（或 schema diff 步骤）打成某个方言的 SQL **文本**。

- UpgradePlan 常物化为可审阅、可有限编辑的 SQL 步骤；
- 显式要求「就是要这段 SQL」时走物化；
- 调试、日志、跨工具粘贴时走物化。

物化成功只说明「打印机能吐出字符串」，**不**代替 schema 静态 query 检查，也**不**定义 Query IR 的全部语义。`std-data` 里历史名 `QueryIr` / `render_ir` 属于物化辅助：打印 SQL，不等于 Query IR 规范本身。

## 错误心智

`Hermes → 某个万能中立层 → 先打成 SQL 字符串 → 再当查询执行`

问题在于：

1. 把执行绑死在字符串 SQL，方言与转义细节泄漏进热路径；
2. 暗示存在贯通 schema、query、DDL、打印的 god IR；
3. 静态检查若只在 SQL 字符串上做，难与 Hermes 目标 SoT 对齐，也难做结构化诊断。

正确顺序：query → Query IR →（检查）→ 执行；仅在需要文本时再物化。

## 和绑定、检查、升级的关系

| 构件 | 和 Query IR 的关系 |
|------|-------------------|
| 最新 Hermes schema | SoT；检查与 `RegenBindings` 都认它 |
| schema 静态 query 检查 | 对进入 Query IR 的 query 做合入门禁 |
| RegenBindings | 生成应用侧类型/仓库接口；query 结果形状应与之相容 |
| UpgradePlan | 改的是库结构；不改 Query IR 定义。结构对齐后，已通过检查的 query 才有资格在该环境执行 |

## 实现现状（`std-data`）

- `hermes`：`.hermes` / `.her` 子集解析与 AST（走向 Query IR）。
- `sql`：方言 AST 与打印机，服务 SQL 物化。
- 完整 Query IR 规范、执行引擎、全量静态检查仍为 Atlas 数据访问的规划能力；竖切用于钉住「查询语义 vs 物化字符串」的边界。
