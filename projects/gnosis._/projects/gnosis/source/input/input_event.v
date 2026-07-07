namespace gnosis.input;

# gnosis.input.input_event: 输入事件抽象
# 定义跨设备统一的输入事件与状态，供动作映射消费。
# 物理输入（键鼠 / 手柄）由平台采样为 InputEvent，汇聚到 InputState。

# ──────────────────────────────────────────────
# InputDevice
# ──────────────────────────────────────────────

⍝ 输入设备种类。
unite InputDevice {
    ⍝ 键盘与鼠标设备。
    KeyboardMouse
    ⍝ 手柄设备。
    Gamepad
}

# ──────────────────────────────────────────────
# InputEvent
# ──────────────────────────────────────────────

⍝ 物理输入事件，对按键 / 鼠标 / 手柄输入的统一描述。
structure InputEvent {
    ⍝ 产生该事件的设备种类。
    device: InputDevice
    ⍝ 设备内逻辑码（键码 / 鼠标键 / 手柄按钮）。
    code: u32
    ⍝ 是否处于按下状态。
    pressed: bool
    ⍝ 模拟量值（如手柄扳机 / 摇杆），无模拟量时为 0。
    value: f32
}

# ──────────────────────────────────────────────
# InputState
# ──────────────────────────────────────────────

⍝ 输入状态快照，记录当前帧各输入的瞬时状态。
class InputState {
    ⍝ 本帧采样到的事件列表。
    _events: [InputEvent]
}

imply InputState {
    ⍝ 构造一个空的输入状态。
    micro new(): Self {
        return InputState {
            _events: [],
        }
    }

    ⍝ 追加一个本帧采样到的事件。
    [host_contract]
    micro push(mut self, event: InputEvent): unit {
        return
    }

    ⍝ 返回本帧采样到的事件列表。
    [host_contract]
    micro events(self): [InputEvent] {
        return []
    }

    ⍝ 清空本帧事件，准备下一帧采样。
    [host_contract]
    micro clear(mut self): unit {
        return
    }
}
