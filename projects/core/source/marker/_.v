namespace marker;

/// <summary>
///     标记一个 class 为命令行入口类，其字段为子命令组
/// </summary>
attribute commander;

/// <summary>
///     标记一个 union 为子命令集合，每个变体是一个子命令
/// </summary>
attribute commands;

/// <summary>
///     标记一个子命令变体
/// </summary>
attribute subcommand;

/// <summary>
///     标记一个命令行参数
/// </summary>
attribute argument;