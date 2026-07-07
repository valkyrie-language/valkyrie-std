# std.adaptor.linux: Linux 内核系统调用
# 标准库只通过 [syscall] 绑定内核入口（不依赖 libc）。
# 用户代码若需 libc，可用 [c("libc", ...)] FFI。

#region 文件描述符

[syscall(1)]
micro sys_write(fd: i32, buf: c_str, length: i32): i64

[syscall(0)]
micro sys_read(fd: i32, buf: i32, length: i32): i64

[syscall(3)]
micro sys_close(fd: i32): i64

[syscall(2)]
micro sys_open(path: c_str, flags: i32, mode: i32): i64

[syscall(8)]
micro sys_lseek(fd: i32, offset: i64, whence: i32): i64

[syscall(72)]
micro sys_fcntl(fd: i32, cmd: i32, arg: i32): i64

[syscall(16)]
micro sys_ioctl(fd: i32, request: i64, arg: i32): i64

#endregion

#region 文件系统

[syscall(4)]
micro sys_stat(path: c_str, buf: i32): i64

[syscall(5)]
micro sys_fstat(fd: i32, buf: i32): i64

[syscall(83)]
micro sys_mkdir(path: c_str, mode: i32): i64

[syscall(84)]
micro sys_rmdir(path: c_str): i64

[syscall(87)]
micro sys_unlink(path: c_str): i64

[syscall(82)]
micro sys_rename(old: c_str, new_: c_str): i64

[syscall(90)]
micro sys_chmod(path: c_str, mode: i32): i64

[syscall(92)]
micro sys_chown(path: c_str, uid: i32, gid: i32): i64

#endregion

#region 内存

[syscall(9)]
micro sys_mmap(addr: i32, length: i32, prot: i32, flags: i32, fd: i32, offset: i64): i64

[syscall(11)]
micro sys_munmap(addr: i32, length: i32): i64

[syscall(10)]
micro sys_mprotect(addr: i32, length: i32, prot: i32): i64

#endregion

#region 进程

[syscall(39)]
micro sys_getpid(): i64

[syscall(110)]
micro sys_getppid(): i64

[syscall(102)]
micro sys_getuid(): i64

[syscall(104)]
micro sys_getgid(): i64

[syscall(57)]
micro sys_fork(): i64

[syscall(59)]
micro sys_execve(path: c_str, argv: i32, envp: i32): i64

[syscall(61)]
micro sys_wait4(pid: i32, status: i32, options: i32, rusage: i32): i64

[syscall(60)]
micro sys_exit(code: i32): void

#endregion

#region 信号

[syscall(62)]
micro sys_kill(pid: i32, sig: i32): i64

#endregion

#region 时间

[syscall(228)]
micro sys_clock_gettime(clock_id: i32, tp: i32): i64

[syscall(35)]
micro sys_nanosleep(req: i32, rem: i32): i64

[syscall(96)]
micro sys_gettimeofday(tv: i32, tz: i32): i64

#endregion

#region 网络

[syscall(41)]
micro sys_socket(domain: i32, type_: i32, protocol: i32): i64

[syscall(49)]
micro sys_bind(fd: i32, addr: i32, length: i32): i64

[syscall(50)]
micro sys_listen(fd: i32, backlog: i32): i64

[syscall(43)]
micro sys_accept(fd: i32, addr: i32, length: i32): i64

[syscall(42)]
micro sys_connect(fd: i32, addr: i32, length: i32): i64

[syscall(44)]
micro sys_sendto(fd: i32, buf: i32, length: i32, flags: i32, addr: i32, address_length: i32): i64

[syscall(45)]
micro sys_recvfrom(fd: i32, buf: i32, length: i32, flags: i32, addr: i32, address_length: i32): i64

#endregion
