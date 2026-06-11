namespace command_system;

using std.command;
using std.io;

[main]
micro main(args: [utf8]) -> unit {
    let mut app: CommandApp = command_app_new("mycli", "a demo cli tool")

    let build_cmd: CommandModel = CommandModel {
        name: "build",
        description: "build the project",
        arguments: [
            ArgumentDef { name: "source", description: "source file path", required: true }
        ],
        options: [
            OptionDef {
                name: "output",
                short_name: "o",
                description: "output directory",
                required: false,
                takes_value: true
            }
        ]
    }
    app = command_app_register(app, build_cmd)

    let test_cmd: CommandModel = CommandModel {
        name: "test",
        description: "run tests",
        arguments: [
            ArgumentDef { name: "filter", description: "test filter", required: false }
        ],
        options: []
    }
    app = command_app_register(app, test_cmd)

    let result: ParsedCommand = command_app_run(app, args)
    let cmd_name: utf8 = result.command_name

    if cmd_name == "__help__" || len(cmd_name) == 0 {
        let help_text: utf8 = generate_root_help(app.name, app.description, app.commands)
        print_line(help_text)
        return
    }

    if cmd_name == "build" {
        print_line("running build command")
        let pos: [utf8] = result.positional
        if len(pos) > 0 {
            let source: utf8 = pos[0]
            print_line("source: " + source)
        }
        return
    }

    if cmd_name == "test" {
        print_line("running test command")
        return
    }

    let help_text: utf8 = generate_root_help(app.name, app.description, app.commands)
    print_line("unknown command: " + cmd_name)
    print_line(help_text)
}