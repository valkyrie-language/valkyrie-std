namespace std.adaptor.clr.collection;

[host_provider(std::collection::ArrayList::new)]
private micro array_list_host_new<T>(capacity: usize): std.collection.ArrayList<T> {
    return __array_list_clr_new::<T>(capacity)
}

[host_provider(std::collection::ArrayList::capacity)]
private micro array_list_host_capacity<T>(list: std.collection.ArrayList<T>): usize {
    return __array_list_clr_capacity::<T>(list)
}

[host_provider(std::collection::ArrayList::push)]
private micro array_list_host_push<T>(list: std.collection.ArrayList<T>, value: T): unit {
    __array_list_clr_add::<T>(list, value)
}

[host_provider(std::collection::ArrayList::insert)]
private micro array_list_host_insert<T>(list: std.collection.ArrayList<T>, index: usize, value: T): unit {
    __array_list_clr_insert::<T>(list, index, value)
}

[host_provider(std::collection::ArrayList::remove)]
private micro array_list_host_remove<T>(list: std.collection.ArrayList<T>, index: usize): T {
    let value: T = __array_list_clr_get::<T>(list, index)
    __array_list_clr_remove_at::<T>(list, index)
    return value
}

[host_provider(std::collection::ArrayList::clear)]
private micro array_list_host_clear<T>(list: std.collection.ArrayList<T>): unit {
    __array_list_clr_clear::<T>(list)
}

[host_provider(std::collection::ArrayList::length)]
private micro array_list_host_length<T>(list: std.collection.ArrayList<T>): usize {
    return __array_list_clr_length::<T>(list)
}

[host_provider(std::collection::ArrayList::get)]
private micro array_list_host_get<T>(list: std.collection.ArrayList<T>, index: usize): T {
    return __array_list_clr_get::<T>(list, index)
}

[host_provider(std::collection::ArrayList::set)]
private micro array_list_host_set<T>(list: std.collection.ArrayList<T>, index: usize, value: T): unit {
    __array_list_clr_set::<T>(list, index, value)
}

[host_provider(std::collection::ArrayList::contains)]
private micro array_list_host_contains<T>(list: std.collection.ArrayList<T>, value: T): bool {
    return __array_list_clr_contains::<T>(list, value)
}

[clr("System.Collections", "System.Collections.Generic.List`1", ".ctor")]
private micro __array_list_clr_new<T>(capacity: usize): std.collection.ArrayList<T> { }

[clr("System.Collections", "System.Collections.Generic.List`1", "get_Count"), pure]
private micro __array_list_clr_length<T>(list: std.collection.ArrayList<T>): usize { }

[clr("System.Collections", "System.Collections.Generic.List`1", "get_Capacity"), pure]
private micro __array_list_clr_capacity<T>(list: std.collection.ArrayList<T>): usize { }

[clr("System.Collections", "System.Collections.Generic.List`1", "Add")]
private micro __array_list_clr_add<T>(list: std.collection.ArrayList<T>, value: T): unit { }

[clr("System.Collections", "System.Collections.Generic.List`1", "Insert")]
private micro __array_list_clr_insert<T>(list: std.collection.ArrayList<T>, index: usize, value: T): unit { }

[clr("System.Collections", "System.Collections.Generic.List`1", "get_Item"), pure]
private micro __array_list_clr_get<T>(list: std.collection.ArrayList<T>, index: usize): T { }

[clr("System.Collections", "System.Collections.Generic.List`1", "set_Item")]
private micro __array_list_clr_set<T>(list: std.collection.ArrayList<T>, index: usize, value: T): unit { }

[clr("System.Collections", "System.Collections.Generic.List`1", "RemoveAt")]
private micro __array_list_clr_remove_at<T>(list: std.collection.ArrayList<T>, index: usize): unit { }

[clr("System.Collections", "System.Collections.Generic.List`1", "Clear")]
private micro __array_list_clr_clear<T>(list: std.collection.ArrayList<T>): unit { }

[clr("System.Collections", "System.Collections.Generic.List`1", "Contains"), pure]
private micro __array_list_clr_contains<T>(list: std.collection.ArrayList<T>, value: T): bool { }
