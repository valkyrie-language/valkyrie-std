namespace class_super_dispatch;

class Animal {
    micro speak(self) -> utf8 {
        return "Animal"
    }
}

class Dog(Animal) {
    micro speak(self) -> utf8 {
        return "Dog"
    }

    micro super_speak(self) -> utf8 {
        return Animal::speak(self)
    }
}

[main]
micro class_super_main() -> Unit {
    let dog = Dog {}
    print(dog.super_speak())
}