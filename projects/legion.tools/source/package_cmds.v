namespace legion;

using std.io;
using nyar.package_registry;
using nyar.package_manager;

structure PackageCommandRequest {
    project: utf8
    package_name: utf8
    version: utf8
    registry: utf8
    token: utf8
    tag: utf8
    access: utf8
    bump: utf8
    query: utf8
    dry_run: bool
    frozen_lockfile: bool
    skip_git_check: bool
    verbose: bool
}

micro empty_package_command_request() -> PackageCommandRequest {
    return PackageCommandRequest {
        project: "",
        package_name: "",
        version: "latest",
        registry: "local",
        token: "",
        tag: "latest",
        access: "public",
        bump: "",
        query: "",
        dry_run: false,
        frozen_lockfile: false,
        skip_git_check: false,
        verbose: false
    }
}

micro parse_package_command_request(args: [utf8]) -> PackageCommandRequest {
    let mut request: PackageCommandRequest = empty_package_command_request()
    let mut i: usize = 0
    while i < args.length() {
        let arg: utf8 = args[i]
        if arg == "--registry" {
            if i + 1 < args.length() {
                request.registry = args[i + 1]
            }
            i = i + 2
            continue
        }
        if arg.starts_with("--registry=") {
            request.registry = arg.slice(11, arg.length())
            i = i + 1
            continue
        }
        if arg == "--version" {
            if i + 1 < args.length() {
                request.version = args[i + 1]
            }
            i = i + 2
            continue
        }
        if arg.starts_with("--version=") {
            request.version = arg.slice(10, arg.length())
            i = i + 1
            continue
        }
        if arg == "--token" {
            if i + 1 < args.length() {
                request.token = args[i + 1]
            }
            i = i + 2
            continue
        }
        if arg == "--tag" {
            if i + 1 < args.length() {
                request.tag = args[i + 1]
            }
            i = i + 2
            continue
        }
        if arg == "--access" {
            if i + 1 < args.length() {
                request.access = args[i + 1]
            }
            i = i + 2
            continue
        }
        if arg == "--bump" {
            if i + 1 < args.length() {
                request.bump = args[i + 1]
            }
            i = i + 2
            continue
        }
        if arg == "--dry-run" {
            request.dry_run = true
            i = i + 1
            continue
        }
        if arg == "--frozen-lockfile" {
            request.frozen_lockfile = true
            i = i + 1
            continue
        }
        if arg == "--skip-git-check" {
            request.skip_git_check = true
            i = i + 1
            continue
        }
        if arg == "-v" || arg == "--verbose" {
            request.verbose = true
            i = i + 1
            continue
        }
        if !arg.starts_with("-") {
            if request.package_name.length() == 0 && (arg.contains("@") || arg.contains(".") || arg.contains("-") || arg.contains("_")) {
                # package name or project path: prefer package when looks like identifier, else project
            }
            if request.project.length() == 0 && (arg.contains("/") || arg.contains("\u{5c}") || arg == "." || arg == "..") {
                request.project = arg
            } else if request.package_name.length() == 0 {
                request.package_name = arg
                request.query = arg
            } else if request.project.length() == 0 {
                request.project = arg
            }
        }
        i = i + 1
    }
    return request
}

micro default_registry_root() -> utf8 {
    return path_join(path_join(std.io.get_current_directory(), ".valkyrie"), "registry")
}

micro open_default_manager(project_dir: utf8, registry_name: utf8) -> PackageManager {
    let registry: Registry = if registry_name == "npm" {
        default_npm_registry(path_join(default_registry_root(), "npm"))
    } else if registry_name == "mock" {
        new_mock_registry("mock", path_join(default_registry_root(), "mock"))
    } else {
        new_local_registry("local", path_join(default_registry_root(), "local"))
    }
    return open_package_manager(project_dir, registry)
}

micro execute_check(args: [utf8]) -> unit {
    std.io.print_line("check：验证项目可编译性（复用 build）")
    execute_build(args)
}

micro execute_registry_publish(args: [utf8]) -> unit {
    let request: PackageCommandRequest = parse_package_command_request(args)
    let project_dir: utf8 = resolve_project_dir(request.project)
    let mut manager: PackageManager = open_default_manager(project_dir, request.registry)
    let mut options: PublishOptions = empty_publish_options()
    options.registry_name = request.registry
    options.tag = request.tag
    options.access = request.access
    options.bump = request.bump
    options.dry_run = request.dry_run
    options.skip_git_check = request.skip_git_check
    options.create_git_tag = false
    options.auth_token = request.token
    let publish_attempt: PublishAttempt = manager_publish_attempt(manager, options)
    if !publish_attempt.ok {
        std.io.error("发布失败: " + publish_attempt.error)
        return
    }
    let result: PublishResult = publish_attempt.result
    if result.success {
        if result.dry_run {
            std.io.print_line("dry-run 成功: " + result.package_name + "@" + result.version)
        } else {
            std.io.print_line("发布成功: " + result.package_name + "@" + result.version)
            if result.published_url.length() > 0 {
                std.io.print_line("URL: " + result.published_url)
            }
        }
    } else {
        std.io.error("发布失败: " + result.message)
    }
}

