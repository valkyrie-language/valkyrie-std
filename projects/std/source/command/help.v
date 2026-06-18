namespace std.command;

micro generate_root_help(app_name: utf8, app_description: utf8, commands: [CommandModel]) -> utf8 {
    let mut result: utf8 = app_name
    result = result + " - "
    result = result + app_description
    result = result + "\n"
    result = result + "\n"
    result = result + "commands:\n"

    let mut i: usize = 0
    while i < commands.length() {
        let cmd: CommandModel = commands[i]
        result = result + "  "
        result = result + cmd.name
        if cmd.description.length() > 0 {
            result = result + "  - "
            result = result + cmd.description
        }
        result = result + "\n"
        i = i + 1
    }

    result = result + "\n"
    result = result + "run "
    result = result + app_name
    result = result + " <command> --help' for more info.\n"

    return result
}

micro generate_command_help(app_name: utf8, cmd: CommandModel) -> utf8 {
    let mut result: utf8 = "command: "
    result = result + app_name
    result = result + " "
    result = result + cmd.name
    result = result + "\n"

    if cmd.description.length() > 0 {
        result = result + "\n"
        result = result + cmd.description
        result = result + "\n"
    }

    let cmd_args: [ArgumentDef] = cmd.arguments
    if cmd_args.length() > 0 {
        result = result + "\n"
        result = result + "arguments:\n"
        let mut i: usize = 0
        while i < cmd_args.length() {
            let arg: ArgumentDef = cmd_args[i]
            result = result + "  "
            result = result + arg.name
            if arg.required {
                result = result + " (required)"
            }
            if arg.description.length() > 0 {
                result = result + "  - "
                result = result + arg.description
            }
            result = result + "\n"
            i = i + 1
        }
    }

    let cmd_opts: [OptionDef] = cmd.options
    if cmd_opts.length() > 0 {
        result = result + "\n"
        result = result + "options:\n"
        let mut i: usize = 0
        while i < cmd_opts.length() {
            let opt: OptionDef = cmd_opts[i]
            result = result + "  --"
            result = result + opt.name
            if opt.short_name.length() > 0 {
                result = result + ", -"
                result = result + opt.short_name
            }
            if opt.description.length() > 0 {
                result = result + "  - "
                result = result + opt.description
            }
            result = result + "\n"
            i = i + 1
        }
    }

    return result
}

micro generate_usage(app_name: utf8, commands: [CommandModel]) -> utf8 {
    let mut result: utf8 = "usage: "
    result = result + app_name

    if commands.length() == 0 {
        return result
    }

    result = result + " <"
    let mut i: usize = 0
    while i < commands.length() {
        if i > 0 {
            result = result + "|"
        }
        let cmd: CommandModel = commands[i]
        result = result + cmd.name
        i = i + 1
    }
    result = result + "> [args...]"

    return result
}
