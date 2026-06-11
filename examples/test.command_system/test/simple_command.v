namespace command_system::test;

using std.command;

[test]
micro parse_build_command() -> unit {
    let mut app: CommandApp = command_app_new("testcli", "test cli")

    let build_cmd: CommandModel = CommandModel {
        name: "build",
        description: "build the project",
        arguments: [
            ArgumentDef { name: "source", description: "source file path", required: true }
        ],
        options: []
    }
    app = command_app_register(app, build_cmd)

    let args: [utf8] = ["build", "main.gg"]
    let result: ParsedCommand = command_app_run(app, args)

    assert(result.command_name == "build")
    assert(len(result.positional) == 1)
    assert(result.positional[0] == "main.gg")
}

[test]
micro parse_no_args_shows_help() -> unit {
    let mut app: CommandApp = command_app_new("testcli", "test cli")

    let build_cmd: CommandModel = CommandModel {
        name: "build",
        description: "build",
        arguments: [],
        options: []
    }
    app = command_app_register(app, build_cmd)

    let args: [utf8] = []
    let result: ParsedCommand = command_app_run(app, args)

    assert(result.command_name == "")
    assert(len(result.positional) == 0)
}

[test]
micro parse_unknown_command() -> unit {
    let mut app: CommandApp = command_app_new("testcli", "test cli")

    let build_cmd: CommandModel = CommandModel {
        name: "build",
        description: "build",
        arguments: [],
        options: []
    }
    app = command_app_register(app, build_cmd)

    let args: [utf8] = ["unknown_cmd"]
    let result: ParsedCommand = command_app_run(app, args)

    assert(result.command_name == "")
}

[test]
micro type_converter_parse_i32() -> unit {
    let result: Option<i32> = parse_i32("42")
    assert(result.is_some())
    assert(result.unwrap() == 42)
}

[test]
micro type_converter_parse_i32_negative() -> unit {
    let result: Option<i32> = parse_i32("-17")
    assert(result.is_some())
    assert(result.unwrap() == -17)
}

[test]
micro type_converter_parse_i32_invalid() -> unit {
    let result: Option<i32> = parse_i32("abc")
    assert(result.is_none())
}

[test]
micro type_converter_parse_bool_true() -> unit {
    let result: Option<bool> = parse_bool("true")
    assert(result.is_some())
    assert(result.unwrap() == true)
}

[test]
micro type_converter_parse_bool_one() -> unit {
    let result: Option<bool> = parse_bool("1")
    assert(result.is_some())
    assert(result.unwrap() == true)
}

[test]
micro type_converter_parse_bool_false() -> unit {
    let result: Option<bool> = parse_bool("false")
    assert(result.is_some())
    assert(result.unwrap() == false)
}