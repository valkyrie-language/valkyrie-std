# AWSL 扩展

AWSL（Asgard Web Specification Language）是 VOA 框架中的 **Vue 风格** UI 声明语言（`.awsl`）：模板、指令、**单文件组件（SFC）** 的结构借鉴 Vue，但**响应式语义接近 Solid**——状态与更新图编译进 **WASM**，浏览器侧只有加载胶水，没有独立 JS 框架 runtime。

SFC 只存在于 AWSL：每个 `.awsl` 文件对应**一个** widget，经统一的 `compile_awsl_source` 解析、校验、降级后汇入 Valkyrie 主线。顶层 `widget` / `template`（兼容别名）、`script`、`style` 块并列写在文件里。

## 三种标签形式

| 形式 | 语法 | 语义 |
|:---|:---|:---|
| **扩展属性** | `<tag @name="expr"/>` | 编译器 DSL（`@` 前缀），引号内为 Valkyrie 表达式 |
| **动态绑定** | `<tag :prop="expr"/>` | 动态 prop / 双向绑定（`:` 前缀） |
| **静态属性** | `<tag class="counter"/>` | HTML 字符串字面量 |
| **二分标签** | `<tag>content</tag>` | 带子内容 |

## Widget 标准词表

**SFC 根标签** `<widget name>` 与文件名 stem 一致，采用 **snake_case**（`counter.awsl` → `<widget counter>`，`interactive-col-plot.awsl` → `<widget interactive_col_plot>`）。

模板内的 **Asgard / Valkyrie 控件原语** 仍为 PascalCase：`Column`、`Box`、`Row`、`Text`、`Button` 等。

`div` / `span` 是 **HTML 宿主方言**（静态属性用引号；动态用 `@` / `:` DSL，不是 HTML `on:click`）。

```awsl
<widget counter>
  <Column>
    <Text>{count}</Text>
    <Button @click="on_tap">+1</Button>
  </Column>
</widget>
<script>
  let mut count = 0
  micro on_tap() { count += 1 }
</script>
```

## KV 语法（AWSL DSL）

AWSL 属性 KV **不用花括号 `{}`**。分三层：

| 层级 | 写法 | 示例 |
|:---|:---|:---|
| **静态 HTML** | `name="literal"` | `class="counter"` `href="/about"` |
| **动态绑定** | `:name="expr"` | `:title="title"` `:bind="name"` |
| **编译器 DSL** | `@name="expr"` | `@click="handler"` `@if="isVisible"` |

### `@` 指令（DSL，引号内表达式）

大多数控制逻辑走 `@` 前缀——**不是 HTML 属性名**：

```awsl
<button @click="on_increment">+1</button>
<ul @loop="item in items()">
  <li>{item.name}</li>
</ul>
<div @if="isVisible">...</div>
<div @style="flex w-4 h-4 rounded-lg bg-blue-500">...</div>
<input :bind="name" />
```

| 指令 | 示例 |
|:---|:---|
| `@click` / `@submit` | `@click="on_increment"` |
| `@loop` | `@loop="item in todos()"` |
| `@if` | `@if="isVisible"` |
| `@style` | `@style="flex items-center gap-2"`（Tailwind atomic class 等） |
| `:style` | `:style="f\"width: {w}\""`（动态 inline CSS，HTML `style` 属性） |
| `<style>` | 静态 CSS 规则块 |
| `@class` | `@class="isActive ? 'on' : ''"` |
| `@bind` | 可用 `:bind="name"`（推荐）或 `@bind="name"` |

**禁止**：KV 上的 `={expr}`、`on:click`（非 HTML）、裸 `@click=on_increment`（必须加引号）、在 `@style` 里写 CSS 属性（应用 `:style` 或 `<style>`）。

模板正文 `{count}` 仍是插值，不受 KV 规则影响。

### 与 Marko / Vue 的对照

| | Marko | Vue | AWSL |
|:---|:---|:---|:---|
| 静态 | `class="a"` | `class="a"` | `class="a"` |
| 动态 | `value=count` / `:=` | `:class="expr"` | `:bind="expr"` |
| 事件 | `onClick() { }` 方法块 | `@click="fn"` | `@click="fn"` |
| KV `{}` | 无（用 `${}` 正文） | 无 | 无 |

Marko 用 **方法块**和 `:=` 双向绑定；AWSL 选用 **Vue 式 `@` / `:` + 引号表达式**，更适合 Valkyrie 源码片段。

## 脚本与样式子块

**`<script>` 使用 vx 表面**（Valkyrie + X-Grammar，与 `.vx` 相同），不是纯 Valkyrie（`.v`）源码面。可在 script 中写 `let` / `micro`，以及在 `view` / `render` 方法体内混写 X-Grammar 标记。`let`、参数、`micro` / 普通 method 名应为 `snake_case`（lint `E0301`，不阻断编译）。

```awsl
<widget counter>
  <flex>
    <text class="counter">计数: {count}</text>
    <button @click="on_increment">+1</button>
  </flex>
</widget>
<script>
  let mut count = 0
  micro on_increment() { count += 1 }
</script>
<style>
  .counter { font-size: 24px; }
</style>
```

## 响应式系统（Solid 语义）

| 写法 | 语义 |
|:---|:---|
| `let mut x = …` | 响应式；模板 `{x}` 订阅变更 |
| `let x = …` | 非响应式常量 |
| `micro foo() { … }` | 事件 / 逻辑 |

## 与 `.vx` X-Grammar 的对照

| | AWSL 模板 | AWSL `<script>` | `.vx` |
|:---|:---|:---|:---|
| 语言面 | AWSL DSL | **vx**（Valkyrie + X-Grammar） | **vx** |
| 静态 | `class="counter"` | `class="counter"`（在 X-Grammar 体内） | `class="counter"` |
| 动态 | `:title="title"` | `:on_click="expr"` | `:on_click="expr"` |
| 事件 / DSL | `@click="fn"` | （用 `:on_click` 或 widget API） | （用 `:on_click` 或 widget API） |
| KV `{}` | 禁止 | 禁止 | 禁止 |
| HTML void | 支持（不推荐） | — | 不支持 |

## 组件与插槽

```awsl
<card-layout>
  <slot:header><text>标题</text></slot:header>
  <text>默认插槽</text>
</card-layout>
```

列表渲染也可用标签形式：`<loop item in todos()>`（与 `@loop="item in todos()"` 等价，后者更偏 DSL）。
