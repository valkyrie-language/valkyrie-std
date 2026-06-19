namespace simple_cli;

structure ArgumentDef {
    name: utf8,
    description: utf8,
    required: bool
}

structure CommandModel {
    name: utf8,
    description: utf8,
    arguments: [ArgumentDef]
}

structure ParsedCommand {
    command_name: utf8,
    positional: [utf8]
}

structure CommandApp {
    name: utf8,
    commands: [CommandModel]
}

micro command_app_run(app: CommandApp, args: [utf8]) -> ParsedCommand {
    if len(args) == 0 {
        return ParsedCommand {
            command_name: "",
            positional: []
        }
    }

    let first_arg: utf8 = args[0]
    let cmds: [CommandModel] = app.commands
    loop cmd in cmds {
        if cmd.name == first_arg {
            let pos: [utf8] = args
                .into_iterator()
                .skip(1)
                .collect_array()
            return ParsedCommand {
                command_name: cmd.name,
                positional: pos
            }
        }
    }
    return ParsedCommand {
        command_name: "",
        positional: []
    }
}

[main]
micro main() -> Unit {
    let app: CommandApp = CommandApp {
        name: "mycli",
        commands: [
            CommandModel {
                name: "build",
                description: "build the project",
                arguments: [
                    ArgumentDef {
                        name: "source",
                        description: "source file",
                        required: true
                    }
                ]
            }
        ]
    }
    let args: [utf8] = ["__unused__"]
    let result: ParsedCommand = command_app_run(app, args)
}
