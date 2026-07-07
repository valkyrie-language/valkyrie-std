namespace std.adaptor.jvm.collection;

[host_provider(std::collection::Array::length)]
private micro array_host_length<T>(array: [T]): usize {
    return __array_jvm_length::<T>(array)
}

[host_provider(std::collection::Array::get)]
private micro array_host_get<T>(array: [T], ordinal: usize): Option<T> {
    let item_count: usize = __array_jvm_length::<T>(array)
    if ordinal == 0 || ordinal > item_count {
        return None
    }

    return Some(__array_jvm_get::<T>(array, ordinal - 1))
}

[host_provider(std::collection::Array::set)]
private micro array_host_set<T>(array: [T], ordinal: usize, value: T): unit {
    let item_count: usize = __array_jvm_length::<T>(array)
    if ordinal == 0 || ordinal > item_count {
        return
    }

    __array_jvm_set::<T>(array, ordinal - 1, value)
}

[jvm("java.lang.reflect.Array", "getLength"), pure]
private micro __array_jvm_length<T>(array: [T]): usize { }

[jvm("java.lang.reflect.Array", "get"), pure]
private micro __array_jvm_get<T>(array: [T], index: usize): T { }

[jvm("java.lang.reflect.Array", "set")]
private micro __array_jvm_set<T>(array: [T], index: usize, value: T): unit { }
