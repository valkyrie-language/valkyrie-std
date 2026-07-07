# 编译器自举契约

L2 自举分 **CLR**（NuGet）与 **Node**（**npm / JSR**）两条并行轨，完整契约见：

**[projects/legion._/projects/legion.tools/documentation/pages/zh-hans/bootstrap-contract.md](../../../../projects/legion._/projects/legion.tools/documentation/pages/zh-hans/bootstrap-contract.md)**

| 轨 | 目标 | 验收 | 发布 |
|:---|:---|:---|:---|
| CLR | `clr` | `bootstrap-clr.mjs` | NuGet |
| Node | `node` | `bootstrap-node.mjs` | **npm**、**JSR** |

```bash
node scripts/bootstrap-clr.mjs
node scripts/bootstrap-node.mjs
```

npm / JSR 发布策略：[publishing-registries.md](../guides/publishing-registries.md)
