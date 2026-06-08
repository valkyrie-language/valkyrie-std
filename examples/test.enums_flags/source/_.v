namespace enums_flags;

enums Status { Active = 0, Inactive = 1, Pending = 2 }

flags Permission { Read = 1, Write = 2, Execute = 4 }

[main]
micro enums_flags_main() -> ExitCode {
    let s = Status::Active
    let p = Permission::Read | Permission::Write
    print("enums and flags ok")
    return ExitCode(0 as i32)
}