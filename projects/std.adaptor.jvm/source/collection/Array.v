namespace std.adaptor.jvm.collection;

[host_provider(std::collection::__array_host_length)]
private micro array_host_length<T>(array: [T]): usize {
    return __array_jvm_length::<T>(array)
}

[host_provider(std::collection::__array_host_get)]
private micro array_host_get<T>(array: [T], index: usize): T {
    return __array_jvm_get::<T>(array, index)
}

[jvm("java.lang.reflect.Array", "getLength"), pure]
private micro __array_jvm_length<T>(array: [T]): usize { }

[jvm("java.lang.reflect.Array", "get"), pure]
private micro __array_jvm_get<T>(array: [T], index: usize): T { }
