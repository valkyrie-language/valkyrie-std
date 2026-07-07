namespace nyar.package_manager;

using std.io;
using std.data.text.von;
using nyar.package_registry;

# package 清单中的依赖项
structure PackageDependency {
    name: utf8
    version: utf8
    is_workspace: bool
}

# package 清单（面向安装/发布，独立于产物信道 publish[]）
structure PackageManifest {
    name: utf8
    version: utf8
    description: utf8
    homepage: utf8
    license: utf8
    registry: utf8
    access: utf8
    tag: utf8
    dependencies: [PackageDependency]
}

# lock 条目
structure LockEntry {
    name: utf8
    version: utf8
    registry: utf8
    resolved: utf8
    integrity: utf8
    is_workspace: bool
    install_path: utf8
}

# lock 文件
structure LockFile {
    version: utf8
    packages: [LockEntry]
    path: utf8
}

# pack 结果
structure PackResult {
    payload: utf8
    sha256: utf8
    size: usize
    file_count: usize
}

# 包管理器上下文
structure PackageManager {
    root: utf8
    registry: Registry
    lock_file: LockFile
    manifest: PackageManifest
    has_manifest: bool
    frozen_lockfile: bool
}

[tag(PmResultKind)]
unite PmResult<T> {
    [tag(0)]
    Fine { value: T }
    [tag(1)]
    Fail { error: utf8 }
}

structure PackageInstallAttempt {
    ok: bool
    package: Package
    error: utf8
}

structure CountInstallAttempt {
    ok: bool
    count: usize
    error: utf8
}

structure PublishAttempt {
    ok: bool
    result: PublishResult
    error: utf8
}

micro empty_manifest() -> PackageManifest {
    return PackageManifest {
        name: "",
        version: "0.1.0",
        description: "",
        homepage: "",
        license: "",
        registry: "npm",
        access: "public",
        tag: "latest",
        dependencies: []
    }
}

