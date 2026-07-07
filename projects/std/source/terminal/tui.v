namespace std.terminal;

# widget 种类常量
micro widget_kind_column() -> i32 { return 0 }
micro widget_kind_row() -> i32 { return 1 }
micro widget_kind_box() -> i32 { return 2 }
micro widget_kind_text() -> i32 { return 3 }
micro widget_kind_button() -> i32 { return 4 }
micro widget_kind_item() -> i32 { return 5 }
micro widget_kind_checkbox() -> i32 { return 6 }
micro widget_kind_radio() -> i32 { return 7 }
micro widget_kind_list() -> i32 { return 8 }

# 按键码常量
micro key_unknown() -> i32 { return 0 }
micro key_up() -> i32 { return 1 }
micro key_down() -> i32 { return 2 }
micro key_left() -> i32 { return 3 }
micro key_right() -> i32 { return 4 }
micro key_home() -> i32 { return 5 }
micro key_end() -> i32 { return 6 }
micro key_pageup() -> i32 { return 7 }
micro key_pagedown() -> i32 { return 8 }
micro key_enter() -> i32 { return 9 }
micro key_tab() -> i32 { return 10 }
micro key_backtab() -> i32 { return 11 }
micro key_backspace() -> i32 { return 12 }
micro key_esc() -> i32 { return 13 }
micro key_char() -> i32 { return 14 }

# focusable 种类常量
micro focus_kind_button() -> i32 { return 0 }
micro focus_kind_item() -> i32 { return 1 }
micro focus_kind_checkbox() -> i32 { return 2 }
micro focus_kind_radio() -> i32 { return 3 }

# widget 节点：TUI 渲染树的基本单元
structure Widget {
    kind: i32
    text: utf8
    event: utf8
    binding: utf8
    option: utf8
    children: ArrayList<Widget>
}

# 可聚焦元素：参与 2D 方向导航与 Tab 线性步进
structure Focusable {
    row: i32
    col: i32
    width: i32
    kind: i32
    label: utf8
    event: utf8
    binding: utf8
    option: utf8
}

# 绑定存储条目：name -> value 字符串映射
structure Binding {
    name: utf8
    value: utf8
}

# TUI 运行时状态：widget 树 + 绑定 + focusable 列表 + 焦点索引 + 终端尺寸
structure TuiRuntime {
    roots: ArrayList<Widget>
    bindings: ArrayList<Binding>
    focusables: ArrayList<Focusable>
    focus_index: i32
    last_char: i32
    term_rows: i32
    term_cols: i32
}

# 全局 TuiRuntime 单例存储（host_contract，待 V 编译器补全局可变变量后移除）
[host_contract]
micro tui_global_get() -> TuiRuntime

[host_contract]
micro tui_global_set(rt: TuiRuntime) -> unit

# widget 构建原语：AWSL lower 生成调用这些原语的 V synthetic code
micro widget_column(children: ArrayList<Widget>) -> Widget {
    return Widget { kind: 0, text: "", event: "", binding: "", option: "", children: children }
}

micro widget_row(children: ArrayList<Widget>) -> Widget {
    return Widget { kind: 1, text: "", event: "", binding: "", option: "", children: children }
}

micro widget_box(children: ArrayList<Widget>) -> Widget {
    return Widget { kind: 2, text: "", event: "", binding: "", option: "", children: children }
}

micro widget_text(text: utf8) -> Widget {
    return Widget { kind: 3, text: text, event: "", binding: "", option: "", children: ArrayList::new(0) }
}

micro widget_button(label: utf8, event: utf8) -> Widget {
    return Widget { kind: 4, text: label, event: event, binding: "", option: "", children: ArrayList::new(0) }
}

micro widget_item(label: utf8, event: utf8) -> Widget {
    return Widget { kind: 5, text: label, event: event, binding: "", option: "", children: ArrayList::new(0) }
}

micro widget_checkbox(label: utf8, event: utf8, binding: utf8) -> Widget {
    return Widget { kind: 6, text: label, event: event, binding: binding, option: "", children: ArrayList::new(0) }
}

