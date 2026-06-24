# 特性标注与 Port 机制

## 设计目的

特性标注负责声明元数据，不负责做 target 选择。`sdk vendor` 体系中的特性标注只解决一个问题：

> 哪个符号是抽象 port，哪个符号是该 port 的 provider。

target、abi、publish format、vendor 选择都属于 `manifest + planner` 的职责，不属于源码特性标注。

## 三类特性标注

### 1. 抽象 port 特性标注

抽象 port 由 `std` 或其他协议包定义，表示“这里需要一个稳定能力”，而不是“这里已经绑定到某宿主”。

建议语义：

```v
[port]
micro request(req: Request) -> Response
```

约束：

1. `[port]` 只能标注在函数声明上。
2. `[port]` 声明本身不允许带宿主 FFI 特性标注。
3. `[port]` 不能有函数体，或者函数体只允许作为默认桥接包装层。

### 2. Provider 特性标注

provider 声明某个函数提供特定 port 的实现。

建议语义：

```v
[provides("std.port.net.request")]
micro wechat_request(req: Request) -> Response {
    ...
}
```

约束：

1. `provides` 参数必须是稳定、完整、可解析的 port 路径。
2. provider 的签名必须与目标 port 完全兼容。
3. 一个 provider 可以叠加底层宿主特性标注，但只能 `provides` 一个 port。

### 3. 底层宿主特性标注

底层宿主特性标注继续负责“最后一跳绑定”：

- `[js_builtin("wx.request")]`
- `[js_builtin("fetch")]`
- `[clr("System.Net.Http", "System.Net.Http.HttpClient", "GetStringAsync")]`
- `[jvm("java.net.HttpURLConnection", "setRequestMethod")]`
- `[c("libc", "write")]`
- `[wasi]`

这些特性标注不知道 `port`，它们只表达宿主调用约定。

## 推荐语义规则

| 特性标注 | 层级 | 作用 |
|:---|:---|:---|
| `[port]` | 抽象层 | 定义能力插槽 |
| `[provides("...")]` | provider 层 | 声明实现关系 |
| `[js_builtin]` / `[clr]` / `[jvm]` / `[c]` / `[wasi]` | 宿主层 | 绑定最终宿主符号 |

## 典型结构

### `std` 中的抽象 port

```v
namespace std.port.net;

[port]
micro request(req: Request) -> Response
```

### browser `sdk`

```v
namespace sdk.browser.net;

[provides("std.port.net.request")]
micro browser_request(req: Request) -> Response {
    let handle = __fetch_request(req)
    return from_fetch_response(handle)
}

[js_builtin("fetch")]
micro __fetch_request(req: i32): i32
```

### `wechat` vendor `sdk`

```v
namespace tencent.wechat.net;

[provides("std.port.net.request")]
micro wechat_request(req: Request) -> Response {
    let handle = __wx_request(to_wx_request(req))
    return from_wx_response(handle)
}

[js_builtin("wx.request")]
micro __wx_request(req: i32): i32
```

## 编译期解析流程

1. 解析源码，记录所有 `[port]` 声明。
2. 解析依赖闭包中的所有 `[provides(...)]` 声明。
3. 根据 planner 已选中的工程集合过滤候选 provider。
4. 在符号解析期，把对 port 的调用重写到唯一 provider。
5. 重写后，后续 `MIR/LIR/backend` 不再感知抽象 port。

## 签名兼容规则

provider 必须与 port 签名一致：

- 参数个数一致
- 参数类型一致，或满足显式定义的可赋值规则
- 返回类型一致
- 泛型参数与约束一致
- effect、async 语义一致

若不一致，报编译错误，而不是在后端兜底。

## 默认实现与桥接层

`std` 可以为某些 port 提供默认桥接包装，但这个包装本身仍然不是宿主分支表。

允许：

```v
namespace std.net;

micro get(url: utf8): utf8 {
    let req = Request.get(url)
    let resp = std.port.net.request(req)
    return resp.text()
}
```

不允许：

```v
micro get(url: utf8): utf8 {
    <% match arch %>
        <% case "wasm32" %>
        return std.adaptor.wasm.fetch.http_fetch(url)
        <% case "clr" %>
        return std.adaptor.dotnet.net.http_get_string_async(url)
    <% end match %>
}
```

后者会把宿主选择重新塞回 `std`。

## 冲突规则

### 0 个 provider

若当前构建闭包中没有任何 provider，报错：

- 指出缺失的 port
- 指出当前 target
- 列出已加载的 `sdk` 包
- 提示应新增依赖或绑定

### 1 个 provider

静态绑定，后续正常优化。

### 多个 provider

若多个 provider 同时可见，默认报错，不做隐式优先级猜测。

只有在 manifest 显式指定时，才能消歧。

## 建议的诊断

| 代码 | 场景 |
|:---|:---|
| `sdk::port::missing_provider` | 某个 port 没有实现 |
| `sdk::port::duplicate_provider` | 多个 provider 同时命中 |
| `sdk::port::signature_mismatch` | provider 与 port 签名不兼容 |
| `sdk::port::illegal_host_attribute` | `[port]` 上错误叠加底层 FFI 特性标注 |
| `sdk::port::unreachable_provider` | provider 所在包未进入依赖闭包 |

## 为什么特性标注是合适入口

因为它只声明语义关系，而不引入运行时成本：

- 不需要注册表
- 不需要反射
- 不需要 service loader
- 不需要依赖注入容器

所有关系都在编译期解析并固化为普通函数调用，因此天然符合 zero cost 原则。
