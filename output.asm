global next

next:
    push rbp
    mov rbp, rsp
    mov rax, 65
    mov rsp, rbp
    pop rbp
    ret
global add

add:
    push rbp
    mov rbp, rsp
    mov rax, rdi
    add rax, rsi
    mov rsp, rbp
    pop rbp
    ret
global get42

get42:
    push rbp
    mov rbp, rsp
    mov rax, 42
    mov rsp, rbp
    pop rbp
    ret