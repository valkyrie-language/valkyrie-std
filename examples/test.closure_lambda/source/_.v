namespace closure_lambda;

class Item { name: string; value: i32 }

[main]
micro closure_main() -> ExitCode {
    let items = [Item { name: "a", value: 1 }, Item { name: "b", value: 2 }]

    let names = items.map(.name)
    print("field shorthand ok")

    let big = items.filter(x => x.value > 0)
    print("lambda ok")

    let mapped = items.map(micro(item) -> string {
        return item.name
    })
    print("full closure ok")

    return ExitCode(0 as i32)
}