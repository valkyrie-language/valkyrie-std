# Zero Cost 原则

## 定义

在 `sdk vendor` 体系中，zero cost 的含义是：

> 选择 `fill` 的成本只存在于编译期，不存在于运行时。

最终产物的调用路径应当等价于“开发者手写调用具体宿主绑定函数”。

## 必须满足的条件

### 1. 编译期静态解析

`port` 到 `fill` 的映射必须在编译期确定。运行时二进制中不应残留“等会儿再决定调用谁”的逻辑。

### 2. 普通符号调用

解析完成后，port 调用应被重写为普通函数调用，而不是：

- 虚调用
- 反射调用
- 字符串查找
- 字典映射
- Service Locator

### 3. 可继续优化

静态重写后的调用必须继续参与现有优化：

- 内联
- 死代码消除
- 常量折叠
- 去虚拟化
- 跨模块裁剪

## 非 zero cost 的反例

以下方案都不符合设计要求：

### 运行时注册表

```v
register("std.net.request", wechat_request)
call_by_name("std.net.request", req)
```

问题：

- 有运行时查找
- 有字符串依赖
- 无法可靠内联

### 接口对象注入

```v
let client: NetClient = resolve_client()
client.request(req)
```

问题：

- 运行时动态分派
- 有对象模型成本
- `fill` 选择不再是构建期行为

### 反射 / DLR / JS 动态路径拼接

```v
invoke(runtime_name, method_name, req)
```

问题：

- 无法进行编译期签名校验
- 无法静态裁剪无用 `fill`

## 正确做法

### 源码阶段

源码中允许存在：

- 抽象 port 调用
- `fill` 声明
- 底层宿主特性标注

### 解析阶段

在符号解析阶段完成：

1. 找到 port
2. 过滤可见 `fill`
3. 唯一绑定
4. 直接改写调用目标

### 后续阶段

进入 `MIR/LIR/backend` 时，只保留：

- 已解析的具体函数符号
- 宿主 FFI 调用

此时抽象 port 已经“蒸发”。

## 编译器实现要求

### 要求 1：重写越早越好

应在高级语义层完成重写，最好在 `HIR` 符号解析结束前后完成。

理由：

- 诊断信息最完整
- 类型签名还完整可见
- 后续 IR 无需理解 `fill` 系统

### 要求 2：后端不做兜底

后端只负责生成目标代码，不参与 `fill` 选择。

如果到了 backend 才发现：

- 缺 `fill`
- 多个 `fill`
- 签名不匹配

说明前面的语义层设计已经失守。

### 要求 3：死代码可删除

未被选中的 `fill` 即使在有效依赖闭包中存在，也必须能够在后续阶段被裁剪，不应强制进入最终产物。

## 典型展开示例

### 源码

```v
micro get(url: utf8): utf8 {
    let req = Request.get(url)
    let resp = std.net.request(req)
    return resp.text()
}
```

### 编译期选择后

```v
micro get(url: utf8): utf8 {
    let req = Request.get(url)
    let resp = tencent.wechat.net.wechat_request(req)
    return resp.text()
}
```

### 最终宿主调用

```v
[js_builtin("wx.request")]
micro __wx_request(req: i32): i32
```

在最终代码里，没有：

- `fill` 查找表
- 条件分发器
- 运行时绑定层

这就是 zero cost。

## 与模板 / 元代码的边界

模板展开可以协助生成样板代码，但它不能代替编译期 `fill` 解析。

如果系统依赖模板在 `std` 中生成一堆：

```v
<% match target %>
```

式的宿主分支，那只是把硬编码换了一种写法，并没有获得真正的 zero cost 可扩展架构。

## 审核清单

一个 `sdk vendor` 方案若想声称 zero cost，至少要通过以下检查：

1. `fill` 是否在编译期唯一确定
2. 最终产物里是否还残留动态分派结构
3. 未使用的 `fill` 是否可被裁剪
4. backend 是否无需理解 `bind` 选择逻辑
5. `std` 是否不再直接 `match arch` 选择宿主实现

只要其中一项不成立，就不能称为 zero cost `sdk` 体系。