micro widget_radio(label: utf8, event: utf8, binding: utf8, option: utf8) -> Widget {
    return Widget { kind: 7, text: label, event: event, binding: binding, option: option, children: ArrayList::new(0) }
}

micro widget_list(children: ArrayList<Widget>) -> Widget {
    return Widget { kind: 8, text: "", event: "", binding: "", option: "", children: children }
}

# 绑定注册原语：AWSL lower 在 mount 时为每个 let mut 绑定调用
micro tui_register_binding(name: utf8, value: utf8) -> unit {
    let mut rt: TuiRuntime = tui_global_get()
    rt.binding_set(name, value)
    tui_global_set(rt)
}

# 绑定读取原语：AWSL lower 生成的动态文本 / 条件表达式调用
micro tui_binding_get(name: utf8) -> utf8 {
    let rt: TuiRuntime = tui_global_get()
    return rt.binding_get(name)
}

# 绑定真值判定：条件渲染（if）使用
micro tui_binding_truthy(name: utf8) -> bool {
    let rt: TuiRuntime = tui_global_get()
    return rt.binding_truthy(name)
}

# 重挂载原语：事件处理器调用后重建 widget 树并重渲染
micro tui_remount(roots: ArrayList<Widget>) -> unit {
    let mut rt: TuiRuntime = tui_global_get()
    rt.mount(roots)
}

