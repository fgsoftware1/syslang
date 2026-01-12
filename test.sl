struct Lexer {
    source: string,
    pos: int
}

fn (mut l: Lexer) next() -> char {
    let x: int = 0;
    if 1 != 2 {} else{}
    return 'A';
}

fn add(a: int, b: int) -> int {
    return a + b;
}

lowlevel get42() -> @rax {
    mov(@rax, 42);
}

fn test() -> int {
    if 1 != 2 {
        return 5;
    } else {
        return 10;
    }
}