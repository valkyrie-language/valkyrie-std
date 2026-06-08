namespace multi_file;

using multi_file::lib::LibType
using multi_file::lib::helper

[main]
micro multi_main() -> ExitCode {
    let t = LibType { value: 10 }
    let result = helper(t)
    print("multi-file result={result}")
    return ExitCode(0 as i32)
}