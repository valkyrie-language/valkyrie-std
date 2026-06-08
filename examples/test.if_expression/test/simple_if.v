[test] 
micro easy_if_1() -> unit {
    let a = 10
    let b = 20
    let max = if a > b { a } else { b }
    print("max={max}")

    let label = if max > 15 {
        "big"
    } else if max > 5 {
        "medium"
    } else {
        "small"
    }
    print("label={label}")
}

# valkyrie 中 modifier `xxx` 和 attribute `xxx` 完全等价
test micro easy_if_2() -> unit {

}

# 测试 if 表达式的性能, 可用过 legion benchmark 或 legion bench 触发
[benchmark]
micro easy_if_3() -> unit {

}

# raw id 也是 id，而且很建议在测试中使用 raw id 说清楚测试的是什么。
test micro `easy if`() -> unit {
    # 读取宏变量 build_type
    # 必然是 build，test，benchmark，coverage 之一
    if @build_type == "test" {
        print("build_type is test")
    } else {
        print("build_type is not test")
    }
    # 读取宏变量 build_mode
    # 必然是 production，development 之一
    if @build_mode == "production" {
        print("build_mode is production")
    } else {
        print("build_mode is development")
    }
}

# 复杂测试环境，需要在测试中初始化或者清理一些状态
tests `test block` {
    # 内部环境等同于 class body
    field: Typing = default;
    method() -> unit { }
    domain {
        field;
        method();
        domain { }
    }
}


# coverage 没有对应的 attribute，可直接通过 legion coverage 或者 legion cov 触发。


# 注意 legion test 并不会多平台尝试，只会使用 nyar vm 测试。
# 如需多平台测试，需要添加 --target jvm --target clr --target nyar 等参数
