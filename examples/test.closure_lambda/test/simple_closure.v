namespace closure_lambda::test;

class Item { name: string; value: i32 }

[test]
micro simple_closure() -> unit {
    let items = [Item { name: "a", value: 1 }]
    let big = items.filter(x => x.value > 0)
    print("closure ok")
}
