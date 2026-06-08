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
    let mut i: usize = 0
    while i < len(cmds) {
        let cmd: CommandModel = cmds[i]
        if cmd.name == first_arg {
            let mut pos: [utf8] = []
            let mut j: usize = 1
            while j < len(args) {
                push(pos, args[j])
                j = j + 1
            }
            return ParsedCommand {
                command_name: cmd.name,
                positional: pos
            }
        }
        i = i + 1
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