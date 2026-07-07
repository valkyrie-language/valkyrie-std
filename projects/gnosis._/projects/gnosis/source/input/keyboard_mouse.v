namespace gnosis.input;

# gnosis.input.keyboard_mouse: 键鼠输入
# 定义键盘键码、鼠标按键与键鼠状态快照。
# 实际平台采样由宿主 adaptor 写入 KeyboardMouseState。

# ──────────────────────────────────────────────
# KeyCode
# ──────────────────────────────────────────────

⍝ 键盘键码，覆盖常见游戏控制键。
unite KeyCode {
    ⍝ 字母 A。
    A
    ⍝ 字母 B。
    B
    ⍝ 字母 C。
    C
    ⍝ 字母 D。
    D
    ⍝ 字母 E。
    E
    ⍝ 字母 F。
    F
    ⍝ 字母 G。
    G
    ⍝ 字母 H。
    H
    ⍝ 字母 I。
    I
    ⍝ 字母 J。
    J
    ⍝ 字母 K。
    K
    ⍝ 字母 L。
    L
    ⍝ 字母 M。
    M
    ⍝ 字母 N。
    N
    ⍝ 字母 O。
    O
    ⍝ 字母 P。
    P
    ⍝ 字母 Q。
    Q
    ⍝ 字母 R。
    R
    ⍝ 字母 S。
    S
    ⍝ 字母 T。
    T
    ⍝ 字母 U。
    U
    ⍝ 字母 V。
    V
    ⍝ 字母 W。
    W
    ⍝ 字母 X。
    X
    ⍝ 字母 Y。
    Y
    ⍝ 字母 Z。
    Z
    ⍝ 数字 0。
    Digit0
    ⍝ 数字 1。
    Digit1
    ⍝ 数字 2。
    Digit2
    ⍝ 数字 3。
    Digit3
    ⍝ 数字 4。
    Digit4
    ⍝ 数字 5。
    Digit5
    ⍝ 数字 6。
    Digit6
    ⍝ 数字 7。
    Digit7
    ⍝ 数字 8。
    Digit8
    ⍝ 数字 9。
    Digit9
    ⍝ 空格键。
    Space
    ⍝ 回车键。
    Enter
    ⍝ 退格键。
    Backspace
    ⍝ Tab 键。
    Tab
    ⍝ 左 Shift。
    LeftShift
    ⍝ 右 Shift。
    RightShift
    ⍝ 左 Ctrl。
    LeftCtrl
    ⍝ 右 Ctrl。
    RightCtrl
    ⍝ 左 Alt。
    LeftAlt
    ⍝ 右 Alt。
    RightAlt
    ⍝ 上方向键。
    ArrowUp
    ⍝ 下方向键。
    ArrowDown
    ⍝ 左方向键。
    ArrowLeft
    ⍝ 右方向键。
    ArrowRight
    ⍝ Escape 键。
    Escape
}

# ──────────────────────────────────────────────
# MouseButton
# ──────────────────────────────────────────────

⍝ 鼠标按键。
unite MouseButton {
    ⍝ 左键。
    Left
    ⍝ 右键。
    Right
    ⍝ 中键（滚轮按下）。
    Middle
    ⍝ 扩展键 1（侧键）。
    X1
    ⍝ 扩展键 2（侧键）。
    X2
}

# ──────────────────────────────────────────────
# KeyboardMouseState
# ──────────────────────────────────────────────

⍝ 键鼠状态快照，记录按键、鼠标按键与光标位置。
class KeyboardMouseState {
    ⍝ 光标横坐标（像素）。
    _cursor_x: f32
    ⍝ 光标纵坐标（像素）。
    _cursor_y: f32
}

imply KeyboardMouseState {
    ⍝ 构造一个空的键鼠状态，光标位于原点。
    micro new(): Self {
        return KeyboardMouseState {
            _cursor_x: 0.0,
            _cursor_y: 0.0,
        }
    }

    ⍝ 返回光标横坐标。
    micro cursor_x(self): f32 {
        return self._cursor_x
    }

    ⍝ 返回光标纵坐标。
    micro cursor_y(self): f32 {
        return self._cursor_y
    }

    ⍝ 设置光标位置。
    micro set_cursor(mut self, x: f32, y: f32): unit {
        self._cursor_x = x
        self._cursor_y = y
    }

    ⍝ 查询指定键码是否按下。
    [host_contract]
    micro key_pressed(self, key: KeyCode): bool {
        return false
    }

    ⍝ 查询指定鼠标按键是否按下。
    [host_contract]
    micro mouse_pressed(self, button: MouseButton): bool {
        return false
    }
}
