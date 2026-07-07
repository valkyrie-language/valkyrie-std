# legion.tools 文档

`legion.tools` 是用 Valkyrie 重写的 `legion` CLI 与编译器前端，也是 **L2 编译器自举** 的验收目标。

## 核心契约

- [bootstrap-contract.md](./bootstrap-contract.md) — CLR / Node 双轨自举、假自举边界、npm/JSR 发布与 `legions/legion` 依赖约束

## 验收命令

```bash
# CLR 轨（NuGet / CI 发布门）
node scripts/bootstrap-clr.mjs

# Node 轨（npm / JSR 发布门）
node scripts/bootstrap-node.mjs

# CLR smoke 切片（非完整 L2）
node scripts/bootstrap-smoke-clr.mjs
```
