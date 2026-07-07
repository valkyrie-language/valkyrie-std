# Asgard UI v1 wire decode (magic 8 bytes: ASGARDUI)

namespace asgard.ui.wire;

using asgard.ui.ir;
using std.text;

micro asgard_ui_magic(): [u8] {
    return [0x41, 0x53, 0x47, 0x41, 0x52, 0x44, 0x55, 0x49]
}

micro node_tag(): i32 { return 1 }
micro node_text(): i32 { return 2 }
micro node_if(): i32 { return 3 }
micro node_loop(): i32 { return 4 }

micro attr_static(): i32 { return 1 }
micro attr_dynamic(): i32 { return 2 }

micro text_static(): i32 { return 1 }

class StringRead {
    value: utf8
    next: i32
}

class NodeRead {
    nodes: [RenderNode]
    next: i32
}

class AttrRead {
    attrs: [RenderAttr]
    next: i32
}

class BindingRead {
    bindings: [ScriptBinding]
    next: i32
}

micro read_u32(data: [u8], offset: i32): i32 {
    let b0: i32 = i32(data[offset])
    let b1: i32 = i32(data[offset + 1])
    let b2: i32 = i32(data[offset + 2])
    let b3: i32 = i32(data[offset + 3])
    return b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
}

micro slice_bytes(data: [u8], start: i32, end: i32): [u8] {
    let mut out: [u8] = []
    let mut i: i32 = start
    while i < end && i < data.length {
        push(out, data[i])
        i = i + 1
    }
    return out
}

micro read_string(data: [u8], offset: i32): StringRead {
    let len: i32 = read_u32(data, offset)
    let start: i32 = offset + 4
    let end: i32 = start + len
    let bytes: [u8] = slice_bytes(data, start, end)
    return StringRead { value: Utf8Text::from_bytes(bytes), next: end }
}

micro magic_matches(data: [u8], idx: i32): bool {
    let magic: [u8] = asgard_ui_magic()
    let mut i: i32 = 0
    while i < magic.length {
        if data[idx + i] != magic[i] {
            return false
        }
        i = i + 1
    }
    return true
}

micro find_asgard_ui_section(container: [u8]): [u8] {
    let magic: [u8] = asgard_ui_magic()
    let magic_len: i32 = magic.length
    let mut idx: i32 = 0
    let mut last: [u8] = []
    while idx + magic_len + 4 <= container.length {
        if !magic_matches(container, idx) {
            idx = idx + 1
        } else {
            let len: i32 = read_u32(container, idx + magic_len)
            let start: i32 = idx + magic_len + 4
            let end: i32 = start + len
            if end > container.length {
                return last
            }
            last = slice_bytes(container, start, end)
            idx = end
        }
    }
    return last
}

micro join_utf8_parts(parts: [utf8]): utf8 {
    let mut out: utf8 = Utf8Text::from_bytes([])
    loop part in parts {
        out = out.concat(part)
    }
    return out
}

micro read_text_parts(data: [u8], offset: i32): StringRead {
    let count: i32 = read_u32(data, offset)
    let mut cursor: i32 = offset + 4
    let mut parts: [utf8] = []
    let mut i: i32 = 0
    while i < count {
        let kind: i32 = i32(data[cursor])
        cursor = cursor + 1
        let text: StringRead = read_string(data, cursor)
        cursor = text.next
        if kind == text_static() {
            push(parts, text.value)
        } else {
            let open: utf8 = "{"
            let close: utf8 = "}"
            push(parts, open.concat(text.value).concat(close))
        }
        i = i + 1
    }
    return StringRead { value: join_utf8_parts(parts), next: cursor }
}

micro read_attrs(data: [u8], offset: i32): AttrRead {
    let count: i32 = read_u32(data, offset)
    let mut cursor: i32 = offset + 4
    let mut attrs: [RenderAttr] = []
    let mut i: i32 = 0
    while i < count {
        let name: StringRead = read_string(data, cursor)
        cursor = name.next
        let is_event: bool = data[cursor] != 0
        let is_prop: bool = data[cursor + 1] != 0
        let value_kind: i32 = i32(data[cursor + 2])
        cursor = cursor + 3
        let mut static_value: utf8 = Utf8Text::from_bytes([])
        let mut dynamic_value: utf8 = Utf8Text::from_bytes([])
        if value_kind == attr_static() || value_kind == attr_dynamic() {
            let text: StringRead = read_string(data, cursor)
            cursor = text.next
            if value_kind == attr_static() {
                static_value = text.value
            } else {
                dynamic_value = text.value
            }
        } else {
            let mixed: StringRead = read_text_parts(data, cursor)
            cursor = mixed.next
            dynamic_value = mixed.value
        }
        push(attrs, RenderAttr {
            name: name.value,
            is_event: is_event,
            is_prop: is_prop,
            value_kind: value_kind,
            static_value: static_value,
            dynamic_value: dynamic_value,
        })
        i = i + 1
    }
    return AttrRead { attrs: attrs, next: cursor }
}

