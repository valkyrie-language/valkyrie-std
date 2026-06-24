# 分层模型

## 总体结构

`sdk vendor` 体系把“抽象能力”和“宿主实现”拆成四层：

1. 语言层：提供 `attrs`、命名空间、路径解析、类型检查与编译期元数据语义。
2. 标准抽象层：由 `std` 定义稳定的跨平台 port。
3. 宿主实现层：由 `sdk` 或第三方 vendor 包提供具体 provider。
4. 装配层：由 `manifest`、target profile 与 planner 决定当前构建可见的 provider 集合。

## 职责边界

### `std`

`std` 只负责抽象能力，不直接承载宿主名字。

应放在 `std` 的内容：

- 集合、文本、迭代器、数学抽象、容器协议
- `std.net.request` 这种“能力抽象”
- `std.console.write_line` 这种“统一语义入口”
- 与宿主无关的数据结构和错误模型

不应放在 `std` 的内容：

- `wx.request`
- `fetch`
- `System.Net.Http.HttpClient`
- `java.net.HttpURLConnection`
- browser / Node / `wechat` 这种宿主识别分支

### `sdk`

`sdk` 负责宿主 API 绑定，是 `std` 的外部实现提供方。

典型职责：

- 提供底层 FFI 绑定
- 完成编码转换、句柄转换、异常包装
- 声明“我提供哪个 port”
- 声明适用的 target / abi / publish 约束

### 第三方 vendor 包

第三方或厂商维护的包是 `sdk` 的一种特殊形式。它们不需要进入官方 `std` 仓库，只需要遵守统一协议即可。

例如：

- `tencent.wechat.sdk.net`
- `cloudflare.worker.sdk.fetch`
- `electron.sdk.fs`

### 编译器与构建系统

编译器和构建系统不实现宿主逻辑，只负责：

1. 收集 port 声明
2. 收集 provider 声明
3. 依据 target / manifest 过滤 provider
4. 在符号解析阶段把 port 静态绑定到唯一 provider

## 推荐目录形态

### 官方抽象包

```text
projects/std
  source/port/net.v
  source/port/console.v
  source/net/http.v
  source/console/_.v
```

### 官方宿主包

```text
projects/sdk.browser
projects/sdk.dotnet
projects/sdk.jvm
projects/sdk.wasi
projects/sdk.nyar
```

### 第三方 vendor 包

```text
vendors/tencent.wechat.sdk
vendors/tencent.wechat.sdk.net
vendors/tencent.wechat.sdk.storage
```

命名不要求所有人都使用同一前缀，但必须满足两条约束：

1. 包名能稳定区分组织者与宿主。
2. provider 声明的导出路径在工作区中唯一。

## 命名原则

### 抽象能力命名

抽象能力用稳定语义命名，而不是用宿主术语命名。

好例子：

- `std.port.net.request`
- `std.port.console.write_line`
- `std.port.storage.get_text`

坏例子：

- `std.port.fetch`
- `std.port.wx_request`
- `std.port.http_client`

### 宿主实现命名

宿主实现可以使用宿主原生术语，因为它本来就是平台绑定层。

例如：

- `tencent.wechat.net.wx_request`
- `sdk.browser.net.fetch_request`
- `sdk.dotnet.net.http_client_request`

## 为什么必须分层

如果没有这层边界，系统会退化成“`std` 里按 `arch` 写一堆条件分支”。这种方式在短期内简单，但长期会出现：

1. `std` 体积不断膨胀。
2. 宿主差异进入语言核心。
3. 第三方包无法独立演进。
4. target profile 与源码分支强耦合。
5. 同一能力无法在不同宿主下独立演化。

## 与旧 `adaptor` 的关系

旧的 `std.adaptor.*` 可以视为过渡期的宿主包，但不再建议把它当作最终架构：

- 若它只提供宿主实现，可以迁移到 `sdk.*`
- 若它同时承担 `std` 抽象与宿主逻辑，应拆分
- 若它仅是历史命名，可以在迁移期保留别名，但新文档与新工程不再继续扩张该模式

## 设计原则

### 单一职责

- `std` 不选择宿主
- `sdk` 不定义语言抽象
- planner 不实现宿主 API
- backend 不参与 provider 选择

### 显式依赖

某个项目想使用第三方 vendor 能力，必须把对应包显式放入依赖闭包。编译器不自动联网下载，也不根据名字猜测 provider。

### 零运行时成本

分层只存在于源码与编译期，不应残留到运行时对象模型中。
