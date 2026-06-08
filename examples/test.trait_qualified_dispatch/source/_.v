namespace trait_qualified_dispatch;

trait Printable {
    micro process(self) -> utf8 {
        return "Printable"
    }
}

trait Loggable {
    micro process(self) -> utf8 {
        return "Loggable"
    }
}

class Document {
}

imply Document: Printable {
}

[main]
micro trait_qualified_main() -> Unit {
    let doc = Document {}
    print(Loggable::process(doc))
}
