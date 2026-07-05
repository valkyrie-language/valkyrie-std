namespace nyar.package_registry;

using std.io;
using std.data.text.von;

# 注册表包元数据
structure Package {
    name: utf8
    version: utf8
    description: utf8
    homepage: utf8
    author: utf8
    license: utf8
    dist_path: utf8
    integrity: utf8
}

# 发布选项
structure PublishOptions {
    package_name: utf8
    version: utf8
    description: utf8
    package_path: utf8
    registry_name: utf8
    auth_token: utf8
    tag: utf8
    access: utf8
    bump: utf8
    dry_run: bool
    skip_git_check: bool
    create_git_tag: bool
}

# 发布结果
structure PublishResult {
    success: bool
    package_name: utf8
    version: utf8
    message: utf8
    published_url: utf8
    dry_run: bool
    size: usize
    file_count: usize
    sha256: utf8
}

# 令牌验证结果
structure TokenVerifyResult {
    valid: bool
    username: utf8
    error_message: utf8
}

# 注册表句柄：kind = npm | local | mock
structure Registry {
    name: utf8
    endpoint: utf8
    kind: utf8
    root: utf8
}

[tag(RegistryResultKind)]
unite RegistryResult<T> {
    Fine(T)
    Fail(utf8)
}

structure RegistryPackageAttempt {
    ok: bool
    package: Package
    error: utf8
}

micro registry_package_attempt_ok(package: Package) -> RegistryPackageAttempt {
    return RegistryPackageAttempt {
        ok: true,
        package: package,
        error: ""
    }
}

micro registry_package_attempt_fail(error: utf8) -> RegistryPackageAttempt {
    return RegistryPackageAttempt {
        ok: false,
        package: empty_package(),
        error: error
    }
}

micro empty_package() -> Package {
    return Package {
        name: "",
        version: "",
        description: "",
        homepage: "",
        author: "",
        license: "",
        dist_path: "",
        integrity: ""
    }
}

micro empty_publish_options() -> PublishOptions {
    return PublishOptions {
        package_name: "",
        version: "",
        description: "",
        package_path: "",
        registry_name: "npm",
        auth_token: "",
        tag: "latest",
        access: "public",
        bump: "",
        dry_run: false,
        skip_git_check: false,
        create_git_tag: true
    }
}

micro token_success(username: utf8) -> TokenVerifyResult {
    return TokenVerifyResult {
        valid: true,
        username: username,
        error_message: ""
    }
}

micro token_failure(message: utf8) -> TokenVerifyResult {
    return TokenVerifyResult {
        valid: false,
        username: "",
        error_message: message
    }
}

micro normalize_endpoint(endpoint: utf8) -> utf8 {
    let mut value: utf8 = endpoint.trim()
    while value.ends_with("/") {
        value = value.slice(0, value.length() - 1)
    }
    return value
}

micro path_join(base: utf8, child: utf8) -> utf8 {
    let sep: utf8 = "\u{5c}"
    let left: utf8 = base.replace(sep, "/")
    let right: utf8 = child.replace(sep, "/")
    if left.length() == 0 {
        return right
    }
    if right.length() == 0 {
        return left
    }
    if left.ends_with("/") {
        return left + right
    }
    return left + "/" + right
}

micro path_file_name(path: utf8) -> utf8 {
    let normalized: utf8 = path.replace("\u{5c}", "/")
    let mut best: utf8 = normalized
    let mut i: usize = 0
    while i < normalized.length() {
        let head: utf8 = normalized.slice(i, normalized.length())
        if head.starts_with("/") {
            best = head.slice(1, head.length())
        }
        i = i + 1
    }
    return best
}

micro path_parent(path: utf8) -> utf8 {
    let normalized: utf8 = path.replace("\u{5c}", "/")
    let name: utf8 = path_file_name(normalized)
    if name.length() == 0 || name.length() >= normalized.length() {
        return ""
    }
    return normalized.slice(0, normalized.length() - name.length() - 1)
}

micro package_store_path(registry: Registry, package_name: utf8, version: utf8) -> utf8 {
    return path_join(path_join(path_join(registry.root, package_name), version), "package")
}

micro package_meta_path(registry: Registry, package_name: utf8, version: utf8) -> utf8 {
    return path_join(path_join(path_join(registry.root, package_name), version), "meta.von")
}

micro write_package_meta(path: utf8, package: Package) -> bool {
    let q: utf8 = "\u{22}"
    let content: utf8 = "{\n    name: " + q + package.name
        + q + ",\n    version: " + q + package.version
        + q + ",\n    description: " + q + package.description
        + q + ",\n    homepage: " + q + package.homepage
        + q + ",\n    author: " + q + package.author
        + q + ",\n    license: " + q + package.license
        + q + ",\n    dist_path: " + q + package.dist_path
        + q + ",\n    integrity: " + q + package.integrity
        + q + ",\n}\n"
    return std.io.write_file_text(path, content)
}

