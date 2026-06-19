namespace std.adaptor.clr.console;

# std.adaptor.clr.console: CLR 控制台 API 绑定
# 通过 [clr] 属性映射到 System.Console 静态方法

#region 输出

/// <summary>
/// 向标准输出流写入文本并换行（映射到 System.Console.WriteLine）
/// </summary>
[clr("System.Runtime", "System.Console", "WriteLine")]
micro console_write_line(value: utf8): unit

/// <summary>
/// 向标准输出流写入文本（映射到 System.Console.Write）
/// </summary>
[clr("System.Runtime", "System.Console", "Write")]
micro console_write(value: utf8): unit

#endregion
