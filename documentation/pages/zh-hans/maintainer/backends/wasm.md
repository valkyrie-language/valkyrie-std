# WASM 后端

## 定位

`WASM` family 面向 WebAssembly 生态，但它本身不是单一目标。浏览器、`Node`、`WASI` 等宿主差异必须在 family 内部分层处理，不能重新长成一个跨所有 target 的统一大后端。

## 同构管线（Valkyrie）

```
ExecutableModule
  → typed WasmExecutableOpcode CFG   (`nyar.emitter.wasm`)
  → .wasm bytes                      (`std.data.binary.wasm` encode)
  → host shell                       (`host/js_glue` | `host/wasi_cm`)
```

入口只接受 `ExecutableModule`；禁止 `body_source` 旁路。

## 字符串编码边界（硬）

| 层 | 约定 |
|:---|:---|
| 语言 / IR `utf8` / `LoadConstString.utf8_source` | UTF-8（std 按 Unicode scalar） |
| JS 宿主 `string` 存储 | UTF-16 code unit |
| `env.utf8_*`（JS glue） | 按 **scalar** 索引（`[...s]`），禁止裸 `.length` / `.substring` |
| WASI CM 路径 / WIT id | UTF-8 **字节** |

## 输入前提

进入 `WASM` 后端前，应当已经完成：

- 语义闭合
- `Partition`
- `WASM` family 专属 lowering
- 宿主能力与导入需求的显式标注

`WASM` 后端只接收自己的 `Backend Input`，而不是重新消费通用兼容壳。

## Validate

`Validate` 阶段重点确认：

- 当前输入是否符合 `wasm` 执行模型
- 所需能力是否属于 `browser`、`node` 或 `wasi` 等合法宿主
- `std.adaptor.*` 是否已经把宿主能力边界表达清楚
- 受限环境下不允许的能力是否已经被提前拒绝

例如，`std.dom` 这类能力可以面向浏览器宿主开放，但不能默认对纯 `wasi` 输入静默成立。

## Compile

`Compile` 阶段负责：

- 生成 `WASM` 模块结构（type / import / function / export / code）
- 安排函数、表、内存、导入导出和必要的运行时桥接点
- 产出后续编码与打包所需的模块数据（`std.data.binary.wasm`）

## 宿主分层

同属 `WASM` family 的不同宿主应当继续区分：

- `wasm-browser`
- `wasm-node`（JS glue：`env.const_utf8` + `env.utf8_*`）
- `wasm-wasi`（wasip2 / wasip3 CM；禁止 `wasi_snapshot_preview1`）

这些差异主要体现在：

- 可用标准库 adaptor
- 导入来源
- 入口包装
- 打包产物

## 交付物

典型交付物包括：

- `.wasm`
- 宿主胶水文件或启动脚本
- import / export 清单
- 最终 `ArtifactSet`

## 风险边界

- 禁止把浏览器、`Node`、`WASI` 细节直接塞回公共语义层
- 禁止把宿主桥接逻辑伪装成统一标准库语义
- 禁止在 emit 末端临时判断宿主能力并偷偷降级
- 禁止把 `Utf8Text` 与宿主 UTF-16 `string` 的 length/slice 抹平