micro execute_install(args: [utf8]) -> unit {
    let request: PackageCommandRequest = parse_package_command_request(args)
    let project_dir: utf8 = resolve_project_dir(request.project)
    let mut manager: PackageManager = open_default_manager(project_dir, request.registry)
    manager.frozen_lockfile = request.frozen_lockfile
    if request.package_name.length() > 0 {
        let install_attempt: PackageInstallAttempt = manager_install_one_attempt(manager, request.package_name, request.version)
        if !install_attempt.ok {
            std.io.error("安装失败: " + install_attempt.error)
        } else {
            let package: Package = install_attempt.package
            std.io.print_line("已安装 " + package.name + "@" + package.version)
        }
        return
    }
    let deps_attempt: CountInstallAttempt = manager_install_dependencies_attempt(manager)
    if !deps_attempt.ok {
        std.io.error("安装失败: " + deps_attempt.error)
        return
    }
    let count: usize = deps_attempt.count
    if count == 0 {
        std.io.print_line("没有需要安装的依赖")
    } else {
        std.io.print_line("依赖安装完成")
    }
}

micro execute_add(args: [utf8]) -> unit {
    execute_install(args)
}

micro execute_remove(args: [utf8]) -> unit {
    let request: PackageCommandRequest = parse_package_command_request(args)
    if request.package_name.length() == 0 {
        std.io.error("错误：请指定要移除的包名")
        return
    }
    let project_dir: utf8 = resolve_project_dir(request.project)
    let mut manager: PackageManager = open_default_manager(project_dir, request.registry)
    lock_remove_package(manager.lock_file, request.package_name)
    save_lock_file(manager.lock_file)
    std.io.print_line("已移除依赖 " + request.package_name)
}

micro execute_update(args: [utf8]) -> unit {
    let request: PackageCommandRequest = parse_package_command_request(args)
    let project_dir: utf8 = resolve_project_dir(request.project)
    let mut manager: PackageManager = open_default_manager(project_dir, request.registry)
    let package_name: utf8 = request.package_name
    if package_name.length() == 0 {
        std.io.error("错误：请指定要更新的包名")
        return
    }
    lock_remove_package(manager.lock_file, package_name)
    let update_attempt: PackageInstallAttempt = manager_install_one_attempt(manager, package_name, request.version)
    if !update_attempt.ok {
        std.io.error("更新失败: " + update_attempt.error)
        return
    }
    let package: Package = update_attempt.package
    std.io.print_line("已更新 " + package.name + "@" + package.version)
}

micro execute_search(args: [utf8]) -> unit {
    let request: PackageCommandRequest = parse_package_command_request(args)
    let project_dir: utf8 = resolve_project_dir(request.project)
    let manager: PackageManager = open_default_manager(project_dir, request.registry)
    let packages: [Package] = manager_search(manager, request.query)
    if packages.length() == 0 {
        std.io.print_line("未找到匹配包")
        return
    }
    let mut i: usize = 0
    while i < packages.length() {
        let package: Package = packages[i]
        std.io.print_line(package.name + "@" + package.version + "  " + package.description)
        i = i + 1
    }
}

micro execute_info(args: [utf8]) -> unit {
    let request: PackageCommandRequest = parse_package_command_request(args)
    if request.package_name.length() == 0 {
        std.io.error("错误：请指定包名")
        return
    }
    let project_dir: utf8 = resolve_project_dir(request.project)
    let manager: PackageManager = open_default_manager(project_dir, request.registry)
    let info_attempt: RegistryPackageAttempt = manager_info_attempt(manager, request.package_name)
    if !info_attempt.ok {
        std.io.error("查询失败: " + info_attempt.error)
        return
    }
    let package: Package = info_attempt.package
    std.io.print_line("name:        " + package.name)
    std.io.print_line("version:     " + package.version)
    std.io.print_line("description: " + package.description)
}

micro execute_vendor(args: [utf8]) -> unit {
    if args.length() == 0 {
        std.io.error("用法：legion vendor login|logout|list|whoami")
        return
    }
    let sub: utf8 = args[0]
    let rest: [utf8] = collect_tail_args(args, 1)
    let request: PackageCommandRequest = parse_package_command_request(rest)
    let project_dir: utf8 = resolve_project_dir(request.project)
    let manager: PackageManager = open_default_manager(project_dir, request.registry)
    if sub == "login" {
        let result: TokenVerifyResult = manager_vendor_login(manager, request.token)
        if result.valid {
            std.io.print_line("已登录 " + request.registry + " 为 " + result.username)
        } else {
            std.io.error("登录失败: " + result.error_message)
        }
        return
    }
    if sub == "whoami" {
        let result: TokenVerifyResult = manager_vendor_login(manager, "local-token")
        if result.valid {
            std.io.print_line(result.username)
        } else {
            std.io.error(result.error_message)
        }
        return
    }
    if sub == "list" || sub == "logout" {
        std.io.print_line("vendor " + sub + "：本地注册表无需持久化凭证")
        return
    }
    std.io.error("未知 vendor 子命令：" + sub)
}
