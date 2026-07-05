namespace feature_matrix::test;

trait Future {
    type Output

    micro poll(mut self) -> bool
}

class ReadyFuture {
    done: bool
}

imply ReadyFuture: Future {
    type Output = i32

    micro poll(mut self) -> bool {
        if !self.done {
            self.done = true
            return false
        }
        return true
    }
}

[test]
micro async_await_surface() -> unit {
    let future: Future<i32> = ReadyFuture { done: false }
    if future.poll() {
        panic("ready future should poll once")
    }
}
