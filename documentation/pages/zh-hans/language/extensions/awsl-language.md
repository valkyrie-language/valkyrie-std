# AWSL 扩展

AWSL（Asgard Web Specification Language）是 VOA 框架中的 **Vue 风格** UI 声明语言（`.awsl`）：模板、指令、**单文件组件（SFC）** 的结构借鉴 Vue，但**响应式语义接近 Solid**——状态与更新图编译进 **WASM**，浏览器侧只有加载胶水，没有独立 JS 框架 runtime。

SFC 只存在于 AWSL：顶层（或约定顺序的）`widget` / `template`、`script`、`style` 块写在 `.awsl` 里，不再有独立的 Valkyrie SFC / `.vx` 组件格式。

## 三种标签形式

| 形式 | 语法 | 语义 |
|:---|:---|:---|
| **扩展属性** | `<tag @name/>` | 编译器扩展 `@` 开头属性，编译后删除 |
| **直接标签** | `<tag name/>` | 常规短写 `context.Tag(ContextFn, {})` |
| **二分标签** | `<tag>content</tag>` | 带子内容 `context.Tag(ContextFn, {}, children)` |

## Widget 标准词表（PascalCase）

Asgard / Valkyrie **widget 布局与控件原语是 PascalCase**：`Column`、`Box`、`Row`、`Text`、`Button` 等。

`div` / `span` 是 **HTML 宿主方言**。写了 Asgard 也会翻译（人性化），但那不是 widget 词表本身——Asgard 基于 widget，再叠一层对 HTML 习惯的优化。

```awsl
<template>
  <Column>
    <Text>{count}</Text>
    <Button on:click=on_tap>+1</Button>
  </Column>
</template>
```

小写 `flex` / `text` 等旧写法仍可识别，视为 Asgard 别名。

## 扩展属性约定

`@` 前缀为编译器扩展标记，编译后直接删除：

```awsl
<card @if={isVisible} @for={item in items}>
  <text>{item.name}</text>
</card>
```

编译后 `@if` 和 `@for` 被转换为条件/循环逻辑，不会出现在最终输出中。

## 脚本与样式子块

顶层并列 `<widget>`、`<script>`、`<style>` 三大块（`<template>` 是 `<widget>` 的兼容别名，仅用于顶层模板容器）：

```awsl
<widget>
  <flex>
    <text class="counter">计数: {count}</text>
    <button @click="increment">+1</button>
  </flex>
</widget>
<script>
  let mut count = 0

  micro increment() {
      count += 1
  }
</script>
<style>
  .counter {
    font-size: 24px;
    color: #333;
  }
</style>
```

旧写法把 `<script>` / `<style>` / 内联 `<template>` 包在 `<widget>` 内仍可解析，但不应在新代码中使用。

## 响应式系统（Solid 语义）

AWSL **不写** `createSignal` / `createEffect` 等 API。响应式由 Valkyrie 的 `let mut` 直接表达，编译器在 WASM 内建立细粒度依赖图（类似 Solid，而非 Vue 的组件级重渲染）。

| 写法 | 语义 | 编译去向 |
|:---|:---|:---|
| `let mut x = …` | **响应式**可变状态；模板中 `{x}` 订阅其变更 | WASM 信号 / 更新图 |
| `let x = …` | **非响应式**绑定（一次性快照、派生常量） | 普通 `let` |
| `micro foo() { … }` | 事件 / 逻辑处理 | WASM 函数 |

### 示例

```awsl
<script>
  let mut count = 0              // 响应式
  let label = "点击次数"          // 非响应式常量

  micro increment() {
      count += 1                 // 仅更新依赖 count 的 DOM 片段
  }
</script>

<widget>
  <text>{label}：{count}</text>
  <button @click="increment">+1</button>
</widget>
```

### 与 Vue / Solid 的对照

| | Vue | Solid | AWSL |
|:---|:---|:---|:---|
| 模板语法 | SFC + 指令 | JSX | **Vue 风格** `.awsl` |
| 状态 | `ref` / `reactive` | `createSignal` | **`let mut`** |
| 更新粒度 | 组件级 diff | 细粒度信号 | **细粒度（WASM）** |
| 运行时 | JS 框架 | JS 运行时 | **WASM + 最小 `boot.js`** |

模板中的 `{expr}` 读取响应式变量时，编译器会插入订阅；`@click` 等事件处理调用 `<script>` 中的 `micro`，逻辑全部在 WASM 内执行。

### 事件绑定

```awsl
<button @click="handler">点击</button>
<button @click="count += 1">+1</button>
<input @input="name = event.target.value"/>
```

## 指令

| 指令 | 说明 | 示例 |
|:---|:---|:---|
| `@if` | 条件渲染 | `<div @if={isVisible}>` |
| `@for` | 列表渲染（兼容，等价于 `<loop>`） | `<li @for={item in items}>` |
| `<loop>` | **列表渲染（首选）** | `<loop item in todos()>` |
| `@bind` | 双向绑定 | `<input @bind={name}/>` |
| `@on` | 事件绑定简写 | `<div @on:click={handler}>` |
| `@ref` | DOM 引用 | `<canvas @ref={myCanvas}/>` |
| `@class` | 类名合并 | `<div @class:active={isActive}>` |

## 组件系统

### 插槽

```awsl
<!-- 父组件 -->
<card-layout>
  <slot:header>
    <text>标题</text>
  </slot:header>
  <text>默认插槽内容</text>
  <slot:footer>
    <button>确定</button>
  </slot:footer>
</card-layout>

<!-- card-layout 组件定义 -->
<flex>
  <div class="header">{slots.header}</div>
  <div class="body">{slots.default}</div>
  <div class="footer">{slots.footer}</div>
</flex>
```

### 组件导入

```awsl
<import:card-layout from="./components/card-layout.awsl"/>
```
