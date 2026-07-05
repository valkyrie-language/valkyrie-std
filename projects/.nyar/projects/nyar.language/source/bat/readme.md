# bat

`bat` 是 `nyar.language` 体系中的 `Windows Batch` 前端入口。

## 定位

- 面向 `cmd.exe` / `.bat` / `.cmd` 脚本的解析与前端分析
- 负责把批处理语义接入 `nyar` 元优化体系
- 作为 `Windows Batch` 到 `nyar` 公共语义层之间的前端桥接

## 适合承载什么

- 批处理脚本的语法解析与语法树
- 标签、跳转、环境变量、命令调用等前端语义分析
- 批处理脚本的前端诊断与约束检查
- 把 `bat` 语言能力映射到 `nyar` 可优化语义对象的前端逻辑

## 不适合承载什么

- `nyar` 核心 `OA / EGraph / PE` 基础设施本身
- 其他语言前端共享的公共协议
- 平台专用编码、打包与运行时交付逻辑
- 把 `bat` 兼容性包袱扩散为所有语言的公共假设

## 与其他项目的关系

- `projects/nyar`：提供元优化核心与公共协议
- `projects/nyar.language`：提供多语言前端组织方式
- `projects/nyar.language/source/*`：与 `bash`、`powershell`、`valkyrie` 等前端并列存在

## 目标

- 让 `bat` 脚本成为 `nyar` 体系中的正式前端
- 复用 `nyar` 的统一优化体系，而不是为批处理语言单独维护一条编译主线
- 保持批处理语言特性局部化，不反向污染核心层
