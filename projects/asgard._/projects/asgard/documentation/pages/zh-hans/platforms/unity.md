# Unity Player（Mono / MSIL）

Valkyrie 的 Unity 首版目标走 **Mono + MSIL**：在 V 项目里写游戏逻辑，`legion build` 生成托管 DLL，再由 **Valkyrie Unity Editor Package** 导入 Unity 工程并在 Play Mode 调用 V `main` 入口。

**边界（当前阶段）**：

- 支持 `publish: ["unity-player"]` + `clr-microsoft-unknown-managed`
- **不做** IL2CPP（`clr-unity-windows-il2cpp` 留 Phase 2）
- UI 不走 Asgard AWSL；Unity 侧仅承载 **V 游戏逻辑脚本**
- 生命周期首版由插件生成 `ValkyrieBootstrap` 薄壳，不在 V 源码手写 `MonoBehaviour`
- Unity 插件包 `valkyrie.unity` 为 **DLL-only UPM**（无 C# 源码）；由 V 项目 `valkyrie.v/projects/unity._/projects/valkyrie.unity` 编译并按 `[export(unity.runtime|unity.editor)]` 分区落盘（SDK 包在同级 `unity.engine.sdk`）

## `[export(..)]` 与 CLR 分区

| 标注 | 含义 |
|:---|:---|
| `[export]` | 默认分区 `default`，进入 `ExportContract` |
| `[export(unity.runtime)]` | Runtime 分区 DLL（`{project}__unity.runtime.dll`） |
| `[export(unity.editor)]` | Editor 分区 DLL（`{project}__unity.editor.dll`） |
| `[main]` | 游戏入口（`EntryContract`），与 export 独立 |

无 `[export]` 的 `micro` 在 CLR 下为模块内部符号，不进入导出清单。

`valkyrie.unity` 示例：

```von
[export(unity.runtime)]
micro run(assembly_file: utf8, entry_method: utf8): unit { ... }

[export(unity.editor)]
micro import_msil(project_root: utf8): bool { ... }
```

`build_plugin.export_routes` 将分区 DLL 同步到 Unity 目录：

```von
export_routes: {
    "unity.runtime": "../../../../valkyrie.unity/Runtime",
    "unity.editor": "../../../../valkyrie.unity/Editor",
    "default": "Assets/Valkyrie/Plugins"
}
```

| | 微信小游戏 | Unity Mono |
|:---|:---|:---|
| `publish` | `mini-game` | `unity-player` |
| SDK | `tencent.wechat.sdk` | `unity.engine.sdk` |
| 产物 | WASM | MSIL DLL |
| 打包 | `asgard pack` | Unity Editor Package 导入 `Assets/Valkyrie/Plugins` |
| 运行 | 微信运行时 | Unity Mono `Assembly.Load` + 反射 |

## `legion.von` 配置

```von
{
    name: "demo.unity.game",
    dependencies: {
        "std": { version: "workspace" }
    },
    build: [
        {
            target: "clr-microsoft-unknown-managed",
            publish: ["unity-player"],
            msil: true
        }
    ],
    build_plugin: {
        kind: "unity-project-export",
        sdk: "unity.engine.sdk",
        mode: "auto",
        input_directory: "build/unity/msil",
        output_directory: "build/unity/project",
        next_step: "Unity 构建器自动写入 Unity 工程并触发 Unity 编译"
    }
}
```

### `build_plugin` 字段

| 字段 | 说明 |
|:---|:---|
| `kind` | 固定 `unity-project-export` |
| `input_directory` | MSIL 导出目录（默认 `build/unity/msil`） |
| `output_directory` | Unity 工程侧指针目录（默认 `build/unity/project`） |
| `sdk` | 关联平台 SDK（`unity.engine.sdk`） |
| `mode` | 预留：`auto` / 手动触发 |
| `next_step` | 文档提示，不参与编译 |

`legion build` 完成后会写入：

- `build/unity/msil/{name}.dll` — 主游戏程序集
- `build/unity/msil/deps/*.dll` — 同目录下其它 DLL 依赖
- `build/unity/msil/valkyrie-export.json` — Editor 插件消费清单

`valkyrie-export.json` v2 示例（多分区插件）：

