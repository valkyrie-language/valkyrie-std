# Port、Bind、Fill 与特性标注

## 设计目的

`sdk vendor` 体系中的源码语义不再建立 `std.port.*` 这样的额外命名空间，而是直接围绕现有 `std` 函数入口展开。这里有三套正交能力：

1. `port`：声明某个稳定函数入口可被宿主填充。
2. `bind`：声明当前项目把该入口绑定到哪个实现。
3. `fill`：声明某个函数严格实现该入口。

target、abi、publish format、vendor 选择都属于 `manifest + planner` 的职责，不属于源码特性标注。

## 三类语义

### 1. `port`

`port` 不是一个新的命名空间，而是附着在现有稳定函数入口上的插槽语义。

建议语义：

```v
namespace std.net;

[port]
micro request(req: Request) -> Response
```

这里的 `port` 身份就是 `std.net.request` 本身，而不是另起一个 `std.port.net.request`。

约束：

1. `[port]` 只能标注在稳定入口函数上。
2. `[port]` 不引入新命名空间，也不改变用户调用路径。
3. `[port]` 本身不允许叠加底层宿主特性标注。

### 2. `fill`

`fill` 表示“我来严格填充某个 `port`”。

建议语义：

```v
[fill("std.net.request")]
micro wechat_request(req: Request) -> Response {
    ...
}
```

约束：

1. `fill` 的目标必须是完整、稳定、可解析的 `std` 入口路径。
2. `fill` 函数签名必须与目标 `port` 严格一致。
3. 一个 `fill` 可以叠加底层宿主特性标注，但一次只能填充一个入口。

### 3. `bind`

`bind` 不写在源码里，而写在项目清单中，用来表达“当前工程到底选择哪个 `fill`”。

它默认不是必填字段，而是冲突消歧字段。

示意：

```von
sdk: {
    bind: {
        "std.net.request": "tencent.wechat.net.wechat_request"
    }
}
```

`bind` 不创建实现，它只做选择。

## 底层宿主特性标注

底层宿主特性标注继续负责“最后一跳绑定”：

- `[js_builtin("wx.request")]`
- `[js_builtin("fetch")]`
- `[clr("System.Net.Http", "System.Net.Http.HttpClient", "GetStringAsync")]`
- `[jvm("java.net.HttpURLConnection", "setRequestMethod")]`
- `[c("libc", "write")]`
- `[wasi]`

这些特性标注不知道 `bind`，也不做项目选择，它们只表达宿主调用约定。

## 推荐语义规则

| 能力 | 所在层级 | 作用 |
|:---|:---|:---|
| `[port]` | `std` 稳定入口层 | 声明该入口允许被填充 |
| `[fill("...")]` | `sdk` / `adaptor` / vendor 层 | 声明实现关系 |
| `sdk.bind` | 项目清单层 | 选择当前项目使用哪个实现 |
| `[js_builtin]` / `[clr]` / `[jvm]` / `[c]` / `[wasi]` | 宿主层 | 绑定最终宿主符号 |

## 典型结构

### `std` 中的稳定入口

```v
namespace std.net;

[port]
micro request(req: Request) -> Response
```

### browser `sdk`

```v
namespace sdk.browser.net;

[fill("std.net.request")]
micro browser_request(req: Request) -> Response {
    return __fetch_request(req)
}

[js_builtin("fetch")]
micro __fetch_request(req: Request): Response
```

### `wechat` vendor `sdk`

```v
namespace tencent.wechat.net;

[fill("std.net.request")]
micro wechat_request(req: Request) -> Response {
    return __wx_request(req)
}

[js_builtin("wx.request")]
micro __wx_request(req: Request): Response
```

## 编译期解析流程

1. 解析源码，记录所有 `[port]` 入口。
2. 解析有效依赖闭包中的所有 `[fill(...)]` 声明。
3. 根据有效依赖闭包和 `sdk-vendor` 过滤候选实现。
4. 若候选集唯一，则直接自动绑定。
5. 若候选集冲突，再读取项目侧 `sdk.bind` 做消歧。
6. 重写后，后续 `MIR/LIR/backend` 不再感知 `port / bind / fill` 关系。

## 签名兼容规则

`fill` 必须与 `port` 严格一致：

- 参数个数一致
- 参数类型一致
- 返回类型一致
- 泛型参数与约束一致
- effect、async 语义一致

这里不建议放宽成“可赋值即可”，因为 `fill` 的语义是对 `std` 入口的严格填充，而不是模糊适配。

若不一致，报编译错误，而不是在后端兜底。

## `std` 可以直接调用

因为 `port` 就是现有 `std` 函数入口，所以用户和标准库都继续直接写：

```v
namespace std.net;

micro get(url: utf8): utf8 {
    let req = Request.get(url)
    let resp = std.net.request(req)
    return resp.text()
}
```

这里并没有新增一层 `std.port.net.request`。

## 不允许的写法

不允许继续把宿主选择写回 `std`：

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

上面的分支逻辑应该迁移为 `bind` 选择，而不是保留在 `std` 里。

## 冲突规则

### 0 个 `fill`

若当前构建闭包中没有任何 `fill`，报错：

- 指出缺失的 `port`
- 指出当前有效依赖闭包里已经找到哪些 `sdk`
- 提示应新增依赖或新增 `bind`

### 1 个 `fill`

自动静态绑定，后续正常优化。

### 多个 `fill`

若多个 `fill` 同时可见，默认报错，不做隐式优先级猜测。

只有这时项目 manifest 才需要显式指定 `sdk.bind` 消歧。

## 建议的诊断

| 代码 | 场景 |
|:---|:---|
| `sdk::port::missing_fill` | 某个入口没有实现 |
| `sdk::port::duplicate_fill` | 多个实现同时命中 |
| `sdk::port::signature_mismatch` | `fill` 与 `port` 签名不兼容 |
| `sdk::port::illegal_host_attribute` | `[port]` 上错误叠加底层宿主特性标注 |
| `sdk::port::unreachable_fill` | `fill` 所在包未进入有效依赖闭包 |

## 为什么特性标注是合适入口

因为它只声明语义关系，而不引入运行时成本：

- 不需要注册表
- 不需要反射
- 不需要 service loader
- 不需要依赖注入容器

所有关系都在编译期解析并固化为普通函数调用，因此天然符合 zero cost 原则。
