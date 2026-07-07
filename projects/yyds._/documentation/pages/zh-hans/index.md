# YY 数据库生态

`yyds._` 是数据库生态总 workspace，内部至少拆成 `yykv`、`yydb`、`yyds` 三条主线。

## 核心分层

### `yykv`

- 共享底层存储内核
- 为 `yydb` 与 `yyds` 提供公共存储能力

### `yydb`

- 单机数据库
- 产品定位接近 `sqlite + redis`
- 适合嵌入式、本地优先、sidecar 与缓存场景

### `yyds`

- 分布式数据库
- 面向集群、复制、调度与多节点一致性
- 协议层兼容 `mysql / pgsql / redis`

## 边界约束

- `yydb` 可作为 `yyds` 的 sidecar 高速缓存
- `yydb` 与 `yyds` 可以做升降级、迁移、复制与数据搬运
- `yydb` 不被视为 `yyds` 的一部分
- `yydb` 与 `yyds` 必须物理拆包，避免退化成单体数据库

## 与 Atlas 的边界

**yyds 与 Atlas 无关。** 本生态是独立数据库产品线（`yykv` / `yydb` / `yyds`），不是 Atlas 的默认数据平面，也不承担 Atlas 的 Hermes（schema 真源 + 默认 query；SQL 亦可）/ `RegenBindings` / 一次性升级约定。Atlas 数据访问见其自身文档；此处不交叉绑定。

> 注意：上文「`yydb` / `yyds` 升降级」指产品形态与部署角色的升降，与 Atlas 无关。

## 计划中的子包

- `projects/yykv`
- `projects/yydb`
- `projects/yyds`
- `projects/yyds.protocol.mysql`
- `projects/yyds.protocol.pgsql`
- `projects/yyds.protocol.redis`
- `projects/yyds.tools`
