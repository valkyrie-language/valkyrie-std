namespace feature_matrix::test;

trait Future {
    type Output

    micro poll(mut self) -> bool

    micro output(self) -> Output
}

class ReadyFuture {
    done: bool
    value: i32
}

imply ReadyFuture: Future {
    type Output = i32

    micro poll(mut self) -> bool {
        if !self.done {
            self.value = 42
            self.done = true
            return false
        }
        return true
    }

    micro output(self) -> i32 {
        return self.value
    }
}

[test]
micro async_await_surface() -> unit {
    let future: Future<i32> = ReadyFuture { done: false, value: 0 }
    if future.poll() {
        panic("ready future should poll once")
    }
    if !future.poll() {
        panic("ready future should be done on second poll")
    }
    let v: i32 = future.output()
    if v != 42 {
        panic("future output should be 42")
    }
}
