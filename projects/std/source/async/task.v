namespace std.async;

# std.async: 异步任务最小面
# 提供 Future / Promise / CancellationToken / CancellationSource / spawn / delay / sleep / yield 的最小定义，
# 作为语言级异步并发语义的真实承载体。

⍝ 异步结果的抽象协议。
⍝ 定义异步值的最小接口：通过 `poll` 查询就绪状态，通过 `output` 显式取出结果值。
⍝ 该协议取代了旧的“布尔 poll + 编译器脑补输出值”隐式约定，使结果恢复显式且可验证。
trait Future {
    ⍝ Future 完成后产出的结果类型。
    type Output

    ⍝ 查询当前 Future 是否已进入终态（就绪）。
    ⍝ 返回 true 表示可调用 `output` 取出结果；返回 false 表示尚未完成。
    micro poll(mut self): bool

    ⍝ 取出已完成的结果值。
    ⍝ 调用前应确保 `poll` 已返回 true；对未完成或已取消的 Future 调用行为未定义。
    micro output(self): Output
}

⍝ 单赋值的可完成异步值，是 `Future` 的具体拥有型实现。
⍝ 持有值槽、完成标志与取消标志，支持通过 `resolve` 写入结果或通过 `cancel` 取消。
class Promise<T> {
    ⍝ 已写入的结果值，完成前为 `None`。
    _value: Option<T>

    ⍝ 是否已进入终态（已写入结果或已取消）。
    _done: bool

    ⍝ 是否已被取消。
    _cancelled: bool
}

imply Promise<T>: Future {
    ⍝ Promise 的结果类型即为所持有的值类型 T。
    type Output = T

    ⍝ 构造一个未完成、未取消的空 Promise。
    micro new(): Self {
        return Promise {
            _value: None,
            _done: false,
            _cancelled: false,
        }
    }

    ⍝ 写入结果值并标记完成，使 Promise 进入终态。
    ⍝ 若 Promise 已进入终态则忽略后续写入，保证单赋值语义。
    micro resolve(mut self, value: T): unit {
        if self._done {
            return
        }
        self._value = Some::<T>(value)
        self._done = true
    }

    ⍝ 查询是否已进入终态（已写入结果或已取消）。
    micro poll(mut self): bool {
        return self._done
    }

    ⍝ 取出已写入的结果值。
    ⍝ 调用前应确保 `poll` 已返回 true；对已取消但未写入值的 Promise 调用会触发 panic。
    micro output(self): T {
        let value: Option<T> = self._value
        return value.unwrap()
    }

    ⍝ 请求取消该 Promise，将其标记为已取消并进入终态。
    ⍝ 若 Promise 已进入终态则忽略取消请求。
    micro cancel(mut self): unit {
        if self._done {
            return
        }
        self._cancelled = true
        self._done = true
    }

    ⍝ 查询该 Promise 是否已被取消。
    ⍝ 取消感知的 await/block 在 `poll` 返回 true 后调用本方法，
    ⍝ 若返回 true 则跳过会触发 panic 的 `output`，直接以 null/unit 完成恢复。
    micro is_cancelled(self): bool {
        return self._cancelled
    }
}

⍝ 取消信号的载体，记录是否已收到取消请求。
⍝ 通常由 `CancellationSource` 创建并对外暴露，供异步任务观察取消状态。
class CancellationToken {
    ⍝ 是否已收到取消请求。
    _cancelled: bool
}

imply CancellationToken {
    ⍝ 构造一个未取消的 token。
    micro new(): Self {
        return CancellationToken {
            _cancelled: false,
        }
    }

    ⍝ 标记该 token 为已取消。
    micro cancel(mut self): unit {
        self._cancelled = true
    }

    ⍝ 查询是否已被取消。
    micro is_cancelled(self): bool {
        return self._cancelled
    }
}

⍝ 取消源，拥有一个 `CancellationToken` 并提供触发取消与暴露 token 的能力。
class CancellationSource {
    ⍝ 内部持有的取消 token。
    _token: CancellationToken
}

imply CancellationSource {
    ⍝ 构造一个尚未触发取消的取消源。
    micro new(): Self {
        return CancellationSource {
            _token: CancellationToken::new(),
        }
    }

    ⍝ 返回所持有的取消 token，供异步任务观察取消状态。
    micro token(self): CancellationToken {
        return self._token
    }

    ⍝ 触发取消，将内部 token 标记为已取消。
    micro cancel(mut self): unit {
        self._token.cancel()
    }
}

⍝ 在异步运行时上调度执行一个任务。
⍝ 该函数为 host contract：具体调度行为由宿主运行时提供。
[host_contract]
micro spawn(task: micro() -> unit): unit {
    task()
}

⍝ 让当前任务延迟指定毫秒后再恢复，交出控制权。
⍝ 该函数为 host contract：具体的计时与调度由宿主运行时提供。
[host_contract]
micro delay(ms: i32): unit {
    return
}

⍝ 让当前任务休眠指定毫秒后再恢复，语义与 `delay` 一致。
⍝ 该函数为 host contract：保留独立命名以对齐 spec 的 sleep 语义。
[host_contract]
micro sleep(ms: i32): unit {
    return
}

⍝ 让出当前任务的执行控制权，允许运行时调度其他任务。
micro yield(): unit {
    delay(0)
}
