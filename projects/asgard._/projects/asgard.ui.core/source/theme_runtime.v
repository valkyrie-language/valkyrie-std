# 主题运行时辅助 —— 跨平台系统颜色模式解析
#
# 站点 mode 含 Auto：跟随系统。主题 mode 本身只有 Light / Night，无 Auto 概念。
# 本模块负责把站点 Auto 解析成实际 Light / Night。
# 各后端通过覆盖 `resolve_system_mode` 提供平台实现：
#   - 浏览器：matchMedia('(prefers-color-scheme: dark)')
#   - 微信小程序：wx.getSystemInfoSync().theme
#   - 原生：平台系统 API
# 未知平台默认 Light。

/// 解析系统当前颜色模式偏好。
/// 返回 "light" 或 "night"。未知平台默认 "light"。
micro resolve_system_mode(): string {
    return "light"
}

/// 把站点 mode 解析为实际主题 mode。
/// site_mode = "auto" 时跟随系统；否则原样返回。
micro resolve_theme_mode(site_mode: string): string {
    if site_mode == "auto" {
        return resolve_system_mode()
    }
    return site_mode
}

# ===== 浏览器后端实现（WASM/JS） =====
[js]
micro resolve_system_mode(): string
