namespace async_await::test;

class UserService {
    rpc get_user(id: i32) -> future<User>
}
class User { id: i32; name: utf8 }

[test]
micro simple_await() -> unit {
    let user = UserService.get_user(1).await
    print("user={user.name}")
}

[test]
micro chain_await() -> unit {
    let a = UserService.get_user(1).await
    let b = UserService.get_user(a.id + 1).await
    print("chain={b.name}")
}

[test]
micro awake_fire_forget() -> unit {
    UserService.get_user(99).awake
    print("awake ok")
}

[test]
micro block_sync() -> unit {
    let user = UserService.get_user(7).block
    print("blocked={user.name}")
}

[test]
micro future_ready() -> unit {
    let f = future.ready("immediate")
    let v = f.await
    print("ready={v}")
}

[benchmark]
micro await_benchmark() -> unit {
    let user = UserService.get_user(1).await
    print("bench done: {user.name}")
}