imply TuiRuntime {
    micro new() -> Self {
        return TuiRuntime {
            roots: ArrayList::new(16),
            bindings: ArrayList::new(16),
            focusables: ArrayList::new(64),
            focus_index: 0,
            last_char: 0,
            term_rows: 24,
            term_cols: 80
        }
    }

    micro mount(mut self, roots: ArrayList<Widget>) -> unit {
        self.roots = roots
        self.render()
    }

    micro binding_get(self, name: utf8) -> utf8 {
        let mut i: usize = 0
        while i < self.bindings.length() {
            let b: Binding = self.bindings.get(i + 1).unwrap()
            if b.name == name {
                return b.value
            }
            i = i + 1
        }
        return ""
    }

    micro binding_truthy(self, name: utf8) -> bool {
        let v: utf8 = self.binding_get(name)
        if v == "" {
            return false
        }
        if v == "0" {
            return false
        }
        if v == "false" {
            return false
        }
        return true
    }

    micro binding_set(mut self, name: utf8, value: utf8) -> unit {
        let mut i: usize = 0
        while i < self.bindings.length() {
            let b: Binding = self.bindings.get(i + 1).unwrap()
            if b.name == name {
                self.bindings.set(i + 1, Binding { name: name, value: value })
                return
            }
            i = i + 1
        }
        self.bindings.push(Binding { name: name, value: value })
    }

    micro binding_toggle(mut self, name: utf8) -> unit {
        if self.binding_truthy(name) {
            self.binding_set(name, "0")
        } else {
            self.binding_set(name, "1")
        }
    }

    micro patch(mut self, name: utf8, value: utf8) -> unit {
        self.binding_set(name, value)
        self.render()
    }

    micro register_focusable(mut self, row: i32, col: i32, label: utf8, event: utf8, kind: i32, binding: utf8, option: utf8) -> unit {
        let width: i32 = label.length() + 4
        self.focusables.push(Focusable {
            row: row,
            col: col,
            width: width,
            kind: kind,
            label: label,
            event: event,
            binding: binding,
            option: option
        })
    }

    micro render(mut self) -> unit {
        self.term_rows = size_rows()
        self.term_cols = size_cols()
        if self.term_rows == 0 {
            self.term_rows = 24
        }
        if self.term_cols == 0 {
            self.term_cols = 80
        }
        clear()
        self.focusables.clear()
        let mut row: i32 = 0
        let mut remaining: i32 = self.term_rows
        let mut i: usize = 0
        while i < self.roots.length() {
            if remaining <= 0 {
                break
            }
            let w: Widget = self.roots.get(i + 1).unwrap()
            let used: i32 = self.render_widget(w, row, 0, self.term_cols, remaining)
            row = row + used
            remaining = remaining - used
            i = i + 1
        }
        self.render_focus_highlight()
        self.render_help_bar()
        flush()
    }

    micro render_widget(mut self, w: Widget, row: i32, col: i32, width: i32, height: i32) -> i32 {
        if width <= 0 || height <= 0 {
            return 0
        }
        if w.kind == 0 {
            return self.render_column(w.children, row, col, width, height)
        }
        if w.kind == 1 {
            return self.render_row(w.children, row, col, width, height)
        }
        if w.kind == 2 {
            return self.render_box(w.children, row, col, width, height)
        }
        if w.kind == 3 {
            self.draw_text(row, col, w.text)
            return 1
        }
        if w.kind == 4 {
            let display: utf8 = "[ " + w.text + " ]"
            self.draw_text(row, col, display)
            self.register_focusable(row, col, w.text, w.event, 0, "", "")
            return 1
        }
        if w.kind == 5 {
            let display: utf8 = "  " + w.text
            self.draw_text(row, col, display)
            self.register_focusable(row, col, w.text, w.event, 1, "", "")
            return 1
        }
        if w.kind == 6 {
            let mark: utf8 = "[ ] "
            if self.binding_truthy(w.binding) {
                mark = "[x] "
            }
            let display: utf8 = mark + w.text
            self.draw_text(row, col, display)
            self.register_focusable(row, col, w.text, w.event, 2, w.binding, "")
            return 1
        }
        if w.kind == 7 {
            let mark: utf8 = "( ) "
            if self.binding_get(w.binding) == w.option {
                mark = "(x) "
            }
            let display: utf8 = mark + w.text
            self.draw_text(row, col, display)
            self.register_focusable(row, col, w.text, w.event, 3, w.binding, w.option)
            return 1
        }
        if w.kind == 8 {
            return self.render_column(w.children, row, col, width, height)
        }
        return 0
    }

    micro render_column(mut self, children: ArrayList<Widget>, row: i32, col: i32, width: i32, height: i32) -> i32 {
        let mut cur_row: i32 = row
        let mut remaining: i32 = height
        let mut i: usize = 0
        while i < children.length() {
            if remaining <= 0 {
                break
            }
            let child: Widget = children.get(i + 1).unwrap()
            let used: i32 = self.render_widget(child, cur_row, col, width, remaining)
            cur_row = cur_row + used
            remaining = remaining - used
            i = i + 1
        }
        return cur_row - row
    }

    micro render_row(mut self, children: ArrayList<Widget>, row: i32, col: i32, width: i32, height: i32) -> i32 {
        let count: i32 = children.length() as i32
        if count == 0 {
            return 0
        }
        let child_width: i32 = width / count
        let mut cur_col: i32 = col
        let mut max_height: i32 = 0
        let mut i: usize = 0
        while i < children.length() {
            let mut actual_w: i32 = child_width
            if i as i32 == count - 1 {
                actual_w = width - child_width * (count - 1)
            }
            let child: Widget = children.get(i + 1).unwrap()
            let used: i32 = self.render_widget(child, row, cur_col, actual_w, height)
            cur_col = cur_col + actual_w
            if used > max_height {
                max_height = used
            }
            i = i + 1
        }
        return max_height
    }

    micro render_box(mut self, children: ArrayList<Widget>, row: i32, col: i32, width: i32, height: i32) -> i32 {
        self.draw_box_border(row, col, width, height)
        if width >= 2 && height >= 2 {
            self.render_column(children, row + 1, col + 1, width - 2, height - 2)
        }
        return height
    }

    micro draw_text(self, row: i32, col: i32, text: utf8) -> unit {
        if row < 0 || row >= self.term_rows {
            return
        }
        if col < 0 || col >= self.term_cols {
            return
        }
        move_to(row, col)
        put_str(text)
    }

    micro draw_box_border(self, row: i32, col: i32, width: i32, height: i32) -> unit {
        if width < 1 || height < 1 {
            return
        }
        self.draw_char_at(row, col, 43)
        if width > 1 {
            self.draw_char_at(row, col + width - 1, 43)
        }
        if height > 1 {
            self.draw_char_at(row + height - 1, col, 43)
            if width > 1 {
                self.draw_char_at(row + height - 1, col + width - 1, 43)
            }
        }
        let mut c: i32 = col + 1
        while c < col + width - 1 {
            self.draw_char_at(row, c, 45)
            if height > 1 {
                self.draw_char_at(row + height - 1, c, 45)
            }
            c = c + 1
        }
        let mut r: i32 = row + 1
        while r < row + height - 1 {
            self.draw_char_at(r, col, 124)
            if width > 1 {
                self.draw_char_at(r, col + width - 1, 124)
            }
            r = r + 1
        }
    }

    micro draw_char_at(self, row: i32, col: i32, ch: i32) -> unit {
        if row < 0 || row >= self.term_rows {
            return
        }
        if col < 0 || col >= self.term_cols {
            return
        }
        move_to(row, col)
        put_char(ch)
    }

    micro render_focus_highlight(self) -> unit {
        if self.focusables.length() == 0 {
            return
        }
        if self.focus_index >= self.focusables.length() as i32 {
            self.focus_index = 0
        }
        let f: Focusable = self.focusables.get(self.focus_index as usize + 1).unwrap()
        move_to(f.row, f.col)
        set_reverse(1)
        if f.kind == 1 {
            put_str("> " + f.label)
        } else if f.kind == 2 {
            if self.binding_truthy(f.binding) {
                put_str("[x] " + f.label)
            } else {
                put_str("[ ] " + f.label)
            }
        } else if f.kind == 3 {
            if self.binding_get(f.binding) == f.option {
                put_str("(x) " + f.label)
            } else {
                put_str("( ) " + f.label)
            }
        } else {
            put_str("[ " + f.label + " ]")
        }
        set_reverse(0)
    }

    micro render_help_bar(self) -> unit {
        if self.term_rows >= 2 {
            move_to(self.term_rows - 1, 0)
        } else {
            move_to(0, 0)
        }
        put_str("Arrows/hjkl: navigate | Enter/Space: activate | Tab: next | q/Esc: quit")
    }

    micro find_in_direction(self, direction: i32) -> i32 {
        if self.focusables.length() == 0 {
            return 0
        }
        let cur: Focusable = self.focusables.get(self.focus_index as usize + 1).unwrap()
        let mut best: i32 = -1
        let mut best_dist: i32 = 2147483647
        let mut i: usize = 0
        while i < self.focusables.length() {
            if i as i32 == self.focus_index {
                i = i + 1
                continue
            }
            let f: Focusable = self.focusables.get(i + 1).unwrap()
            let dr: i32 = f.row - cur.row
            let dc: i32 = f.col - cur.col
            let mut valid: bool = false
            let mut primary: i32 = 0
            let mut secondary: i32 = 0
            if direction == 1 {
                if dr < 0 {
                    valid = true
                    primary = -dr
                    if dc < 0 {
                        secondary = -dc
                    } else {
                        secondary = dc
                    }
                }
            } else if direction == 2 {
                if dr > 0 {
                    valid = true
                    primary = dr
                    if dc < 0 {
                        secondary = -dc
                    } else {
                        secondary = dc
                    }
                }
            } else if direction == 3 {
                if dc < 0 {
                    valid = true
                    primary = -dc
                    if dr < 0 {
                        secondary = -dr
                    } else {
                        secondary = dr
                    }
                }
            } else if direction == 4 {
                if dc > 0 {
                    valid = true
                    primary = dc
                    if dr < 0 {
                        secondary = -dr
                    } else {
                        secondary = dr
                    }
                }
            }
            if valid {
                let dist: i32 = primary * 1000 + secondary
                if dist < best_dist {
                    best_dist = dist
                    best = i as i32
                }
            }
            i = i + 1
        }
        if best >= 0 {
            return best
        }
        return self.focus_index
    }

    micro find_linear(self, forward: bool, step: i32) -> i32 {
        if self.focusables.length() == 0 {
            return 0
        }
        if self.focusables.length() == 1 {
            return 0
        }
        let count: i32 = self.focusables.length() as i32
        let mut idx: i32 = self.focus_index
        if forward {
            idx = idx + step
            while idx >= count {
                idx = idx - count
            }
        } else {
            idx = idx - step
            while idx < 0 {
                idx = idx + count
            }
        }
        return idx
    }

    micro activate_current(mut self) -> unit {
        if self.focusables.length() == 0 {
            return
        }
        if self.focus_index >= self.focusables.length() as i32 {
            self.focus_index = 0
        }
        let f: Focusable = self.focusables.get(self.focus_index as usize + 1).unwrap()
        if f.kind == 2 {
            self.binding_toggle(f.binding)
            self.render()
            return
        }
        if f.kind == 3 {
            self.binding_set(f.binding, f.option)
            self.render()
            return
        }
        if f.event != "" {
            tui_invoke_event(f.event)
        }
    }

    micro run(mut self) -> i32 {
        enter_alt_screen()
        self.render()
        let running: bool = true
        while running {
            let key: i32 = poll_key()
            if key < 0 {
                sleep_ms(10)
                continue
            }
            if key == 13 {
                break
            }
            if key == 14 {
                if self.last_char == 113 {
                    break
                }
                if self.last_char == 81 {
                    break
                }
                if self.last_char == 104 {
                    self.focus_index = self.find_in_direction(3)
                    self.render()
                    continue
                }
                if self.last_char == 106 {
                    self.focus_index = self.find_in_direction(2)
                    self.render()
                    continue
                }
                if self.last_char == 107 {
                    self.focus_index = self.find_in_direction(1)
                    self.render()
                    continue
                }
                if self.last_char == 108 {
                    self.focus_index = self.find_in_direction(4)
                    self.render()
                    continue
                }
                if self.last_char == 32 {
                    self.activate_current()
                    continue
                }
                if self.last_char >= 49 && self.last_char <= 57 {
                    let idx: i32 = self.last_char - 49
                    if idx < self.focusables.length() as i32 {
                        self.focus_index = idx
                        self.activate_current()
                    }
                    continue
                }
                continue
            }
            if key == 1 {
                self.focus_index = self.find_in_direction(1)
                self.render()
                continue
            }
            if key == 2 {
                self.focus_index = self.find_in_direction(2)
                self.render()
                continue
            }
            if key == 3 {
                self.focus_index = self.find_in_direction(3)
                self.render()
                continue
            }
            if key == 4 {
                self.focus_index = self.find_in_direction(4)
                self.render()
                continue
            }
            if key == 5 {
                self.focus_index = 0
                self.render()
                continue
            }
            if key == 6 {
                if self.focusables.length() > 0 {
                    self.focus_index = self.focusables.length() as i32 - 1
                }
                self.render()
                continue
            }
            if key == 7 {
                self.focus_index = self.find_linear(false, 5)
                self.render()
                continue
            }
            if key == 8 {
                self.focus_index = self.find_linear(true, 5)
                self.render()
                continue
            }
            if key == 10 {
                self.focus_index = self.find_linear(true, 1)
                self.render()
                continue
            }
            if key == 11 {
                self.focus_index = self.find_linear(false, 1)
                self.render()
                continue
            }
            if key == 12 {
                self.focus_index = self.find_linear(false, 1)
                self.render()
                continue
            }
            if key == 9 {
                self.activate_current()
                continue
            }
        }
        exit_alt_screen()
        return 0
    }
}

# 事件派发：按名调用 awsl_call_* export
# asgard lower 阶段为本函数生成按字符串比较的 if-else 链，分派到所有 awsl_call_* 符号
micro tui_invoke_event(name: utf8) -> unit {
    asgard_invoke_export(name)
}

# asgard_invoke_export：由 asgard lower 生成的派发器入口
# 形如：if name == "awsl_call_on_inc" { awsl_call_on_inc(); return } ...
# 此处为占位声明，asgard codegen 会替换为真实实现
micro asgard_invoke_export(name: utf8) -> unit

# TUI 主入口：挂载 widget 树并启动事件循环
micro asgard_terminal_run(roots: ArrayList<Widget>) -> i32 {
    let mut rt: TuiRuntime = TuiRuntime::new()
    tui_global_set(rt)
    rt.mount(roots)
    let ret: i32 = rt.run()
    return ret
}

# patch 入口：外部更新绑定值并重渲染
micro asgard_terminal_patch(name: utf8, value: utf8) -> unit {
    let mut rt: TuiRuntime = tui_global_get()
    rt.patch(name, value)
    tui_global_set(rt)
}
