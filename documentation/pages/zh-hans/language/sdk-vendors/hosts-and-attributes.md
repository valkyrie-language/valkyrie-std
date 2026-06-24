# Host 与特性标注

## Host 模型

在 `sdk vendor` 体系里，真正的核心是三件事：

1. `host_contract`
2. `host_provider`
3. `bind`

它们分别回答三个问题：

1. 哪个稳定入口允许宿主实现
2. 哪个函数在某个宿主下提供该实现
3. 哪个底层宿主绑定属性把实现接到最终宿主符号上

因此，源码语义不再建立 `std.host_contract.*` 这样的额外命名空间，而是直接围绕现有 `std` 函数入口展开。

## 1. `host_contract`

`host_contract` 表示“这个稳定入口允许由宿主提供方实现”。

它不是一个新的命名空间，而是附着在现有稳定函数入口上的宿主契约语义。

建议语义：

```v
namespace std.net;

[host_contract]
micro request(req: Request) -> Response
```

这里的 `host_contract` 身份就是 `std.net.request` 本身，而不是另起一个 `std.host_contract.net.request`。

约束：

1. `[host_contract]` 只能标注在稳定入口函数上。
2. `[host_contract]` 不引入新命名空间，也不改变用户调用路径。
3. `[host_contract]` 本身不允许叠加底层宿主特性标注。

## 2. `host_provider`

`host_provider` 表示“我来严格提供某个 `host_contract`”。

建议语义：

```v
[host_provider("std.net.request")]
micro wechat_request(req: Request) -> Response {
    ...
}
```

约束：

1. `host_provider` 的目标必须是完整、稳定、可解析的 `std` 入口路径。
2. `host_provider` 函数签名必须与目标 `host_contract` 严格一致。
3. 一个 `host_provider` 可以叠加底层宿主特性标注，但一次只能提供一个入口。

## 3. `bind`

`bind` 不是项目配置字段，而是底层宿主绑定属性这一层语义。

它负责把某个实现函数真正接到最终宿主符号上，这些信息由 `nyar` 在编译期收集处理。

典型形式：

```v
[js_builtin("fetch")]
micro __fetch_request(req: Request): Response

[clr("System.Net.Http", "System.Net.Http.HttpClient", "GetStringAsync")]
micro __clr_get(url: utf8): utf8

[jvm("java.net.HttpURLConnection", "setRequestMethod")]
micro __jvm_set_request_method(conn: i32, method: utf8): unit
```

`bind` 不负责选择哪个 `host_provider`，它只负责“选中的实现最终如何绑定到宿主”。

## 特性标注只是承载方式

当 `host` 模型确定之后，才轮到回答“源码里用什么表达它”。

这里选择特性标注，是因为它只声明关系，不引入新的运行时对象模型：

- `[host_contract]` 声明某个稳定入口允许宿主实现
- `[host_provider("...")]` 声明某个函数提供该入口
- `[js_builtin]` / `[clr]` / `[jvm]` / `[c]` / `[wasi]` / `[vm]` 等 `bind` 属性负责宿主绑定

也就是说，先有 `host_contract / host_provider / bind` 这套模型，后有 attribute 语法承载它们。

## 底层宿主特性标注

底层宿主特性标注继续负责“最后一跳绑定”：

- `[js_builtin("wx.request")]`
- `[js_builtin("fetch")]`
- `[clr("System.Net.Http", "System.Net.Http.HttpClient", "GetStringAsync")]`
- `[jvm("java.net.HttpURLConnection", "setRequestMethod")]`
- `[c("libc", "write")]`
- `[wasi]`

这些特性标注不知道 `bind`，也不做项目选择，它们只表达宿主调用约定。
这些特性标注本身就是 `bind` 语义的具体载体，由 `nyar` 在编译期收集并下沉到后续 IR / backend。

## 推荐语义规则

