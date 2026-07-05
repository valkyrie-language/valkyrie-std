# RenderIR 与 script 绑定类型（与 VOA mobile_ui_binary 对齐）

namespace asgard.ui.ir;

class ScriptBinding {
    name: utf8
    init_expr: utf8
    is_reactive: bool
    value_type: i32
}

class RenderAttr {
    name: utf8
    is_event: bool
    is_prop: bool
    value_kind: i32
    static_value: utf8
    dynamic_value: utf8
}

class RenderNode {
    kind: i32
    tag: utf8
    node_kind: i32
    attrs: [RenderAttr]
    children: [RenderNode]
    else_children: [RenderNode]
    text_parts: [utf8]
    cond_expr: utf8
    loop_items: utf8
    loop_item_var: utf8
}

class UiComponent {
    route: utf8
    name: utf8
    bindings: [ScriptBinding]
    nodes: [RenderNode]
}
