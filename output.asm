global next

next:
    push rbp
    mov rbp, rsp
    mov rax, 1
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    cmp rax, rbx
    je else_0
    jmp end_0
else_0:
end_0:
    mov rax, 65
    mov rsp, rbp
    pop rbp
    ret
global add

add:
    push rbp
    mov rbp, rsp
    mov rax, rdi
    push rax
    mov rax, rsi
    mov rbx, rax
    pop rax
    add rax, rbx
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
global test

test:
    push rbp
    mov rbp, rsp
    mov rax, 1
    push rax
    mov rax, 2
    mov rbx, rax
    pop rax
    cmp rax, rbx
    je else_1
    mov rax, 5
    jmp end_1
else_1:
    mov rax, 10
end_1:
    mov rsp, rbp
    pop rbp
    ret