# yyds._

`yyds._` 是数据库生态的顶层 workspace，不是单一产品。

## 组成

- `yykv`：共享底层存储内核
- `yydb`：单机数据库，定位接近 `sqlite + redis`
- `yyds`：分布式数据库

## 原则

- `yydb` 与 `yyds` 不是一个东西
- `yydb` 可以作为 `yyds` 的 sidecar 高速缓存
- `yydb` 和 `yyds` 可以升降级，但不能因此合并成一个包
- **与 Atlas 无关**：yyds 是独立数据库产品线，不是 Atlas ORM / 数据绑定平面；勿与 Atlas 的 Hermes（schema 真源 + 默认 query；SQL 亦可）→ RegenBindings / 一次性升级故事交叉绑定

## 计划中的子包

- `projects/yykv`
- `projects/yydb`
- `projects/yyds`
- `projects/yyds.protocol.mysql`
- `projects/yyds.protocol.pgsql`
- `projects/yyds.protocol.redis`
- `projects/yyds.tools`

## 当前状态

规划中，先完成 workspace 与文档骨架。

文档入口：[documentation/pages/zh-hans/index.md](documentation/pages/zh-hans/index.md)
