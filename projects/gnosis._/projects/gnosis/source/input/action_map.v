namespace gnosis.input;

# gnosis.input.action_map: 输入动作映射
# 将物理输入事件映射为逻辑动作，提供按下 / 刚按下 / 刚释放的查询。
# ActionMap 在帧末基于 InputState 刷新动作状态，供玩法系统查询。

# ──────────────────────────────────────────────
# ActionId 与 Binding
# ──────────────────────────────────────────────

⍝ 逻辑动作标识。
structure ActionId {
    ⍝ 动作的不透明索引。
    id: u32
}

⍝ 物理输入到逻辑动作的绑定条目。
structure Binding {
    ⍝ 绑定的逻辑动作。
    action: ActionId
    ⍝ 产生该绑定的设备种类。
    device: InputDevice
    ⍝ 触发该动作的设备逻辑码。
    code: u32
}

# ──────────────────────────────────────────────
# ActionState
# ──────────────────────────────────────────────

⍝ 动作状态枚举。
unite ActionState {
    ⍝ 当前帧处于按下状态。
    Pressed
    ⍝ 当前帧刚按下（上一帧未按下，本帧按下）。
    JustPressed
    ⍝ 当前帧刚释放（上一帧按下，本帧未按下）。
    JustReleased
    ⍝ 当前帧处于释放状态。
    Released
}

# ──────────────────────────────────────────────
# ActionMap
# ──────────────────────────────────────────────

⍝ 动作映射表，维护绑定关系并基于输入状态查询动作状态。
class ActionMap {
    ⍝ 已注册的绑定条目列表。
    _bindings: [Binding]
}

imply ActionMap {
    ⍝ 构造一个空的动作映射表。
    micro new(): Self {
        return ActionMap {
            _bindings: [],
        }
    }

    ⍝ 注册一条物理输入到逻辑动作的绑定。
    [host_contract]
    micro bind(mut self, binding: Binding): unit {
        return
    }

    ⍝ 查询指定动作是否处于按下状态。
    [host_contract]
    micro is_pressed(self, action: ActionId): bool {
        return false
    }

    ⍝ 查询指定动作是否在本帧刚按下。
    [host_contract]
    micro just_pressed(self, action: ActionId): bool {
        return false
    }

    ⍝ 查询指定动作是否在本帧刚释放。
    [host_contract]
    micro just_released(self, action: ActionId): bool {
        return false
    }

    ⍝ 基于本帧输入状态刷新动作状态，在帧末调用。
    [host_contract]
    micro update(mut self, state: InputState): unit {
        return
    }
}