micro read_ir_nodes(data: [u8], offset: i32): NodeRead {
    let count: i32 = read_u32(data, offset)
    let mut cursor: i32 = offset + 4
    let mut nodes: [RenderNode] = []
    let mut i: i32 = 0
    while i < count {
        let kind: i32 = i32(data[cursor])
        cursor = cursor + 1
        if kind == node_tag() {
            let tag: StringRead = read_string(data, cursor)
            cursor = tag.next
            let node_kind: i32 = i32(data[cursor])
            cursor = cursor + 1
            let attrs: AttrRead = read_attrs(data, cursor)
            cursor = attrs.next
            let children: NodeRead = read_ir_nodes(data, cursor)
            cursor = children.next
            push(nodes, RenderNode {
                kind: node_tag(),
                tag: tag.value,
                node_kind: node_kind,
                attrs: attrs.attrs,
                children: children.nodes,
                else_children: [],
                text_parts: [],
                cond_expr: "",
                loop_items: "",
                loop_item_var: "",
            })
        } else if kind == node_text() {
            let parts: StringRead = read_text_parts(data, cursor)
            cursor = parts.next
            let mut text_parts: [utf8] = []
            push(text_parts, parts.value)
            push(nodes, RenderNode {
                kind: node_text(),
                tag: "",
                node_kind: 0,
                attrs: [],
                children: [],
                else_children: [],
                text_parts: text_parts,
                cond_expr: "",
                loop_items: "",
                loop_item_var: "",
            })
        } else if kind == node_if() {
            let cond: StringRead = read_string(data, cursor)
            cursor = cond.next
            let then_branch: NodeRead = read_ir_nodes(data, cursor)
            cursor = then_branch.next
            let else_branch: NodeRead = read_ir_nodes(data, cursor)
            cursor = else_branch.next
            push(nodes, RenderNode {
                kind: node_if(),
                tag: "",
                node_kind: 0,
                attrs: [],
                children: then_branch.nodes,
                else_children: else_branch.nodes,
                text_parts: [],
                cond_expr: cond.value,
                loop_items: "",
                loop_item_var: "",
            })
        } else if kind == node_loop() {
            let items: StringRead = read_string(data, cursor)
            cursor = items.next
            let item_var: StringRead = read_string(data, cursor)
            cursor = item_var.next
            let body: NodeRead = read_ir_nodes(data, cursor)
            cursor = body.next
            push(nodes, RenderNode {
                kind: node_loop(),
                tag: "",
                node_kind: 0,
                attrs: [],
                children: body.nodes,
                else_children: [],
                text_parts: [],
                cond_expr: "",
                loop_items: items.value,
                loop_item_var: item_var.value,
            })
        }
        i = i + 1
    }
    return NodeRead { nodes: nodes, next: cursor }
}

micro read_bindings(data: [u8], offset: i32): BindingRead {
    let count: i32 = read_u32(data, offset)
    let mut cursor: i32 = offset + 4
    let mut bindings: [ScriptBinding] = []
    let mut i: i32 = 0
    while i < count {
        let name: StringRead = read_string(data, cursor)
        cursor = name.next
        let init_expr: StringRead = read_string(data, cursor)
        cursor = init_expr.next
        let is_reactive: bool = data[cursor] != 0
        let value_type: i32 = i32(data[cursor + 1])
        cursor = cursor + 2
        push(bindings, ScriptBinding {
            name: name.value,
            init_expr: init_expr.value,
            is_reactive: is_reactive,
            value_type: value_type,
        })
        i = i + 1
    }
    return BindingRead { bindings: bindings, next: cursor }
}

micro header_matches(data: [u8]): bool {
    if data.length < 11 {
        return false
    }
    let magic: [u8] = asgard_ui_magic()
    let mut i: i32 = 0
    while i < magic.length {
        if data[i] != magic[i] {
            return false
        }
        i = i + 1
    }
    return true
}

micro decode_package(data: [u8]): [UiComponent] {
    if !header_matches(data) {
        return []
    }
    let mut offset: i32 = asgard_ui_magic().length
    if offset < data.length && data[offset] == 0x02 {
        offset = offset + 1
    }
    let component_count: i32 = read_u32(data, offset)
    offset = offset + 4
    let mut components: [UiComponent] = []
    let mut i: i32 = 0
    while i < component_count {
        let route: StringRead = read_string(data, offset)
        offset = route.next
        let name: StringRead = read_string(data, offset)
        offset = name.next
        if offset > asgard_ui_magic().length && data[asgard_ui_magic().length] == 0x02 {
            offset = skip_abi_section(data, offset)
        }
        let bindings: BindingRead = read_bindings(data, offset)
        offset = bindings.next
        let nodes: NodeRead = read_ir_nodes(data, offset)
        offset = nodes.next
        push(components, UiComponent {
            route: route.value,
            name: name.value,
            bindings: bindings.bindings,
            nodes: nodes.nodes,
        })
        i = i + 1
    }
    return components
}

micro skip_abi_section(data: [u8], offset: i32): i32 {
    let mut cursor: i32 = offset
    let prop_count: i32 = read_u32(data, cursor)
    cursor = cursor + 4
    let mut pi: i32 = 0
    while pi < prop_count {
        let prop: StringRead = read_string(data, cursor)
        cursor = prop.next
        cursor = cursor + 1
        let flags: i32 = i32(data[cursor])
        cursor = cursor + 1
        if flags & 2 != 0 {
            let def: StringRead = read_string(data, cursor)
            cursor = def.next
        }
        pi = pi + 1
    }
    let event_count: i32 = read_u32(data, cursor)
    cursor = cursor + 4
    let mut ei: i32 = 0
    while ei < event_count {
        let event: StringRead = read_string(data, cursor)
        cursor = event.next
        let param_count: i32 = read_u32(data, cursor)
        cursor = cursor + 4
        let mut pj: i32 = 0
        while pj < param_count {
            let param: StringRead = read_string(data, cursor)
            cursor = param.next
            cursor = cursor + 1
            pj = pj + 1
        }
        ei = ei + 1
    }
    return cursor
}
