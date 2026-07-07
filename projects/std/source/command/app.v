namespace std.command;

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

micro command_app_register(app: CommandApp, cmd: CommandModel) -> CommandApp {
    let mut result: CommandApp = app
    push(result.commands, cmd)
    return result
}

micro command_app_run(app: CommandApp, args: [utf8]) -> ParsedCommand {
    if args.length() == 0 {
        return ParsedCommand {
            command_name: "",
            positional: [],
            remaining: []
        }
    }

    let first_arg: utf8 = args⁅0⁆

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
    let mut i: usize = 0
    while i < cmds.length() {
        let cmd: CommandModel = cmds⁅i⁆
        if cmd.name == first_arg {
            let pos: [utf8] = args
                .into_iterator()
                .skip(1)
                .collect_array()
            return ParsedCommand {
                command_name: cmd.name,
                positional: pos,
                remaining: []
            }
        }
        i = i + 1
    }

    return ParsedCommand {
        command_name: "",
        positional: [],
        remaining: args
    }
}
