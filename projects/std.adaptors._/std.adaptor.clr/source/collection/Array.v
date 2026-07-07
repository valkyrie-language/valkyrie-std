namespace std.adaptor.clr.collection;

# Array::length uses std `[intrinsic("array.len")]` `__array_len` (f64.add pattern), not host_provider.

[host_provider(std::collection::Array::get)]
private micro array_host_get<T>(array: [T], ordinal: usize): Option<T> {
    let item_count: usize = __array_clr_length::<T>(array)
    if ordinal == 0 || ordinal > item_count {
        return None
    }

    return Some(__array_clr_get::<T>(array, ordinal - 1))
}

[host_provider(std::collection::Array::set)]
private micro array_host_set<T>(array: [T], ordinal: usize, value: T): unit {
    let item_count: usize = __array_clr_length::<T>(array)
    if ordinal == 0 || ordinal > item_count {
        return
    }

    __array_clr_set::<T>(array, ordinal - 1, value)
}

[clr("System.Runtime", "System.Array", "get_Length"), pure]
private micro __array_clr_length<T>(array: [T]): usize { }

[clr("System.Runtime", "System.Array", "GetValue"), pure]
private micro __array_clr_get<T>(array: [T], index: usize): T { }

[clr("System.Runtime", "System.Array", "SetValue")]
private micro __array_clr_set<T>(array: [T], index: usize, value: T): unit { }
