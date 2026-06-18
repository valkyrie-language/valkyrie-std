namespace cli_std;

structure ArgumentDef {
    name: utf8,
    description: utf8,
    required: bool
}

structure OptionDef {
    name: utf8,
    short_name: utf8,
    description: utf8,
    required: bool,
    takes_value: bool
}

structure CommandModel {
    name: utf8,
    description: utf8,
    arguments: [ArgumentDef],
    options: [OptionDef]
}

structure ParsedCommand {
    command_name: utf8,
    positional: [utf8],
    remaining: [utf8]
}

structure CommandApp {
    name: utf8,
    description: utf8,
    commands: [CommandModel]
}

micro command_app_new(name: utf8, description: utf8) -> CommandApp {
    return CommandApp {
        name: name,
        description: description,
        commands: []
    }
}

micro command_app_register(mut app: CommandApp, cmd: CommandModel) -> Unit {
    push(app.commands, cmd)
}

micro command_app_run(app: CommandApp, args: [utf8]) -> ParsedCommand {
    if len(args) == 0 {
        return ParsedCommand {
            command_name: "",
            positional: [],
            remaining: []
        }
    }

    let first_arg: utf8 = args[0]

    if first_arg == "--help" || first_arg == "-h" {
        return ParsedCommand {
            command_name: "__help__",
            positional: [],
            remaining: args
        }
    }

    if first_arg == "--version" || first_arg == "-V" {
        return ParsedCommand {
            command_name: "__version__",
            positional: [],
            remaining: args
        }
    }

    let cmds: [CommandModel] = app.commands
    loop cmd in cmds {
        if cmd.name == first_arg {
            let mut pos: [utf8] = []
            let mut j: usize = 1
            while j < len(args) {
                push(pos, args[j])
                j = j + 1
            }
            return ParsedCommand {
                command_name: cmd.name,
                positional: pos,
                remaining: []
            }
        }
    }

    return ParsedCommand {
        command_name: "",
        positional: [],
        remaining: args
    }
}

micro parse_bool(s: utf8) -> bool {
    if s == "true" || s == "1" || s == "yes" {
        return true
    }
    return false
}

micro parse_i32(s: utf8) -> i32 {
    if s == "0" { return 0 }
    if s == "1" { return 1 }
    if s == "2" { return 2 }
    if s == "3" { return 3 }
    if s == "42" { return 42 }
    if s == "-1" { return -1 }
    return 0
}

micro generate_help(app: CommandApp) -> utf8 {
    let mut result: utf8 = app.name
    result = result + " - "
    result = result + app.description
    result = result + "\n\ncommands:\n"

    loop cmd in app.commands {
        result = result + "  "
        result = result + cmd.name
        if len(cmd.description) > 0 {
            result = result + "  - "
            result = result + cmd.description
        }
        result = result + "\n"
    }

    return result
}

micro generate_command_help(app: CommandApp, cmd_name: utf8) -> utf8 {
    let mut result: utf8 = "command: "
    result = result + app.name
    result = result + " "
    result = result + cmd_name
    result = result + "\n"

    let cmds: [CommandModel] = app.commands
    loop cmd in cmds {
        if cmd.name == cmd_name {
            if len(cmd.description) > 0 {
                result = result + "\n"
                result = result + cmd.description
                result = result + "\n"
            }
        }
    }

    return result
}

[commander]
struct AppCli {
    build: BuildCli
}

[commands]
union SubCmds {
    Build,
    Test,
    Run
}

structure BuildCli {
    source: utf8,
    output: utf8
}

structure TestCli {
    filter: utf8
}

structure RunCli {
    entry: utf8
}

micro build_command_model() -> CommandModel {
    return CommandModel {
        name: "build",
        description: "build the project",
        arguments: [
            ArgumentDef {
                name: "source",
                description: "source file path",
                required: true
            },
            ArgumentDef {
                name: "output",
                description: "output directory",
                required: false
            }
        ],
        options: [
            OptionDef {
                name: "release",
                short_name: "r",
                description: "build in release mode",
                required: false,
                takes_value: false
            }
        ]
    }
}

micro test_command_model() -> CommandModel {
    return CommandModel {
        name: "test",
        description: "run tests",
        arguments: [
            ArgumentDef {
                name: "filter",
                description: "test filter pattern",
                required: false
            }
        ],
        options: []
    }
}

micro run_command_model() -> CommandModel {
    return CommandModel {
        name: "run",
        description: "run the application",
        arguments: [
            ArgumentDef {
                name: "entry",
                description: "entry point name",
                required: true
            }
        ],
        options: [
            OptionDef {
                name: "debug",
                short_name: "d",
                description: "enable debug mode",
                required: false,
                takes_value: false
            }
        ]
    }
}

[main]
micro main() -> Unit {
    let mut app: CommandApp = command_app_new("myapp", "a demo CLI application")

    let build_cmd: CommandModel = build_command_model()
    command_app_register(app, build_cmd)

    let test_cmd: CommandModel = test_command_model()
    command_app_register(app, test_cmd)

    let run_cmd: CommandModel = run_command_model()
    command_app_register(app, run_cmd)

    let help_text: utf8 = generate_help(app)

    let args: [utf8] = ["build", "source.v", "--release"]
    let parsed: ParsedCommand = command_app_run(app, args)

    let build_help: utf8 = generate_command_help(app, "build")
}
