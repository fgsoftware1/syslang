struct Lexer {
    source: string,
    pos: int
}

fn (mut l: Lexer) next() -> char {
    if 1 > 5 {
        print();
    } else {
        print();
    }
    return 'A';
}

fn add(a: int, b: int) -> int {
    return a + b;
}

lowlevel get42() -> @rax {
    mov(@rax, 42);
}
