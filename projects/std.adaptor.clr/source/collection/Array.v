namespace std.adaptor.clr.collection;

[host_provider(std::collection::Array::length)]
private micro array_host_length<T>(array: [T]): usize {
    return __array_clr_length::<T>(array)
}

[host_provider(std::collection::Array::get)]
private micro array_host_get<T>(array: [T], index: usize): T {
    return __array_clr_get::<T>(array, index)
}

[clr("System.Runtime", "System.Array", "get_Length"), pure]
private micro __array_clr_length<T>(array: [T]): usize { }

[clr("System.Runtime", "System.Array", "GetValue"), pure]
private micro __array_clr_get<T>(array: [T], index: usize): T { }