micro read_package_meta(path: utf8) -> Package {
    if !std.io.file_exists(path) {
        return empty_package()
    }
    let source: utf8 = std.io.read_file_text(path)
    let parsed: VonParseResult<VonValue> = parse_von(source)
    let failure: VonDiagnostic? = von_parse_take_fail(parsed)
    if failure.is_some() {
        let unused: utf8 = failure.unwrap().message
        return empty_package()
    }
    let document: VonValue = von_parse_take_fine(parsed).unwrap()
    return Package {
        name: von_as_text(von_find_field(document, "name")),
        version: von_as_text(von_find_field(document, "version")),
        description: von_as_text(von_find_field(document, "description")),
        homepage: von_as_text(von_find_field(document, "homepage")),
        author: von_as_text(von_find_field(document, "author")),
        license: von_as_text(von_find_field(document, "license")),
        dist_path: von_as_text(von_find_field(document, "dist_path")),
        integrity: von_as_text(von_find_field(document, "integrity"))
    }
}

micro new_local_registry(name: utf8, root: utf8) -> Registry {
    std.io.create_directory(root)
    return Registry {
        name: name,
        endpoint: "file://" + root,
        kind: "local",
        root: root
    }
}

micro new_mock_registry(name: utf8, root: utf8) -> Registry {
    std.io.create_directory(root)
    return Registry {
        name: name,
        endpoint: "mock://" + root,
        kind: "mock",
        root: root
    }
}

micro new_npm_registry(endpoint: utf8, cache_root: utf8) -> Registry {
    std.io.create_directory(cache_root)
    return Registry {
        name: "npm",
        endpoint: normalize_endpoint(endpoint),
        kind: "npm",
        root: cache_root
    }
}

micro default_npm_registry(cache_root: utf8) -> Registry {
    return new_npm_registry("https://registry.npmjs.org", cache_root)
}

micro registry_list_versions(registry: Registry, package_name: utf8) -> [utf8] {
    let package_root: utf8 = path_join(registry.root, package_name)
    if !std.io.directory_exists(package_root) {
        return []
    }
    let entries: [utf8] = std.io.get_files(package_root, "*", false)
    let mut versions: [utf8] = []
    let mut i: usize = 0
    while i < entries.length() {
        let version: utf8 = path_file_name(entries[i])
        if version.length() > 0 && std.io.file_exists(package_meta_path(registry, package_name, version)) {
            push(versions, version)
        }
        i = i + 1
    }
    return versions
}

micro registry_get_package_attempt(registry: Registry, package_name: utf8, version: utf8) -> RegistryPackageAttempt {
    let mut resolved: utf8 = version
    if version == "latest" {
        let versions: [utf8] = registry_list_versions(registry, package_name)
        if versions.length() == 0 {
            return registry_package_attempt_fail("package not found: " + package_name)
        }
        resolved = versions[versions.length() - 1]
    }
    let meta_path: utf8 = package_meta_path(registry, package_name, resolved)
    if !std.io.file_exists(meta_path) {
        return registry_package_attempt_fail("package not found: " + package_name + "@" + resolved)
    }
    let package: Package = read_package_meta(meta_path)
    if package.name.length() == 0 {
        return registry_package_attempt_fail("invalid package metadata: " + package_name)
    }
    return registry_package_attempt_ok(package)
}

micro registry_get_package(registry: Registry, package_name: utf8, version: utf8) -> RegistryResult<Package> {
    let attempt: RegistryPackageAttempt = registry_get_package_attempt(registry, package_name, version)
    if attempt.ok {
        return Fine(attempt.package)
    }
    return Fail(attempt.error)
}

micro registry_search(registry: Registry, query: utf8) -> [Package] {
    let roots: [utf8] = std.io.get_files(registry.root, "*", false)
    let mut packages: [Package] = []
    let mut i: usize = 0
    while i < roots.length() {
        let name: utf8 = path_file_name(roots[i])
        if name.contains(query) {
            let attempt: RegistryPackageAttempt = registry_get_package_attempt(registry, name, "latest")
            if attempt.ok {
                push(packages, attempt.package)
            }
        }
        i = i + 1
    }
    return packages
}

