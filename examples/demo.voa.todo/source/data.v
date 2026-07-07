# VOA Todo 数据层 — 可编译 store（合并进 WASM）

singleton TodoStore {
    mut todos_sig: i32 = 0;
    mut filter_store_sig: i32 = 0;
    mut next_id: i32 = 4;

    micro init(mut self) {
        self.todos_sig = sig_create_list([])
        self.filter_store_sig = sig_create_utf8("all")
    }

    micro get_todos(self): list {
        let all: list = sig_get_list(self.todos_sig)
        let filter: utf8 = sig_get_utf8(self.filter_store_sig)
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

    micro get_all_todos(self): list { return sig_get_list(self.todos_sig) }

    micro get_filter(self): utf8 { return sig_get_utf8(self.filter_store_sig) }

    micro set_filter(mut self, f: utf8) {
        sig_set_utf8(self.filter_store_sig, f)
        store_bump()
    }

    micro add_todo(mut self, text: utf8) {
        let trimmed: utf8 = trim(text)
        if trimmed == "" { return }
        let item: list = []
        let all: list = sig_get_list(self.todos_sig)
        sig_set_list(self.todos_sig, push_back(all, item))
        self.next_id = self.next_id + 1
        store_bump()
    }

    micro toggle_todo(mut self, id: i32) { store_bump() }

    micro remove_todo(mut self, id: i32) { store_bump() }

    micro clear_done(mut self) { store_bump() }

    micro count_active(self): i32 {
        let count: i32 = 0
        let all: list = sig_get_list(self.todos_sig)
        loop t in all {
            if !t.done { count = count + 1 }
        }
        return count
    }

    micro count_done(self): i32 {
        let count: i32 = 0
        let all: list = sig_get_list(self.todos_sig)
        loop t in all {
            if t.done { count = count + 1 }
        }
        return count
    }

    micro count_all(self): i32 {
        let count: i32 = 0
        loop _t in sig_get_list(self.todos_sig) { count = count + 1 }
        return count
    }
}

micro init_todo_store() { TodoStore.init() }

micro get_todos(): list { return TodoStore.get_todos() }

micro get_all_todos(): list { return TodoStore.get_all_todos() }

micro get_filter(): utf8 { return TodoStore.get_filter() }

micro set_filter(f: utf8) { TodoStore.set_filter(f) }

micro add_todo(text: utf8) { TodoStore.add_todo(text) }

micro toggle_todo(id: i32) { TodoStore.toggle_todo(id) }

micro remove_todo(id: i32) { TodoStore.remove_todo(id) }

micro clear_done() { TodoStore.clear_done() }

micro count_active(): i32 { return TodoStore.count_active() }

micro count_done(): i32 { return TodoStore.count_done() }

micro count_all(): i32 { return TodoStore.count_all() }

micro push_back(lst: list, item: list): list { return lst }

micro trim(s: utf8): utf8 { return s }
