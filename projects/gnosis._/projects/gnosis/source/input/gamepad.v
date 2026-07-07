namespace gnosis.input;

# gnosis.input.gamepad: 手柄输入
# 定义手柄标识、按钮 / 摇杆状态与单只手柄的瞬时状态快照。
# 多手柄管理通过各自 GamepadId 的 GamepadState 实例承载。

# ──────────────────────────────────────────────
# GamepadId
# ──────────────────────────────────────────────

⍝ 手柄标识，区分连接的多只手柄。
structure GamepadId {
    ⍝ 手柄的不透明索引，从 0 开始。
    id: u32
}

# ──────────────────────────────────────────────
# GamepadButton / GamepadAxis
# ──────────────────────────────────────────────

⍝ 手柄按钮枚举，覆盖常见布局（兼容 Xbox / PlayStation 命名）。
unite GamepadButton {
    ⍝ 方向键上。
    DPadUp
    ⍝ 方向键下。
    DPadDown
    ⍝ 方向键左。
    DPadLeft
    ⍝ 方向键右。
    DPadRight
    ⍝ 南面按钮（A / Cross）。
    FaceSouth
    ⍝ 东面按钮（B / Circle）。
    FaceEast
    ⍝ 西面按钮（X / Square）。
    FaceWest
    ⍝ 北面按钮（Y / Triangle）。
    FaceNorth
    ⍝ 左肩键（LB / L1）。
    LeftShoulder
    ⍝ 右肩键（RB / R1）。
    RightShoulder
    ⍝ 左扳机键（LT / L2）。
    LeftTrigger
    ⍝ 右扳机键（RT / R2）。
    RightTrigger
    ⍝ 左摇杆按下。
    LeftStick
    ⍝ 右摇杆按下。
    RightStick
    ⍝ Start / Menu 键。
    Start
    ⍝ Back / Share 键。
    Back
}

⍝ 手柄模拟量轴索引。
unite GamepadAxis {
    ⍝ 左摇杆 X 轴（左右）。
    LeftX
    ⍝ 左摇杆 Y 轴（上下）。
    LeftY
    ⍝ 右摇杆 X 轴。
    RightX
    ⍝ 右摇杆 Y 轴。
    RightY
    ⍝ 左扳机模拟量。
    LeftTrigger
    ⍝ 右扳机模拟量。
    RightTrigger
}

# ──────────────────────────────────────────────
# ButtonAxis
# ──────────────────────────────────────────────

⍝ 手柄按钮 / 轴状态快照。
structure ButtonAxis {
    ⍝ 按钮是否按下（轴超过阈值时视为按下）。
    pressed: bool
    ⍝ 模拟量值，摇杆范围 [-1.0, 1.0]，扳机范围 [0.0, 1.0]。
    value: f32
}

# ──────────────────────────────────────────────
# GamepadState
# ──────────────────────────────────────────────

⍝ 手柄状态，记录一只手柄全部按钮与轴的瞬时值。
class GamepadState {
    ⍝ 手柄标识。
    _id: GamepadId
    ⍝ 是否已连接。
    _connected: bool
}

imply GamepadState {
    ⍝ 按手柄标识构造状态，默认未连接。
    micro new(id: GamepadId): Self {
        return GamepadState {
            _id: id,
            _connected: false,
        }
    }

    ⍝ 返回手柄标识。
    micro id(self): GamepadId {
        return self._id
    }

    ⍝ 查询手柄是否已连接。
    micro connected(self): bool {
        return self._connected
    }

    ⍝ 设置连接状态。
    micro set_connected(mut self, connected: bool): unit {
        self._connected = connected
    }

    ⍝ 查询指定按钮的状态。
    [host_contract]
    micro button(self, button: GamepadButton): ButtonAxis {
        return ButtonAxis { pressed: false, value: 0.0 }
    }

    ⍝ 查询指定轴的模拟量值。
    [host_contract]
    micro axis(self, axis: GamepadAxis): f32 {
        return 0.0
    }
}
