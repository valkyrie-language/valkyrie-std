namespace async_await;

class UserService {
    rpc get_user(id: i32) -> future<User>
}
class User { id: i32; name: utf8 }

class ProfileService {
    rpc get_profile(id: i32) -> future<Profile>
}
class Profile { user_id: i32; bio: utf8 }

[main]
micro async_await_main() -> ExitCode {
    let user = UserService.get_user(42).await
    let profile = ProfileService.get_profile(user.id).await
    print("user={user.name}, bio={profile.bio}")

    UserService.get_user(100).awake

    let result = UserService.get_user(7).block
    print("blocked={result.name}")

    return ExitCode(0 as i32)
}
