# VOA Todo 数据层 — 可编译 store（合并进 WASM）

let mut todos_sig: i32 = 0
let mut filter_store_sig: i32 = 0
let mut next_id: i32 = 4

micro init_todo_store() {
    todos_sig = sig_create_list([])
    filter_store_sig = sig_create_utf8("all")
}

micro get_todos(): list {
    let all: list = sig_get_list(todos_sig)
    let filter: utf8 = sig_get_utf8(filter_store_sig)
    if filter == "active" {
        let result: list = []
        loop t in all {
            if !t.done { result = push_back(result, t) }
        }
        return result
    }
    if filter == "done" {
        let result: list = []
        loop t in all {
            if t.done { result = push_back(result, t) }
        }
        return result
    }
    return all
}

micro get_all_todos(): list { return sig_get_list(todos_sig) }

micro get_filter(): utf8 { return sig_get_utf8(filter_store_sig) }

micro set_filter(f: utf8) {
    sig_set_utf8(filter_store_sig, f)
    store_bump()
}

micro add_todo(text: utf8) {
    let trimmed: utf8 = trim(text)
    if trimmed == "" { return }
    let item: list = []
    let all: list = sig_get_list(todos_sig)
    sig_set_list(todos_sig, push_back(all, item))
    next_id = next_id + 1
    store_bump()
}

micro toggle_todo(id: i32) { store_bump() }

micro remove_todo(id: i32) { store_bump() }

micro clear_done() { store_bump() }

micro count_active(): i32 {
    let count: i32 = 0
    let all: list = sig_get_list(todos_sig)
    loop t in all {
        if !t.done { count = count + 1 }
    }
    return count
}

micro count_done(): i32 {
    let count: i32 = 0
    let all: list = sig_get_list(todos_sig)
    loop t in all {
        if t.done { count = count + 1 }
    }
    return count
}

micro count_all(): i32 {
    let count: i32 = 0
    loop _t in sig_get_list(todos_sig) { count = count + 1 }
    return count
}

micro push_back(lst: list, item: list): list { return lst }

micro trim(s: utf8): utf8 { return s }
