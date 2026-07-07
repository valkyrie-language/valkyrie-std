# VOA DOM / 组件事件类型 — AWSL 处理器请用具体类型，避免 any

struct DomTokenList {}

struct HtmlElement {
    classList: DomTokenList
}

struct HtmlInputElement {
    value: string
}

# 原生 DOM：input / textarea
struct InputEvent {
    target: HtmlInputElement
}

# 原生 DOM：keydown / keyup
struct KeyboardEvent {
    key: string
    target: HtmlInputElement
}

# 原生 DOM：click / pointer（含 overlay 判定）
struct MouseEvent {
    target: HtmlElement
}

# 组件 emit：Input / Select 等 value 变更
struct ValueChangeEvent {
    value: string
}

# 组件 emit：Switch / checkbox
struct CheckedChangeEvent {
    checked: bool
}

# 组件 emit：Form submit（字段名 → 值）
struct FormSubmitEvent {
    fields: map
}

[js_builtin("DOMTokenList.prototype.contains")]
micro dom_class_list_contains(list: DomTokenList, token: string): bool
