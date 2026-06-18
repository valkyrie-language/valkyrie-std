namespace std.math.random;

[test]
micro `test random next_i32 stays in bounds`() {
    let generator: Random = Random::new()
    let mut i: i32 = 0

    while i < 64 {
        let value: i32 = generator.next_i32(10)
        if value < 0 {
            panic("random next_i32 lower bound test failed")
        }

        if value >= 10 {
            panic("random next_i32 bound test failed")
        }

        i = i + 1
    }
}

[test]
micro `test random range stays in bounds`() {
    let generator: Random = Random::new()
    let mut i: i32 = 0

    while i < 64 {
        let value: i32 = generator.next_range(3, 9)
        if value < 3 {
            panic("random range lower bound test failed")
        }

        if value >= 9 {
            panic("random range upper bound test failed")
        }

        i = i + 1
    }
}

[test]
micro `test random range handles empty span`() {
    let generator: Random = Random::new()

    if generator.next_range(5, 5) != 5 {
        panic("random empty span test failed")
    }

    if generator.next_range(8, 2) != 8 {
        panic("random reversed span test failed")
    }
}

[test]
micro `test random next f64 stays normalized`() {
    let generator: Random = Random::new()
    let value: f64 = generator.next_f64()

    if value < 0.0 {
        panic("random f64 lower bound test failed")
    }

    if value >= 1.0 {
        panic("random f64 upper bound test failed")
    }
}

[test]
micro `test random seeded bounds stay valid`() {
    let generator: Random = Random::with_seed(99)
    let value: i32 = generator.next_i32(4)

    if value < 0 {
        panic("random seeded lower bound test failed")
    }

    if value >= 4 {
        panic("random seeded upper bound test failed")
    }
}
