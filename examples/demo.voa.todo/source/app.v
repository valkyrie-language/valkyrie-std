# VOA Admin 应用入口
# 注册路由、认证守卫、挂载根组件

import voa-admin.data

# 路由与挂载（由 voa-runtime.js 提供）

[js]
micro voa_register_route(path: string, page_name: string): i32

[js]
micro voa_mount(selector: string): i32

[js]
micro voa_navigate(path: string, replace: bool): void

[js]
micro voa_get_current_path(): string

[js]
micro voa_log(msg: string): void

# 检查认证状态，未认证时重定向到登录页

micro require_auth(): bool {
    if (!is_authenticated()) {
        voa_navigate("/login", true)
        return false
    }
    return true
}

# 注册全部路由

micro register_routes(): void {
    voa_register_route("/login", "login")
    voa_register_route("/dashboard", "dashboard")
    voa_register_route("/users", "users")
    voa_register_route("/users/:id", "users")
    voa_register_route("/settings", "settings")
}

# 应用主入口

[main]
micro main(): unit {
    voa_log("VOA Admin 启动中...")

    register_routes()

    # 初始路由守卫：如果当前路径不是 /login 且未认证，重定向到 /login
    let current_path = voa_get_current_path()
    if (current_path != "/login") {
        if (!is_authenticated()) {
            voa_navigate("/login", true)
        }
    }

    # 挂载应用到 #app
    voa_mount("#app")

    voa_log("VOA Admin 启动完成")
}
