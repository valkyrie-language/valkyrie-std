namespace std.adaptor.jvm.collection;

[host_provider("std.collection.__array_list_host_new")]
private micro array_list_host_new<T>(capacity: usize): std.collection.ArrayList<T> {
    return __array_list_jvm_new::<T>(capacity)
}

[host_provider("std.collection.__array_list_host_capacity")]
private micro array_list_host_capacity<T>(list: std.collection.ArrayList<T>): usize {
    return __array_list_jvm_length::<T>(list)
}

[host_provider("std.collection.__array_list_host_push")]
private micro array_list_host_push<T>(list: std.collection.ArrayList<T>, value: T): unit {
    __array_list_jvm_add::<T>(list, value)
}

[host_provider("std.collection.__array_list_host_insert")]
private micro array_list_host_insert<T>(list: std.collection.ArrayList<T>, index: usize, value: T): unit {
    __array_list_jvm_insert::<T>(list, index, value)
}

[host_provider("std.collection.__array_list_host_remove")]
private micro array_list_host_remove<T>(list: std.collection.ArrayList<T>, index: usize): T {
    return __array_list_jvm_remove_at::<T>(list, index)
}

[host_provider("std.collection.__array_list_host_clear")]
private micro array_list_host_clear<T>(list: std.collection.ArrayList<T>): unit {
    __array_list_jvm_clear::<T>(list)
}

[host_provider("std.collection.__array_list_host_length")]
private micro array_list_host_length<T>(list: std.collection.ArrayList<T>): usize {
    return __array_list_jvm_length::<T>(list)
}

[host_provider("std.collection.__array_list_host_get")]
private micro array_list_host_get<T>(list: std.collection.ArrayList<T>, index: usize): T {
    return __array_list_jvm_get::<T>(list, index)
}

[host_provider("std.collection.__array_list_host_set")]
private micro array_list_host_set<T>(list: std.collection.ArrayList<T>, index: usize, value: T): unit {
    __array_list_jvm_set::<T>(list, index, value)
}

[host_provider("std.collection.__array_list_host_contains")]
private micro array_list_host_contains<T>(list: std.collection.ArrayList<T>, value: T): bool {
    return __array_list_jvm_contains::<T>(list, value)
}

[jvm("java.util.ArrayList", "<init>")]
private micro __array_list_jvm_new<T>(capacity: usize): std.collection.ArrayList<T> { }

[jvm("java.util.ArrayList", "size"), pure]
private micro __array_list_jvm_length<T>(list: std.collection.ArrayList<T>): usize { }

[jvm("java.util.ArrayList", "add")]
private micro __array_list_jvm_add<T>(list: std.collection.ArrayList<T>, value: T): bool { }

[jvm("java.util.ArrayList", "add")]
private micro __array_list_jvm_insert<T>(list: std.collection.ArrayList<T>, index: usize, value: T): unit { }

[jvm("java.util.ArrayList", "get"), pure]
private micro __array_list_jvm_get<T>(list: std.collection.ArrayList<T>, index: usize): T { }

[jvm("java.util.ArrayList", "set")]
private micro __array_list_jvm_set<T>(list: std.collection.ArrayList<T>, index: usize, value: T): T { }

[jvm("java.util.ArrayList", "remove")]
private micro __array_list_jvm_remove_at<T>(list: std.collection.ArrayList<T>, index: usize): T { }

[jvm("java.util.ArrayList", "clear")]
private micro __array_list_jvm_clear<T>(list: std.collection.ArrayList<T>): unit { }

[jvm("java.util.ArrayList", "contains"), pure]
private micro __array_list_jvm_contains<T>(list: std.collection.ArrayList<T>, value: T): bool { }
