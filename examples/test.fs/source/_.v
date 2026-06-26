namespace test_fs;

using std.io.{file_exists, get_current_directory, print_line, read_file_text, write_file_text};

[main]
micro main() -> ExitCode {
    let cwd: utf8 = get_current_directory()
    let smoke_path: utf8 = "test.fs.smoke.txt"
    let expected: utf8 = "fs smoke ok"

    print_line(cwd)

    if !write_file_text(smoke_path, expected) {
        print_line("write_file_text failed")
        return ExitCode(1)
    }

    if !file_exists(smoke_path) {
        print_line("file_exists failed")
        return ExitCode(2)
    }

    let actual: utf8 = read_file_text(smoke_path)
    print_line(actual)
    return ExitCode(0)
}