micro empty_lock(path: utf8) -> LockFile {
    return LockFile {
        version: "1",
        packages: [],
        path: path
    }
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

micro manifest_path(root: utf8) -> utf8 {
    return path_join(root, "legion.von")
}

micro lock_path(root: utf8) -> utf8 {
    return path_join(root, "legion-lock.von")
}

micro vendors_path(root: utf8) -> utf8 {
    return path_join(root, "vendors")
}

micro parse_dependency_field(name: utf8, value: VonValue) -> PackageDependency {
    let mut version: utf8 = ""
    let mut is_workspace: bool = false
    if von_is_object(value) {
        version = von_as_text(von_find_field(value, "version"))
    }
    else {
        version = von_as_text(value)
    }
    if version == "workspace" || version.starts_with("workspace:") {
        is_workspace = true
    }
    return PackageDependency {
        name: name,
        version: version,
        is_workspace: is_workspace
    }
}

micro load_package_manifest_option(root: utf8) -> PackageManifest? {
    let path: utf8 = manifest_path(root)
    if !std.io.file_exists(path) {
        return None
    }
    let source: utf8 = std.io.read_file_text(path)
    let parsed: VonParseResult<VonValue> = parse_von(source)
    if von_parse_take_fail(parsed).is_some() {
        return None
    }
    let document: VonValue = von_parse_take_fine(parsed).unwrap()
    let deps_value: VonValue = von_find_field(document, "dependencies")
    let mut dependencies: [PackageDependency] = []
    let fields: [VonField] = von_as_object(deps_value)
    let mut i: usize = 0
    while i < fields.length() {
        let field: VonField = fields⁅i⁆
        push(dependencies, parse_dependency_field(field.name, field.value))
        i = i + 1
    }

    let publish_config: VonValue = von_find_field(document, "publishConfig")
    let mut registry: utf8 = "npm"
    let mut access: utf8 = "public"
    let mut tag: utf8 = "latest"
    if von_is_object(publish_config) {
        let registry_text: utf8 = von_as_text(von_find_field(publish_config, "registry"))
        if registry_text.length() > 0 {
            registry = registry_text
        }
        let access_text: utf8 = von_as_text(von_find_field(publish_config, "access"))
        if access_text.length() > 0 {
            access = access_text
        }
        let tag_text: utf8 = von_as_text(von_find_field(publish_config, "tag"))
        if tag_text.length() > 0 {
            tag = tag_text
        }
    }

    return PackageManifest {
        name: von_as_text(von_find_field(document, "name")),
        version: von_as_text(von_find_field(document, "version")),
        description: von_as_text(von_find_field(document, "description")),
        homepage: von_as_text(von_find_field(document, "homepage")),
        license: von_as_text(von_find_field(document, "license")),
        registry: registry,
        access: access,
        tag: tag,
        dependencies: dependencies
    }
}

micro load_package_manifest(root: utf8) -> PmResult<PackageManifest> {
    let manifest_opt: PackageManifest? = load_package_manifest_option(root)
    if manifest_opt.is_some() {
        return Fine(manifest_opt.unwrap())
    }
    if !std.io.file_exists(manifest_path(root)) {
        return Fail("missing legion.von")
    }
    return Fail("invalid legion.von")
}

micro save_lock_file(lock: LockFile) -> bool {
    let q: utf8 = "\u{22}"
    let mut content: utf8 = "{\n    version: " + q + lock.version + q + ",\n    packages: {\n"
    let mut i: usize = 0
    while i < lock.packages.length() {
        let entry: LockEntry = lock.packages⁅i⁆
        let key: utf8 = entry.name + "@" + entry.version
        content = content + "        " + q + key + q + ": {\n"
        content = content + "            name: " + q + entry.name + q + ",\n"
        content = content + "            version: " + q + entry.version + q + ",\n"
        content = content + "            registry: " + q + entry.registry + q + ",\n"
        content = content + "            resolved: " + q + entry.resolved + q + ",\n"
        content = content + "            integrity: " + q + entry.integrity + q + ",\n"
        content = content + "            install_path: " + q + entry.install_path + q + ",\n"
        if entry.is_workspace {
            content = content + "            is_workspace: true,\n"
        }
        content = content + "        },\n"
        i = i + 1
    }
    content = content + "    },\n}\n"
    return std.io.write_file_text(lock.path, content)
}

micro load_lock_file(root: utf8) -> LockFile {
    let path: utf8 = lock_path(root)
    let mut lock: LockFile = empty_lock(path)
    if !std.io.file_exists(path) {
        return lock
    }
    let source: utf8 = std.io.read_file_text(path)
    let parsed: VonParseResult<VonValue> = parse_von(source)
    if von_parse_take_fail(parsed).is_none() {
        let document: VonValue = von_parse_take_fine(parsed).unwrap()
        lock.version = von_as_text(von_find_field(document, "version"))
        let packages_value: VonValue = von_find_field(document, "packages")
        let fields: [VonField] = von_as_object(packages_value)
        let mut i: usize = 0
        while i < fields.length() {
            let field: VonField = fields⁅i⁆
            let entry_value: VonValue = field.value
            push(lock.packages, LockEntry {
                name: von_as_text(von_find_field(entry_value, "name")),
                version: von_as_text(von_find_field(entry_value, "version")),
                registry: von_as_text(von_find_field(entry_value, "registry")),
                resolved: von_as_text(von_find_field(entry_value, "resolved")),
                integrity: von_as_text(von_find_field(entry_value, "integrity")),
                is_workspace: von_as_bool(von_find_field(entry_value, "is_workspace")),
                install_path: von_as_text(von_find_field(entry_value, "install_path"))
            })
            i = i + 1
        }
    }
    return lock
}

micro lock_has_package(lock: LockFile, name: utf8, version: utf8) -> bool {
    let mut i: usize = 0
    while i < lock.packages.length() {
        let entry: LockEntry = lock.packages⁅i⁆
        if entry.name == name && (version == "latest" || entry.version == version) {
            return true
        }
        i = i + 1
    }
    return false
}

micro lock_remove_package(mut lock: LockFile, name: utf8) -> unit {
    let mut next: [LockEntry] = []
    let mut i: usize = 0
    while i < lock.packages.length() {
        if lock.packages⁅i⁆.name != name {
            push(next, lock.packages⁅i⁆)
        }
        i = i + 1
    }
    lock.packages = next
}

micro lock_add_package(mut lock: LockFile, package: Package, registry_name: utf8, install_path: utf8) -> unit {
    lock_remove_package(lock, package.name)
    push(lock.packages, LockEntry {
        name: package.name,
        version: package.version,
        registry: registry_name,
        resolved: package.dist_path,
        integrity: package.integrity,
        is_workspace: false,
        install_path: install_path
    })
}

micro pack_package(package_path: utf8) -> PackResult {
    let files: [utf8] = std.io.get_files(package_path, "*", true)
    let mut payload: utf8 = "legion-pack-v1\n"
    let mut count: usize = 0
    let mut i: usize = 0
    while i < files.length() {
        let file: utf8 = files⁅i⁆.replace("\u{5c}", "/")
        if file.contains("/vendors/") || file.contains("/.git/") || file.ends_with("legion-lock.von") {
            i = i + 1
            continue
        }
        let content: utf8 = std.io.read_file_text(files⁅i⁆)
        payload = payload + "FILE " + file + "\n"
        payload = payload + content + "\nEND\n"
        count = count + 1
        i = i + 1
    }
    return PackResult {
        payload: payload,
        sha256: "sha256-pack",
        size: payload.length(),
        file_count: count
    }
}

micro bump_version(version: utf8, bump: utf8) -> utf8 {
    if bump == "major" {
        return version + "+major"
    }
    if bump == "minor" {
        return version + "+minor"
    }
    if bump == "patch" {
        return version + "+patch"
    }
    return version
}

micro open_package_manager(root: utf8, registry: Registry) -> PackageManager {
    let mut manager: PackageManager = PackageManager {
        root: root,
        registry: registry,
        lock_file: load_lock_file(root),
        manifest: empty_manifest(),
        has_manifest: false,
        frozen_lockfile: false
    }
    let manifest_opt: PackageManifest? = load_package_manifest_option(root)
    if manifest_opt.is_some() {
        manager.manifest = manifest_opt.unwrap()
        manager.has_manifest = true
    }
    return manager
}

micro manager_install_one_attempt(mut manager: PackageManager, package_name: utf8, version: utf8) -> PackageInstallAttempt {
    if manager.frozen_lockfile && version != "latest" && !lock_has_package(manager.lock_file, package_name, version) {
        return PackageInstallAttempt {
            ok: false,
            package: empty_package(),
            error: "frozen lockfile missing " + package_name + "@" + version
        }
    }

    let lookup: RegistryPackageAttempt = registry_get_package_attempt(manager.registry, package_name, version)
    if !lookup.ok {
        return PackageInstallAttempt {
            ok: false,
            package: empty_package(),
            error: lookup.error
        }
    }
    let package: Package = lookup.package
    let install_dir: utf8 = path_join(path_join(vendors_path(manager.root), manager.registry.name), package.name + "@" + package.version)
    std.io.create_directory(vendors_path(manager.root))
    std.io.create_directory(path_join(vendors_path(manager.root), manager.registry.name))
    let unused_path: utf8 = registry_download(manager.registry, package, install_dir)
    lock_add_package(manager.lock_file, package, manager.registry.name, install_dir)
    save_lock_file(manager.lock_file)
    return PackageInstallAttempt {
        ok: true,
        package: package,
        error: ""
    }
}

micro manager_install_one(mut manager: PackageManager, package_name: utf8, version: utf8) -> PmResult<Package> {
    let attempt: PackageInstallAttempt = manager_install_one_attempt(manager, package_name, version)
    if attempt.ok {
        return Fine(attempt.package)
    }
    return Fail(attempt.error)
}

micro manager_install_dependencies_attempt(mut manager: PackageManager) -> CountInstallAttempt {
    if !manager.has_manifest {
        return CountInstallAttempt {
            ok: false,
            count: 0,
            error: "current directory is not a package"
        }
    }
    let mut count: usize = 0
    let mut i: usize = 0
    while i < manager.manifest.dependencies.length() {
        let dependency: PackageDependency = manager.manifest.dependencies⁅i⁆
        if dependency.is_workspace {
            i = i + 1
            continue
        }
        let mut version: utf8 = dependency.version
        if version.length() == 0 {
            version = "latest"
        }
        let install_attempt: PackageInstallAttempt = manager_install_one_attempt(manager, dependency.name, version)
        if !install_attempt.ok {
            return CountInstallAttempt {
                ok: false,
                count: 0,
                error: install_attempt.error
            }
        }
        let unused: utf8 = install_attempt.package.name
        count = count + 1
        i = i + 1
    }
    return CountInstallAttempt {
        ok: true,
        count: count,
        error: ""
    }
}

micro manager_install_dependencies(mut manager: PackageManager) -> PmResult<usize> {
    let attempt: CountInstallAttempt = manager_install_dependencies_attempt(manager)
    if attempt.ok {
        return Fine(attempt.count)
    }
    return Fail(attempt.error)
}

micro manager_publish_attempt(mut manager: PackageManager, mut options: PublishOptions) -> PublishAttempt {
    if !manager.has_manifest {
        return PublishAttempt {
            ok: false,
            result: PublishResult {
                success: false,
                package_name: "",
                version: "",
                message: "",
                published_url: "",
                dry_run: false,
                size: 0,
                file_count: 0,
                sha256: ""
            },
            error: "current directory is not a package"
        }
    }
    if options.package_name.length() == 0 {
        options.package_name = manager.manifest.name
    }
    if options.version.length() == 0 {
        options.version = manager.manifest.version
    }
    if options.description.length() == 0 {
        options.description = manager.manifest.description
    }
    if options.package_path.length() == 0 {
        options.package_path = manager.root
    }
    if options.registry_name.length() == 0 {
        options.registry_name = manager.manifest.registry
    }
    if options.tag.length() == 0 {
        options.tag = manager.manifest.tag
    }
    if options.access.length() == 0 {
        options.access = manager.manifest.access
    }
    if options.bump.length() > 0 {
        options.version = bump_version(options.version, options.bump)
    }

    let packed: PackResult = pack_package(options.package_path)
    if options.dry_run {
        return PublishAttempt {
            ok: true,
            result: PublishResult {
                success: true,
                package_name: options.package_name,
                version: options.version,
                message: "dry-run: skipped upload",
                published_url: "",
                dry_run: true,
                size: packed.size,
                file_count: packed.file_count,
                sha256: packed.sha256
            },
            error: ""
        }
    }

    let published: PublishResult = registry_publish(manager.registry, options, packed.payload)
    let result: PublishResult = PublishResult {
        success: published.success,
        package_name: published.package_name,
        version: published.version,
        message: published.message,
        published_url: published.published_url,
        dry_run: published.dry_run,
        size: packed.size,
        file_count: packed.file_count,
        sha256: packed.sha256
    }
    if result.success {
        return PublishAttempt {
            ok: true,
            result: result,
            error: ""
        }
    }
    return PublishAttempt {
        ok: false,
        result: result,
        error: result.message
    }
}

micro manager_publish(mut manager: PackageManager, mut options: PublishOptions) -> PmResult<PublishResult> {
    let attempt: PublishAttempt = manager_publish_attempt(manager, options)
    if attempt.ok {
        return Fine(attempt.result)
    }
    return Fail(attempt.error)
}

micro manager_search(manager: PackageManager, query: utf8) -> [Package] {
    return registry_search(manager.registry, query)
}

micro manager_info_attempt(manager: PackageManager, package_name: utf8) -> RegistryPackageAttempt {
    return registry_get_package_attempt(manager.registry, package_name, "latest")
}

micro manager_info(manager: PackageManager, package_name: utf8) -> PmResult<Package> {
    let attempt: RegistryPackageAttempt = manager_info_attempt(manager, package_name)
    if attempt.ok {
        return Fine(attempt.package)
    }
    return Fail(attempt.error)
}

micro manager_vendor_login(manager: PackageManager, token: utf8) -> TokenVerifyResult {
    return registry_verify_token(manager.registry, token)
}
