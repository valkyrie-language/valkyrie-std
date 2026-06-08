namespace nominal_upcast;

trait Speaker {
    micro speak(self) -> utf8
}

class Dog {
    micro speak(self) -> utf8 {
        return "Dog"
    }
}

micro accept(value: Speaker) -> Unit {
    print("Nominal Upcast OK")
    print(value.speak())
}

[main]
micro nominal_upcast_main() -> ExitCode {
    let dog = Dog {}
    let speaker: Speaker = dog
    accept(speaker)

    return ExitCode(0 as i32)
}