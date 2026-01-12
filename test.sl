fn add(a: int, b: int) -> int {
    return a + b;
}

lowlevel get42() -> @rax {
    mov(@rax, 42);
}

struct Lexer {
    source: string,
    pos: int
}

fn (mut l: Lexer) next() -> char {
    return 'A';
}

fn vars_test() -> int {
    let x: int = 5;
    let y: int = 10;
    let z: int = x + y;
    return z;
}

fn if_test() -> int {
    if 1 != 2 {
        return 5;
    } else {
        return 10;
    }
}

fn while_test() -> int {
    let result: int = 123;
    let big: int = 100;
    let small: int = 1;

    while big < small {}

    return result;
}