# 实验性探测脚本

本目录脚本**不计入 CLR 发布门**，也**不能替代** [`bootstrap-clr.mjs`](../bootstrap-clr.mjs)。

| 脚本 | 用途 |
|------|------|
| `nyar-determinism-probe.mjs` | 同一 seed 对同一源码编译两次，仅测量 Nyar 产物确定性 |
| `jvm-backend-probe.mjs` | JVM 后端实验性排查 |
| `wasm-backend-probe.mjs` | WASM 后端实验性排查 |

真自举验收请使用：

- `node scripts/bootstrap-clr.mjs` — CLR 轨 L2（NuGet 发布门）
- `node scripts/bootstrap-node.mjs` — **Node 轨 L2**（**npm / JSR 发布门**）
- `node scripts/bootstrap-smoke-clr.mjs` — CLR smoke 切片（非完整 L2）