```json
{
  "version": 2,
  "entry": { "assembly": "demo.unity.game.dll", "method": "main" },
  "artifacts": [
    { "assembly": "valkyrie.unity__unity.runtime.dll", "partition": "unity.runtime", "role": "plugin-runtime" },
    { "assembly": "valkyrie.unity__unity.editor.dll", "partition": "unity.editor", "role": "plugin-editor" }
  ],
  "entry_assembly": "demo.unity.game.dll",
  "entry_method": "main",
  "target": "clr-microsoft-unknown-managed",
  "publish": ["unity-player"],
  "sdk_version": "0.1.0"
}
```

v1 清单（无 `artifacts`）仍向后兼容。

## 构建流程

```text
V 源码（demo.unity.game）
  → legion unity build   # 或 legion build（均会导出 MSIL）
  → build/unity/msil/demo.unity.game.dll + valkyrie-export.json
Unity 2022 LTS 打开 examples/demo.unity.game/unity
  → 在 Unity `Packages/manifest.json` 添加 Git 依赖：`com.valkyrie.unity` → `https://github.com/valkyrie-lang/valkyrie.unity.git#0.1.0`
  → `legion-unity build` @ `valkyrie.unity` 生成分区插件 DLL 并推送到发布仓
  → `legion unity sync`（CLI / CI 按 `export_routes` 同步 DLL）
  → Play Mode：Console 输出 demo.unity.game boot
```

### 命令行（可选：`legion-unity`）

Unity 目标使用**独立伴随工具** `legion-unity`，默认不随 `legion` 安装。仅 Unity 游戏项目需要：

```bash
cargo install --path valkyrie.rs/projects/legion-unity
legion-unity build
legion-unity sync --unity-project ./unity
```

已安装时，`legion unity …` 会自动转发到 `legion-unity`（例如 `legion unity build` ≡ `legion-unity build`）。

| 命令 | 作用 |
|:---|:---|
| `legion-unity build` | 编译 + 导出 MSIL |
| `legion-unity export` | 仅从 `dist/` 重新导出 |
| `legion-unity sync` | 复制 MSIL 到 Unity `Assets/Valkyrie/Plugins` |
| `legion-unity status` | 查看 `valkyrie-export.json` |

### Editor 插件（二进制 UPM · Git 依赖）

**`valkyrie.unity` 为独立 Git 发布仓**（仅 `package.json` + `Runtime/`、`Editor/` 下 DLL，建议 Git LFS）。V 源码在 `valkyrie.v/projects/unity._/projects/valkyrie.unity`。

Unity 工程通过 **Package Manager Git URL** 引用，**不用 submodule、不用 `file:`**（本地联调未发布包时可临时改回 `file:`）：

```json
{
  "dependencies": {
    "com.valkyrie.unity": "https://github.com/valkyrie-lang/valkyrie.unity.git#0.1.0"
  }
}
```

发布流程：`legion build` → `legion-unity export` 写入发布仓 → `git tag 0.1.0` → push；Unity 侧刷新 Packages 即可拿到新 DLL。

### CI（batchmode）

```bash
Unity -batchmode -quit -projectPath path/to/unity \
  -executeMethod Valkyrie.Unity.Editor.ValkyrieBuildMenu.ImportMsil
```

（需在 Editor 脚本中暴露静态入口；本地开发优先使用菜单。）

## Host Provider 选择

`publish: ["unity-player"]` 时 planner 会：

1. 隐式注入 `unity.engine.sdk`
2. 对 `std::console::write_line`、`std::net::get`、`std::io::read_file_text` 等契约，**优先选用** `unity.engine.sdk` 而非 `std.adaptor.clr`

## 验收清单

| 检查项 | 命令 / 操作 |
|:---|:---|
| Planner 注入 | `cargo test -p legion unity_player` |
| MSIL 编译 | `legion build` @ `demo.unity.game` |
| 导出清单 | 存在 `build/unity/msil/valkyrie-export.json` |
| Editor 导入 | Unity Play → Console 见 boot 日志 |
| 存储 | `PlayerPrefs` profile 键读写 |

## 后续迭代

- IL2CPP 导出钩子
- `CanonicalVendor::unity` Rust 解析
- Asgard UI → UGUI 渲染方案
- Netcode / Addressables 等高级绑定
