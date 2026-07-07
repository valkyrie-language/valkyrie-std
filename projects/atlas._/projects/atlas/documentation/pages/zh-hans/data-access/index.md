# 数据访问总览

Atlas **不内嵌**某一种 ORM 运行时；「故意不做 ORM」应理解为：**不做 migrations-first ORM**，而不是永远没有数据访问。

**Hermes**（C# 侧 Sonic/Hermes 同源；源文件常见 `.hermes` / `.her`）同时是：

- **Schema 真源（SoT）**：特殊 schema DSL，**不是** SQL migration 脚本，也**不是** yyds 专属方言
- **默认 query 执行语言**：应用侧查询默认写 Hermes；**SQL 亦可**（二等可选路径）

Hermes **可生成 SQL**（面向 **MySQL / PostgreSQL / SQLite** 等方言）。应用侧绑定由 **目标 Hermes schema** 经 codegen 重生；需要改库结构时走 **一次性升级**，不以 migrations 文件链为真相源。

对接库为常规 RDBMS：**MySQL / PostgreSQL / SQLite** 等。**yyds 是独立数据库生态，与 Atlas 数据绑定无关**。

## 立场（锁定）

1. **Hermes = schema 真源 + 默认 query 语言**：改目标 schema → **`RegenBindings`（codegen）**；查询默认 Hermes，**SQL 亦可**。
2. **反对 migrations 链作为协作真源**（EF Migrations / Flyway / `sqlx migrate` 那类）。论证见 [migrations 回放](migrations-antipattern.md)。
3. **升级已有库**：目标 schema vs 当前 schema → **UpgradePlan**（可物化为 SQL）→ 用户可有限修改 → **一次性 Apply**。见 [Upgrade Plan](upgrade-plan.md)。

与 `RouteInjector` / `WireInjector` 一致：**改源头，再生成**。

## 展开阅读

| 主题 | 文档 |
|------|------|
| Query IR | [query-ir.md](query-ir.md) |
| Schema Upgrade Plan | [upgrade-plan.md](upgrade-plan.md) |
| schema 静态 query 检查 | [schema-static-query-check.md](schema-static-query-check.md) |
| migrations 回放 | [migrations-antipattern.md](migrations-antipattern.md) |

## 计划中的契约（planned）

| 名称 | 角色 |
|------|------|
| `RegenBindings` | 由目标 Hermes schema 重新生成应用侧数据绑定 |
| `SchemaDiff` | 比较当前 schema 与目标 schema |
| `UpgradePlan` | 可有限编辑的执行计划；确认后一次性 Apply |

工具入口预期落在 `atlas.tools`。

## 明确不在范围

- migrations-first ORM / 以 migrations 链为协作真源
- 在 Atlas 内核硬绑某一种 ORM 运行时
- 把 yyds 当作 Atlas 的默认数据平面
- 排斥 SQL（SQL 是可选等价路径）