micro copy_directory_files(source_directory: utf8, target_directory: utf8) -> usize {
    std.io.create_directory(target_directory)
    if !std.io.directory_exists(source_directory) {
        return 0
    }
    let files: [utf8] = std.io.get_files(source_directory, "*", true)
    let mut count: usize = 0
    let mut i: usize = 0
    while i < files.length() {
        let file: utf8 = files[i]
        let content: utf8 = std.io.read_file_text(file)
        let source_prefix: utf8 = source_directory.replace("\u{5c}", "/")
        let normalized: utf8 = file.replace("\u{5c}", "/")
        let mut relative: utf8 = normalized
        if normalized.starts_with(source_prefix) {
            relative = normalized.slice(source_prefix.length(), normalized.length())
            if relative.starts_with("/") {
                relative = relative.slice(1, relative.length())
            }
        }
        let dest: utf8 = path_join(target_directory, relative)
        let parent: utf8 = path_parent(dest)
        if parent.length() > 0 {
            std.io.create_directory(parent)
        }
        if std.io.write_file_text(dest, content) {
            count = count + 1
        }
        i = i + 1
    }
    return count
}

micro registry_publish(registry: Registry, options: PublishOptions, payload: utf8) -> PublishResult {
    if options.package_name.trim().length() == 0 || options.version.trim().length() == 0 {
        return PublishResult {
            success: false,
            package_name: options.package_name,
            version: options.version,
            message: "package_name/version required",
            published_url: "",
            dry_run: options.dry_run,
            size: payload.length(),
            file_count: 0,
            sha256: ""
        }
    }

    if options.dry_run {
        return PublishResult {
            success: true,
            package_name: options.package_name,
            version: options.version,
            message: "dry-run: skipped upload",
            published_url: "",
            dry_run: true,
            size: payload.length(),
            file_count: 0,
            sha256: "sha256-dry-run"
        }
    }

    let package_dir: utf8 = package_store_path(registry, options.package_name, options.version)
    let meta_path: utf8 = package_meta_path(registry, options.package_name, options.version)
    let version_dir: utf8 = path_join(path_join(registry.root, options.package_name), options.version)
    std.io.create_directory(path_join(registry.root, options.package_name))
    std.io.create_directory(version_dir)
    std.io.create_directory(package_dir)

    let payload_path: utf8 = path_join(version_dir, "payload.tgz.txt")
    std.io.write_file_text(payload_path, payload)
    if options.package_path.length() > 0 {
        copy_directory_files(options.package_path, package_dir)
    }

    let package: Package = Package {
        name: options.package_name,
        version: options.version,
        description: options.description,
        homepage: "",
        author: "",
        license: "",
        dist_path: payload_path,
        integrity: "sha256-len-" + options.package_name
    }
    write_package_meta(meta_path, package)

    return PublishResult {
        success: true,
        package_name: options.package_name,
        version: options.version,
        message: "published",
        published_url: path_join(registry.endpoint, options.package_name + "/" + options.version),
        dry_run: false,
        size: payload.length(),
        file_count: 1,
        sha256: package.integrity
    }
}

micro registry_download(registry: Registry, package: Package, target_directory: utf8) -> utf8 {
    std.io.create_directory(target_directory)
    let source_dir: utf8 = package_store_path(registry, package.name, package.version)
    if std.io.directory_exists(source_dir) {
        copy_directory_files(source_dir, target_directory)
        return target_directory
    }

    let q: utf8 = "\u{22}"
    let manifest: utf8 = "{\n    name: " + q + package.name + q + ",\n    version: " + q + package.version + q + ",\n}\n"
    std.io.write_file_text(path_join(target_directory, "legion.von"), manifest)
    if package.dist_path.length() > 0 && std.io.file_exists(package.dist_path) {
        std.io.write_file_text(path_join(target_directory, "payload.tgz.txt"), std.io.read_file_text(package.dist_path))
    }
    return target_directory
}

micro registry_verify_token(registry: Registry, token: utf8) -> TokenVerifyResult {
    if token.trim().length() == 0 {
        return token_failure("empty token")
    }
    if registry.kind == "mock" || registry.kind == "local" {
        return token_success("local-user")
    }
    return token_success("npm-user")
}

micro registry_insert_package(registry: Registry, package: Package, source_directory: utf8) -> bool {
    let package_dir: utf8 = package_store_path(registry, package.name, package.version)
    let version_dir: utf8 = path_join(path_join(registry.root, package.name), package.version)
    std.io.create_directory(path_join(registry.root, package.name))
    std.io.create_directory(version_dir)
    std.io.create_directory(package_dir)
    if source_directory.length() > 0 {
        copy_directory_files(source_directory, package_dir)
    }
    let mut stored: Package = package
    stored.dist_path = package_dir
    return write_package_meta(package_meta_path(registry, package.name, package.version), stored)
}
