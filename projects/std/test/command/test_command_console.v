namespace std.command.test;

[test]
micro `test generate usage with multiple commands`() {
    let commands: [CommandModel] = [
        CommandModel { name: "build", description: "build project", arguments: [], options: [] },
        CommandModel { name: "test", description: "run tests", arguments: [], options: [] }
    ]

    let usage: utf8 = generate_usage("legion", commands)
    if usage != "usage: legion <build|test> [args...]" {
        panic("command usage generation test failed")
    }
}

[test]
micro `test generate root help contains command descriptions`() {
    let commands: [CommandModel] = [
        CommandModel { name: "build", description: "build project", arguments: [], options: [] },
        CommandModel { name: "test", description: "run tests", arguments: [], options: [] }
    ]

    let help: utf8 = generate_root_help("legion", "workspace tool", commands)
    if !help.contains("legion - workspace tool") {
        panic("root help header test failed")
    }

    if !help.contains("  build  - build project") {
        panic("root help build line test failed")
    }

    if !help.contains("  test  - run tests") {
        panic("root help test line test failed")
    }
}

[test]
micro `test generate command help contains args and options`() {
    let command: CommandModel = CommandModel {
        name: "build",
        description: "build project",
        arguments: [
            ArgumentDef { name: "target", description: "build target", required: true }
        ],
        options: [
            OptionDef { name: "release", short_name: "r", description: "release mode", required: false, takes_value: false }
        ]
    }

    let help: utf8 = generate_command_help("legion", command)
    if !help.contains("command: legion build") {
        panic("command help header test failed")
    }

    if !help.contains("target (required)  - build target") {
        panic("command help argument line test failed")
    }

    if !help.contains("--release, -r  - release mode") {
        panic("command help option line test failed")
    }
}

[test]
micro `test console and terminal smoke`() {
    std.console.write_line("console smoke")
    std.console.error_line("console error smoke")
    std.io.print("io print smoke")
    std.io.print_line("io print line smoke")
    std.io.trace("io trace smoke")
    std.io.debug("io debug smoke")
    std.terminal.reset_color()
}
