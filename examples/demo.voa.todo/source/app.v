# VOA Todo 应用入口
# 注册路由并挂载到 DOM

import voa-todo.data

[js]
micro voa_register_route(path: utf8, page_name: utf8): i32

[js]
micro voa_mount(selector: utf8): i32

[js]
micro voa_log(msg: utf8): void

# 注册路由

micro register_routes(): void {
    voa_register_route("/", "todo")
    voa_register_route("/active", "todo")
    voa_register_route("/done", "todo")
}

# 应用主入口

[main]
micro main(): unit {
    voa_log("VOA Todo 启动")
    register_routes()
    voa_mount("#app")
    voa_log("VOA Todo 启动完成")
}
