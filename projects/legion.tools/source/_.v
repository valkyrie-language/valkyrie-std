namespace legion;

[main]
async micro legion(args: Args) {
    CommandLegion::parse(args).run().await
}

[command]
class CommandLegion {
    [options]
    options: LegionOptions,
    [commands]
    commands: LegionCommands,
}

[options]
class LegionOptions {
    [option]
    verbose: bool,
    [option]
    debug: bool,
}

[commands]
unite LegionCommands {
    [command(wrapper: CommandRun)]
    run, # run { wrapper: CommandRun }
    [command(wrapper: CommandBuild)]
    build,
    [command(wrapper: CommandBenchmark, alias="bench")]
    benchmark,
}

imply CommandLegion {
    micro run(self) {

    }
}

[command]
class CommandRun {
    [options]
    target: utf8
}