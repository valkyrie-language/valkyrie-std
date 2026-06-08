namespace std.command;

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