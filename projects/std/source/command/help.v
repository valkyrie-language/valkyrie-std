namespace std.command;

micro render_command_summary_line(cmd: CommandModel) -> utf8 {
    let mut line: utf8 = "  "
    line = line + cmd.name
    if cmd.description.length() > 0 {
        line = line + "  - "
        line = line + cmd.description
    }
    line = line + "\n"
    return line
}

micro render_argument_help_line(arg: ArgumentDef) -> utf8 {
    let mut line: utf8 = "  "
    line = line + arg.name
    if arg.required {
        line = line + " (required)"
    }
    if arg.description.length() > 0 {
        line = line + "  - "
        line = line + arg.description
    }
    line = line + "\n"
    return line
}

micro render_option_help_line(opt: OptionDef) -> utf8 {
    let mut line: utf8 = "  --"
    line = line + opt.name
    if opt.short_name.length() > 0 {
        line = line + ", -"
        line = line + opt.short_name
    }
    if opt.description.length() > 0 {
        line = line + "  - "
        line = line + opt.description
    }
    line = line + "\n"
    return line
}

micro generate_root_help(app_name: utf8, app_description: utf8, commands: [CommandModel]) -> utf8 {
    let mut result: utf8 = app_name
    result = result + " - "
    result = result + app_description
    result = result + "\n"
    result = result + "\n"
    result = result + "commands:\n"
    result = result + commands
        .into_iterator()
        .map(micro(cmd: CommandModel) -> utf8 {
            return render_command_summary_line(cmd)
        })
        .reduce("", micro(acc: utf8, line: utf8) -> utf8 {
            return acc + line
        })

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
        result = result + cmd_args
            .into_iterator()
            .map(micro(arg: ArgumentDef) -> utf8 {
                return render_argument_help_line(arg)
            })
            .reduce("", micro(acc: utf8, line: utf8) -> utf8 {
                return acc + line
            })
    }

    let cmd_opts: [OptionDef] = cmd.options
    if cmd_opts.length() > 0 {
        result = result + "\n"
        result = result + "options:\n"
        result = result + cmd_opts
            .into_iterator()
            .map(micro(opt: OptionDef) -> utf8 {
                return render_option_help_line(opt)
            })
            .reduce("", micro(acc: utf8, line: utf8) -> utf8 {
                return acc + line
            })
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
    result = result + commands
        .into_iterator()
        .map(micro(cmd: CommandModel) -> utf8 {
            return cmd.name
        })
        .reduce("", micro(acc: utf8, name: utf8) -> utf8 {
            if acc.length() == 0 {
                return name
            }

            return acc + "|" + name
        })
    result = result + "> [args...]"

    return result
}
