namespace std.data.binary.jvm;

structure JvmBinaryClassFile {
    magic: u32

    minor_version: u16

    major_version: u16

    constant_pool: [JvmBinaryConstant]

    access_flags: u16

    this_class: u16

    super_class: u16

    interfaces: [u16]

    fields: [JvmBinaryField]

    methods: [JvmBinaryMethod]

    attributes: [JvmBinaryAttribute]
}

structure JvmBinaryConstant {
    tag: i32

    data: [i32]
}

structure JvmBinaryField {
    access_flags: u16

    name_index: u16

    descriptor_index: u16

    attributes: [JvmBinaryAttribute]
}

structure JvmBinaryMethod {
    access_flags: u16

    name_index: u16

    descriptor_index: u16

    attributes: [JvmBinaryAttribute]
}

structure JvmBinaryAttribute {
    name_index: u16

    data: [i32]
}