| 能力 | 所在层级 | 作用 |
|:---|:---|:---|
| `[host_contract]` | `std` 稳定入口层 | 声明该入口允许被宿主提供方实现 |
| `[host_provider("...")]` | `sdk` / `adaptor` / vendor 层 | 声明实现关系 |
| `[js_builtin]` / `[clr]` / `[jvm]` / `[c]` / `[wasi]` / `[vm]` | 宿主绑定层 | 承载 `bind` 语义并绑定最终宿主符号 |

## 典型结构

### `std` 中的稳定入口

```v
namespace std.net;

[host_contract]
micro request(req: Request) -> Response
```

### browser `sdk`

```v
namespace sdk.browser.net;

[host_provider("std.net.request")]
micro browser_request(req: Request) -> Response {
    return __fetch_request(req)
}

[js_builtin("fetch")]
micro __fetch_request(req: Request): Response
```

### `wechat` vendor `sdk`

```v
namespace tencent.wechat.net;

[host_provider("std.net.request")]
micro wechat_request(req: Request) -> Response {
    return __wx_request(req)
}

[js_builtin("wx.request")]
micro __wx_request(req: Request): Response
```

## 编译期解析流程

1. 解析源码，记录所有 `[host_contract]` 入口。
2. 解析有效依赖闭包中的所有 `[host_provider(...)]` 声明。
3. 根据有效依赖闭包和 `sdk-vendor` 过滤候选实现。
4. 若候选集唯一，则直接自动绑定。
5. 对唯一候选实现继续收集其上的 `[js_builtin]` / `[clr]` / `[jvm]` / `[wasi]` / `[vm]` 等 `bind` 属性。
6. 由 `nyar` 把这些 `bind` 属性下沉到后续 `MIR/LIR/backend` 所需的宿主调用信息。
7. 若候选集不唯一，则直接报冲突诊断，而不是再引入额外配置语义。

## 签名兼容规则

`host_provider` 必须与 `host_contract` 严格一致：

- 参数个数一致
- 参数类型一致
- 返回类型一致
- 泛型参数与约束一致
- effect、async 语义一致

这里不建议放宽成“可赋值即可”，因为 `host_provider` 的语义是对 `std` 入口的严格提供，而不是模糊适配。

若不一致，报编译错误，而不是在后端兜底。

## `std` 可以直接调用

因为 `host_contract` 就是现有 `std` 函数入口，所以用户和标准库都继续直接写：

```v
namespace std.net;

micro get(url: utf8): utf8 {
    let req = Request.get(url)
    let resp = std.net.request(req)
    return resp.text()
}
```

这里并没有新增一层 `std.host_contract.net.request`。

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

上面的分支逻辑应该迁移为 `host_provider + bind` 体系，而不是保留在 `std` 里。

## 冲突规则

### 0 个 `host_provider`

若当前构建闭包中没有任何 `host_provider`，报错：

- 指出缺失的 `host_contract`
- 指出当前有效依赖闭包里已经找到哪些 `sdk`
- 提示应新增依赖、锁版本或缩小候选闭包

### 1 个 `host_provider`

自动静态绑定，后续正常优化。

### 多个 `host_provider`

若多个 `host_provider` 同时可见，默认报错，不做隐式优先级猜测。
此时应通过显式依赖、锁版本或构建器侧默认注入策略缩小候选闭包，而不是引入新的项目级 `bind` 语义。

## 建议的诊断

| 代码 | 场景 |
|:---|:---|
| `sdk::host_contract::missing_provider` | 某个入口没有实现 |
| `sdk::host_contract::duplicate_provider` | 多个实现同时命中 |
| `sdk::host_contract::signature_mismatch` | `host_provider` 与 `host_contract` 签名不兼容 |
| `sdk::host_contract::illegal_host_attribute` | `[host_contract]` 上错误叠加底层宿主特性标注 |
| `sdk::host_contract::unreachable_provider` | `host_provider` 所在包未进入有效依赖闭包 |

## 为什么特性标注是合适入口

因为它只声明语义关系，而不引入运行时成本：

- 不需要注册表
- 不需要反射
- 不需要 service loader
- 不需要依赖注入容器

所有关系都在编译期解析并固化为普通函数调用，因此天然符合 zero cost 原则。
