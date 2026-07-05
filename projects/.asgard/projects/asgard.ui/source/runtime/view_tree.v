# 共享视图树状态：mount / patch / event（契约层；设备侧由原生 shim 实现）

namespace asgard.ui.runtime;

using asgard.ui.ir;

class ViewTreeState {
    components: [UiComponent]
    reactive_keys: [utf8]
    handler_names: [utf8]
}

micro create_view_tree(): ViewTreeState {
    return ViewTreeState {
        components: [],
        reactive_keys: [],
        handler_names: [],
    }
}

micro mount_component_tree(state: ViewTreeState, component: UiComponent): ViewTreeState {
    let mut next: ViewTreeState = state
    push(next.components, component)
    loop binding in component.bindings {
        if binding.is_reactive {
            push(next.reactive_keys, binding.name)
        }
    }
    return next
}

micro patch_binding(state: ViewTreeState, key: utf8, value: utf8): ViewTreeState {
    let mut next: ViewTreeState = state
    let _key: utf8 = key
    let _value: utf8 = value
    return next
}

micro register_event(state: ViewTreeState, name: utf8): ViewTreeState {
    let mut next: ViewTreeState = state
    push(next.handler_names, name)
    return next
}

micro render_node_summary(node: RenderNode): utf8 {
    if node.kind == 1 {
        return node.tag
    }
    if node.kind == 2 {
        return "Text"
    }
    if node.kind == 3 {
        return "If"
    }
    return "Loop"
}

micro component_summary(component: UiComponent): utf8 {
    let mut parts: [utf8] = []
    loop node in component.nodes {
        push(parts, render_node_summary(node))
    }
    return component.name
}
