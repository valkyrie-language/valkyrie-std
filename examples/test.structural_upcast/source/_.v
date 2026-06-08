namespace structural_upcast;

trait Speaker {
    micro show(self) -> string
}

class Dog {
    micro show(self) -> string {
        return "Dog"
    }
}

micro accept(value: Speaker) -> Unit {
    print("Structural Upcast OK")
}

[main]
micro structural_upcast_main() -> ExitCode {
    let dog = Dog {}
    accept(dog)

    let speaker = dog as Speaker
    accept(speaker)

    return ExitCode(0 as i32)
}
