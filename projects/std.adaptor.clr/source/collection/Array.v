namespace std.adaptor.clr.collection;

[host_provider(std::collection::__array_host_length)]
private micro array_host_length<T>(array: std.collection.Array<T>): usize {
    return __array_clr_length::<T>(array)
}

[host_provider(std::collection::__array_host_get)]
private micro array_host_get<T>(array: std.collection.Array<T>, index: usize): T {
    return __array_clr_get::<T>(array, index)
}

[clr("System.Runtime", "System.Array", "get_Length"), pure]
private micro __array_clr_length<T>(array: std.collection.Array<T>): usize { }

[clr("System.Runtime", "System.Array", "GetValue"), pure]
private micro __array_clr_get<T>(array: std.collection.Array<T>, index: usize): T { }
