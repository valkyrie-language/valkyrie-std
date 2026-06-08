namespace nullable_type;

class Box { value: i32 }

[main]
micro nullable_main() -> ExitCode {
    let x: i32? = 42
    let y: i32? = null
    print("nullable ok")
    return ExitCode(0 as i32)
}