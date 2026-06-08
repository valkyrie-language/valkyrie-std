# VOA 实时仪表盘数据层 — 使用静态数据

struct MetricPoint {
    timestamp: i32
    value: i32
}

struct ServiceInfo {
    name: string
    status: string
    latency: i32
}

struct AlertInfo {
    severity: string
    message: string
    time: string
}

struct DashboardState {
    connected: bool
    cpu_usage: list
    active_connections: i32
    total_requests: i32
    avg_response_time: i32
    memory_usage: list
    services: list
    alerts: list
    uptime: string
}

let _state = DashboardState {
    connected: true
    cpu_usage: [
        MetricPoint { timestamp: 0, value: 45 },
        MetricPoint { timestamp: 1, value: 62 },
        MetricPoint { timestamp: 2, value: 38 },
        MetricPoint { timestamp: 3, value: 71 },
        MetricPoint { timestamp: 4, value: 55 },
        MetricPoint { timestamp: 5, value: 48 },
        MetricPoint { timestamp: 6, value: 67 },
        MetricPoint { timestamp: 7, value: 52 },
        MetricPoint { timestamp: 8, value: 41 },
        MetricPoint { timestamp: 9, value: 59 }
    ]
    active_connections: 142
    total_requests: 28471
    avg_response_time: 23
    memory_usage: [
        MetricPoint { timestamp: 0, value: 35 },
        MetricPoint { timestamp: 1, value: 42 },
        MetricPoint { timestamp: 2, value: 38 },
        MetricPoint { timestamp: 3, value: 47 },
        MetricPoint { timestamp: 4, value: 44 },
        MetricPoint { timestamp: 5, value: 39 }
    ]
    services: [
        ServiceInfo { name: "API Gateway", status: "healthy", latency: 12 },
        ServiceInfo { name: "Auth Service", status: "healthy", latency: 8 },
        ServiceInfo { name: "Database", status: "healthy", latency: 3 },
        ServiceInfo { name: "Cache", status: "degraded", latency: 45 }
    ]
    alerts: [
        AlertInfo { severity: "warning", message: "缓存服务延迟升高", time: "14:32" },
        AlertInfo { severity: "info", message: "新版本 v2.1.0 可用", time: "13:15" }
    ]
    uptime: "7d 12h 35m"
}

micro get_dashboard_state(): DashboardState {
    return _state
}

micro connect_websocket(url: string): void {
    _state.connected = true
}

micro disconnect_websocket(): void {
    _state.connected = false
}