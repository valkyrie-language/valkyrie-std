structure SourceClosure {
    package_names: [utf8]
}

structure CompilePlan {
    source_closure: SourceClosure
}

[main]
micro main(plan: CompilePlan) -> i64 {
    return plan.source_closure.package_names.length()
}