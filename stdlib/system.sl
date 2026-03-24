module system;

pub asm exit(code: int -> @rdi) {
    mov($60, @rax);
    syscall();
}

pub asm write(fd: int -> @rdi, buf: int -> @rsi, count: int -> @rdx) {
    mov($1, @rax);
    syscall();
}
