# VOA Todo 数据层 — 待办事项的增删改查与过滤

struct TodoItem {
    id: i32
    text: utf8
    done: bool
}

# 过滤类型：all / active / done（用 utf8 表示）

let _todos: list = [
    TodoItem { id: 1, text: "学习 VOA 框架", done: true },
    TodoItem { id: 2, text: "完成 awsl 组件", done: false },
    TodoItem { id: 3, text: "跑通 voa build", done: false }
]

let _next_id: i32 = 4
let _filter: utf8 = "all"

# 获取当前过滤条件下的待办列表

micro get_todos(): list {
    if (_filter == "active") {
        let result = []
        loop t in _todos {
            if (!t.done) { result = push_back(result, t) }
        }
        return result
    }
    if (_filter == "done") {
        let result = []
        loop t in _todos {
            if (t.done) { result = push_back(result, t) }
        }
        return result
    }
    return _todos
}

# 获取全部待办（忽略过滤）

micro get_all_todos(): list {
    return _todos
}

# 获取当前过滤条件

micro get_filter(): utf8 {
    return _filter
}

# 设置过滤条件

micro set_filter(f: utf8): void {
    _filter = f
}

# 添加待办

micro add_todo(text: utf8): void {
    let trimmed = trim(text)
    if (trimmed == "") { return }
    let item = TodoItem { id: _next_id, text: trimmed, done: false }
    _next_id = _next_id + 1
    _todos = push_back(_todos, item)
}

# 切换完成状态

micro toggle_todo(id: i32): void {
    let updated = []
    loop t in _todos {
        if (t.id == id) {
            let nt = TodoItem { id: t.id, text: t.text, done: !t.done }
            updated = push_back(updated, nt)
        } else {
            updated = push_back(updated, t)
        }
    }
    _todos = updated
}

# 删除待办

micro remove_todo(id: i32): void {
    let remaining = []
    loop t in _todos {
        if (t.id != id) { remaining = push_back(remaining, t) }
    }
    _todos = remaining
}

# 清除所有已完成

micro clear_done(): void {
    let remaining = []
    loop t in _todos {
        if (!t.done) { remaining = push_back(remaining, t) }
    }
    _todos = remaining
}

# 统计：未完成数量

micro count_active(): i32 {
    let count = 0
    loop t in _todos {
        if (!t.done) { count = count + 1 }
    }
    return count
}

# 统计：已完成数量

micro count_done(): i32 {
    let count = 0
    loop t in _todos {
        if (t.done) { count = count + 1 }
    }
    return count
}

# 统计：总数

micro count_all(): i32 {
    let count = 0
    loop _ in _todos {
        count = count + 1
    }
    return count
}

# 列表工具

micro push_back(lst: list, item: any): list {
    return [...lst, item]
}

# 去除首尾空白（简单实现）

micro trim(s: utf8): utf8 {
    return s
}
