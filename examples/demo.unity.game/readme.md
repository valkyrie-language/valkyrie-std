# `demo.unity.game`

Unity Mono 构建流示例（`publish: unity-player`）。

## 五步复现

1. 在仓库根构建 `legion`（或使用已安装的 `legion` CLI）
2. 安装可选工具 `legion-unity`（或确保与 `legion` 同目录已构建）
3. 于本目录执行：`legion-unity build`（或 `legion unity build` 若已转发）
4. 确认生成 `build/unity/msil/demo.unity.game.dll` 与 `valkyrie-export.json`
5. 用 Unity 打开 `unity/` 子工程（`Packages/manifest.json` 已通过 **UPM Git** 引用 `com.valkyrie.unity`）
6. `legion-unity sync` 将游戏 MSIL 同步到 `Assets/Valkyrie/Plugins`，进入 Play Mode，Console 应出现 `demo.unity.game boot`

## 目标

- planner 隐式注入 `unity.engine.sdk`
- 使用 `std` 统一入口（`std.console`、`std.net` 等）
- `legion build` 输出 MSIL 并导出到 `build/unity/msil`
- `com.valkyrie.unity` 经 Git URL 由 Unity Package Manager 拉取（DLL-only，无 C# 插件源码）

## 构建流

```text
legion unity build
  → dist/clr_microsoft_unknown_managed/demo.unity.game.dll
  → build/unity/msil/ + valkyrie-export.json
legion unity sync
  → Assets/Valkyrie/Plugins/
Play Mode → V main 入口
```

## 配置要点

- `build_plugin.kind` = `unity-project-export`
- `build_plugin.input_directory` = `build/unity/msil`
- `com.valkyrie.unity` = `https://github.com/valkyrie-lang/valkyrie.unity.git#0.1.0`（UPM Git，非 submodule）
- 通常**不需要**在 `dependencies` 里手写 `unity.engine.sdk`

## 文档

详见 [Unity 平台文档](../../projects/asgard/documentation/pages/zh-hans/platforms/unity.md)。
