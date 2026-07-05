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

micro parse_prefixed_line(line: utf8, prefix: utf8) -> Option<utf8> {
    if line.starts_with(prefix) {
        return Some(line.slice(prefix.length(), line.length()).trim())
    }
    return None
}

micro parse_compile_plan_snapshot(plan_path: utf8) -> Option<SmokeCompilePlan> {
    if !std.io.file_exists(plan_path) {
        return None
    }
    let text: utf8 = std.io.read_file_text(plan_path)
    if text.length() == 0 {
        return None
    }

    let mut project_name: utf8 = "main"
    let mut project_dir: utf8 = ""
    let mut output_dir: utf8 = ""
    let mut canonical_target: utf8 = "clr"
    let mut emit_msil: bool = false
    let mut files: [utf8] = []
    let mut reading_files: bool = false

    let lines: [utf8] = text.split("\n")
    loop line in lines {
        let trimmed: utf8 = trim_line(line)
        if trimmed.length() == 0 {
            continue
        }
        let prefixed: Option<utf8> = parse_prefixed_line(trimmed, "project_dir:")
        if prefixed.is_some() {
            project_dir = prefixed.unwrap()
            reading_files = false
            continue
        }
        prefixed = parse_prefixed_line(trimmed, "project_name:")
        if prefixed.is_some() {
            project_name = prefixed.unwrap()
            reading_files = false
            continue
        }
        prefixed = parse_prefixed_line(trimmed, "output_dir:")
        if prefixed.is_some() {
            output_dir = prefixed.unwrap()
            reading_files = false
            continue
        }
        prefixed = parse_prefixed_line(trimmed, "canonical_target:")
        if prefixed.is_some() {
            canonical_target = prefixed.unwrap()
            reading_files = false
            continue
        }
        prefixed = parse_prefixed_line(trimmed, "build_options.msil:")
        if prefixed.is_some() {
            emit_msil = prefixed.unwrap() == "true"
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
        if reading_files && trimmed.starts_with("  ") {
            push(files, trimmed.trim())
        }
        else {
            reading_files = false
        }
    }

    if output_dir.length() == 0 {
        return None
    }
    return Some(SmokeCompilePlan {
        project_dir: project_dir,
        project_name: project_name,
        output_dir: output_dir,
        canonical_target: canonical_target,
        emit_msil: emit_msil,
        source_files: files,
        dependency_count: 0
    })
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
