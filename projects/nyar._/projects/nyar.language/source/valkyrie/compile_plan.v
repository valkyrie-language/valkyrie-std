namespace nyar.language.valkyrie;

using std.io;

micro dq() -> utf8 {
    return '''"'''
}

micro path_join(base: utf8, child: utf8) -> utf8 {
    let left: utf8 = base
    let right: utf8 = child
    if left.length() == 0 {
        return right
    }
    if right.length() == 0 {
        return left
    }
    if right.starts_with("/") || right.contains(":/") {
        return right
    }
    if left.ends_with("/") {
        return left + right
    }
    return left + "/" + right
}

micro trim_line(line: utf8) -> utf8 {
    return line.trim()
}

# Caller must ensure `line.starts_with(prefix)`. Returns the trimmed remainder.
# Avoid `utf8?` — CLR currently returns bare string for Some(utf8) and breaks Option_is_some.
micro take_prefix_remainder(line: utf8, prefix: utf8) -> utf8 {
    let start: i32 = prefix.length()
    let mut count: i32 = line.length() - start
    if count < 0 {
        count = 0
    }
    return line.slice(start, count).trim()
}

# Returns empty `output_dir` on failure — avoid `Option<structure>` which CLR currently
# unwraps to `object` then `ldloca`+`ldfld` (InvalidProgram).
micro parse_compile_plan_snapshot(plan_path: utf8) -> SmokeCompilePlan {
    std.io.print_line("[v1-debug] parse_compile_plan_snapshot enter, path=" + plan_path)
    if !std.io.file_exists(plan_path) {
        std.io.print_line("[v1-debug] file not exists")
        return empty_smoke_compile_plan()
    }
    std.io.print_line("[v1-debug] file exists, reading...")
    let text: utf8 = std.io.read_file_text(plan_path)
    std.io.print_line("[v1-debug] text read, length=" + format("{}", text.length()))
    if text.length() == 0 {
        return empty_smoke_compile_plan()
    }

    let mut project_name: utf8 = "main"
    let mut project_dir: utf8 = ""
    let mut output_dir: utf8 = ""
    let mut canonical_target: utf8 = "clr"
    let mut emit_msil: bool = false
    let mut files: [utf8] = []
    let mut reading_files: bool = false

    # CLR bootstrap: prefer ordinal `while` over `loop … in` so plan parsing does not
    # depend on ArrayIterator (previously fuzzy-bound to HttpClient.GetStringAsync).
    let lines: [utf8] = text.split("\n")
    let line_count: usize = lines.length()
    let mut line_idx: usize = 0
    while line_idx < line_count {
        let line: utf8 = lines⁅line_idx⁆
        line_idx = line_idx + 1
        # Indentation must be checked before trim — file entries are `  path`.
        let indented: bool = line.starts_with("  ")
        let trimmed: utf8 = trim_line(line)
        if trimmed.length() == 0 {
            continue
        }
        if trimmed.starts_with("project_dir:") {
            project_dir = take_prefix_remainder(trimmed, "project_dir:")
            reading_files = false
            continue
        }
        if trimmed.starts_with("project_name:") {
            project_name = take_prefix_remainder(trimmed, "project_name:")
            reading_files = false
            continue
        }
        if trimmed.starts_with("output_dir:") {
            output_dir = take_prefix_remainder(trimmed, "output_dir:")
            reading_files = false
            continue
        }
        if trimmed.starts_with("canonical_target:") {
            canonical_target = take_prefix_remainder(trimmed, "canonical_target:")
            reading_files = false
            continue
        }
        if trimmed.starts_with("build_options.msil:") {
            emit_msil = take_prefix_remainder(trimmed, "build_options.msil:") == "true"
            reading_files = false
            continue
        }
        if trimmed.starts_with("dependency_names:") {
            reading_files = false
            continue
        }
        if trimmed.starts_with("files:") {
            reading_files = true
            continue
        }
        if reading_files && indented {
            files = push(files, trimmed)
        }
        else {
            reading_files = false
        }
    }

    if output_dir.length() == 0 {
        return empty_smoke_compile_plan()
    }
    return SmokeCompilePlan {
        project_dir: project_dir,
        project_name: project_name,
        output_dir: output_dir,
        canonical_target: canonical_target,
        emit_msil: emit_msil,
        source_files: files,
        dependency_count: 0
    }
}

micro load_source_files(files: [utf8]) -> utf8 {
    let mut combined: utf8 = ""
    loop file_path in files {
        if !std.io.file_exists(file_path) {
            continue
        }
        let content: utf8 = std.io.read_file_text(file_path)
        combined = combined + "// file: " + file_path + "\n"
        combined = combined + content
        combined = combined + "\n"
    }
    return combined
}
