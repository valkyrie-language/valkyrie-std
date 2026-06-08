# AWSL 到 GGScript 中间表示

## 概述

AWSL 是 VOA 框架的模板语言。`AwslIr` 是 AWSL 编译到 GGScript 的中间表示层，目标是将 AWSL 模板转换为 GGScript AST，再由 Valkyrie 编译管线处理为 WASM，消除 JavaScript 依赖。

## 在管线中的位置

```
AWSL 源码 → Oak.WidgetParser → AWSL AST → AwslIrBuilder → GGScript AST
                                                              │
                          接入标准管线 ──────────────────────┘
                              │
                              ▼
                         ② MetaStager → ... → ⑤ Dialect.Web 降级 → ... → ⑧ WASM Backend
```

AWSL 编译在标准管线之前插入：先由 Oak.WidgetParser 解析 AWSL 模板，再由 AwslIrBuilder 转换为 GGScript AST，然后接入标准管线。Web 方言（`Dialect.Web`）在 MIR 优化阶段处理。

## 转换管道

```
AWSL Source (.awsl)
  │
  ├── Oak.WidgetParser（文本解码 → WidgetParseResult）
  │
  ▼
AWSL AST
  │
  ├── AwslIrBuilder（AST → AwslIr 转换）
  │
  ▼
AwslIr / IKunTree（GGScript IR）
  │
  ├── Dialect.Web（方言降级，Nyar.Optimizer）
  │
  ▼
WasmBackend（代码生成）
  │
  ├── Acorn.Wasm.Encode（二进制编码）
  │
  ▼
.wasm
```

## 核心映射

### 响应式原语

| AWSL 概念 | GGScript IR 表示 | 说明 |
|:---|:---|:---|
| `let x = 0`（mutable） | `Signal<i32>` | 可写响应式值 |
| `let x = 0`（immutable） | `let x: i32 = 0` | 不可变值 |
| `{expr}` 插值 | `Signal.bind(expr)` | 响应式绑定 |
| `memo(fn)` | `Computed<T>` | 派生状态 |
| `effect(fn)` | `Effect<()>` | 副作用 |
| `on:click={fn}` | `EventListener<Click>` | 事件处理器 |

### 模板结构

| AWSL 节点 | GGScript IR 表示 |
|:---|:---|
| `<div class="c">` | `ElementNode { tag: "div", attrs: { "class": String("c") } }` |
| `{variable}` 插值 | `InterpolationNode { expr: ExprId(variable) }` |
| `<if condition={expr}>` | `ConditionalNode { cond: expr, then: nodes[], else: nodes[] }` |
| `<loop item in {list}>` | `ForNode { item: Sym, iterable: expr, body: nodes[] }` |
| `<Client>` / `<Server>` | `IslandNode { kind: Client \| Server, body: nodes[] }` |
| `<Head>` / `<Script>` | `MetaNode { kind: Head \| Script, content: nodes[] }` |
| `<Suspense>` | `SuspenseNode { fallback: nodes[], content: nodes[] }` |

### 生命周期

| AWSL | GGScript IR |
|:---|:---|
| `onMount(fn)` | `on_mount(self, fn)` |
| `onDestroy(fn)` | `on_destroy(self, fn)` |
| `beforeUpdate(fn)` | `before_update(self, fn)` |
| `afterUpdate(fn)` | `after_update(self, fn)` |

## IR 树结构

```
CompilationUnit
├── ComponentDecl(name, props, irNodes, css, islands)
│   ├── PropsDecl { fields: [{name, type, default}] }
│   ├── IRNode[]
│   │   ├── ElementNode(tag, attrs, children, id)
│   │   │   ├── AttrNode[]
│   │   │   │   ├── StaticAttr(name, value)
│   │   │   │   ├── DynamicAttr(name, exprId)
│   │   │   │   └── EventAttr(event, handlerId)
│   │   │   └── IRNode[]
│   │   ├── TextNode(text)
│   │   ├── InterpolationNode(exprId)
│   │   ├── ConditionalNode(condExprId, thenNodes, elseNodes)
│   │   ├── ForNode(varName, iterableExprId, bodyNodes, keyExprId?)
│   │   ├── IslandNode(kind, componentRef, props)
│   │   ├── MetaNode(kind, contentNodes)
│   │   └── SuspenseNode(fallbackNodes, contentNodes)
│   ├── StyledCss[] { scope, css }
│   └── SignalDecl[] { name, type, initialValue }
│
├── ConfigDecl { pwa?, hmr?, ssr? }
└── RouteManifest { entries: [{path, component}] }
```

## WebDialect 桥接

不再生成 JavaScript 的 `addEventListener` 等调用，改为通过 GGScript 的 `[wasm_import]` 声明桥接到浏览器 API：

```v
[wasm_import(module = "voa_web")]
extern micro voa_document_query(selector: string): i32

[wasm_import(module = "voa_web")]
extern micro voa_element_set_text(handle: i32, text: string): void

[wasm_import(module = "voa_web")]
extern micro voa_element_add_event_listener(handle: i32, event_type: string, callback: fn): void

[wasm_import(module = "voa_web")]
extern micro voa_dom_create_element(tag: string): i32

[wasm_import(module = "voa_web")]
extern micro voa_dom_append_child(parent: i32, child: i32): void

[wasm_import(module = "voa_web")]
extern micro voa_dom_set_attribute(element: i32, name: string, value: string): void

[wasm_import(module = "voa_web")]
extern micro voa_dom_set_class_list(element: i32, class_name: string): void

[wasm_import(module = "voa_web")]
extern micro voa_dom_remove_child(parent: i32, child: i32): void
```

## 编译示例

### 输入（AWSL）

```awsl
<widget name="Counter">
    <div class="counter">
        <button on:click={() => count = count + 1}>
            +1
        </button>
        <span>Count: {count}</span>
    </div>
</widget>

<script>
    let count: i32 = 0
</script>
```

### 输出（GGScript IR）

```v
component Counter
{
    signal count: i32 = 0

    fn handle_increment()
    {
        count = count + 1
    }

    fn render(self: Counter): ElementNode
    {
        return ElementNode("div", { class: "counter" }, [
            ElementNode("button", { click: self.handle_increment }, [
                TextNode("+1")
            ]),
            ElementNode("span", {}, [
                TextNode("Count: "),
                InterpolationNode(bind(count))
            ])
        ])
    }
}
```

## Islands 架构映射

```
<Client>  →  ClientIsland(componentRef, hydrationStrategy)
<Server>  →  ServerOnly(componentRef)
```

Hydration 策略：

| 策略 | 行为 |
|:---|:---|
| `eager` | 立即 hydrate |
| `lazy` | IntersectionObserver 进入视口时 hydrate |
| `idle` | requestIdleCallback 时 hydrate |
| `none` | 纯 SSR，不 hydrate |

## SSR 集成

GGScript 版本 SSR 通过 `ValkyrieRuntime` 的 `evaluate` 能力实现：

```v
micro render_page_ssr(component: Component, props: map): string
{
    let runtime = ValkyrieRuntime.create()
    let instance = runtime.instantiate(component, props)
    return runtime.render_to_string(instance)
}
```