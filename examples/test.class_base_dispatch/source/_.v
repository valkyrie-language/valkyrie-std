namespace class_base_dispatch;

class Animal {
    micro speak(self) -> utf8 {
        return "Animal"
    }
}

class Dog(Animal) {
    micro speak(self) -> utf8 {
        return Animal::speak(self)
    }
}

[main]
micro class_base_main() -> Unit {
    let dog = Dog {}
    print(dog.speak())
}
