namespace trait_default_dispatch;

trait Greeter {
    micro greet(self) -> utf8 {
        return "Trait Dispatch OK"
    }
}

class Dog {
}

[main]
micro trait_default_main() -> Unit {
    let dog = Dog {}
    print(dog.greet())
}
