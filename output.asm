global add

add:
    push rbp  ; Save old base pointer
    mov rbp, rsp  ; Set up new stack frame
    sub rsp, 64  ; Allocate space for locals (Hack)
    ; Function body
    ; Return statement
    ; Evaluate return value
    ; --- Binary expression: + ---
    ; Evaluate left operand
    mov rax, rdi  ; Load parameter "a"
    push rax  ; Save left result on stack
    ; Evaluate right operand
    mov rax, rsi  ; Load parameter "b"
    mov rbx, rax  ; Move right to rbx
    pop rax  ; Restore left to rax
    add rax, rbx  ; rax = rax + rbx
    ; (Return value now in rax)
    mov rsp, rbp  ; Restore stack pointer
    pop rbp  ; Restore base pointer
    ret  ; Return to caller

global get42

get42:
    push rbp  ; Save old base pointer
    mov rbp, rsp  ; Set up stack frame
    ; Lowlevel function body
    ; Opcode: mov
    mov rax, 42
    mov rsp, rbp  ; Restore stack pointer
    pop rbp  ; Restore base pointer
    ret  ; Return to caller
global next

next:
    push rbp  ; Save old base pointer
    mov rbp, rsp  ; Set up new stack frame
    sub rsp, 64  ; Allocate space for locals (Hack)
    ; Function body
    ; Return statement
    ; Evaluate return value
    mov rax, 65  ; Load character literal (65)
    ; (Return value now in rax)
    mov rsp, rbp  ; Restore stack pointer
    pop rbp  ; Restore base pointer
    ret  ; Return to caller

global vars_test

vars_test:
    push rbp  ; Save old base pointer
    mov rbp, rsp  ; Set up new stack frame
    sub rsp, 64  ; Allocate space for locals (Hack)
    ; Function body
    ; Variable declaration: x
    mov rax, 5  ; Load constant 5
    mov [rbp-8], rax  ; Store to x
    ; Variable declaration: y
    mov rax, 10  ; Load constant 10
    mov [rbp-16], rax  ; Store to y
    ; Variable declaration: z
    ; --- Binary expression: + ---
    ; Evaluate left operand
    mov rax, [rbp-8]  ; Load variable "x"
    push rax  ; Save left result on stack
    ; Evaluate right operand
    mov rax, [rbp-16]  ; Load variable "y"
    mov rbx, rax  ; Move right to rbx
    pop rax  ; Restore left to rax
    add rax, rbx  ; rax = rax + rbx
    mov [rbp-24], rax  ; Store to z
    ; Return statement
    ; Evaluate return value
    mov rax, [rbp-24]  ; Load variable "z"
    ; (Return value now in rax)
    mov rsp, rbp  ; Restore stack pointer
    pop rbp  ; Restore base pointer
    ret  ; Return to caller

global if_test

if_test:
    push rbp  ; Save old base pointer
    mov rbp, rsp  ; Set up new stack frame
    sub rsp, 64  ; Allocate space for locals (Hack)
    ; Function body
    ; --- If statement ---
    ; Evaluate condition
    ; Evaluate comparison for conditional jump
    ; Evaluate left side
    mov rax, 1  ; Load constant 1
    push rax  ; Save left operand
    ; Evaluate right side
    mov rax, 2  ; Load constant 2
    mov rbx, rax  ; Move right to rbx
    pop rax  ; Restore left to rax
    cmp rax, rbx  ; Compare left and right
    je else_0  ; Jump to else_0 if condition false
    ; Then block
    ; Return statement
    ; Evaluate return value
    mov rax, 5  ; Load constant 5
    ; (Return value now in rax)
    jmp end_0  ; Skip else block
else_0:
    ; Else block
    ; Return statement
    ; Evaluate return value
    mov rax, 10  ; Load constant 10
    ; (Return value now in rax)
end_0:
    ; --- End if ---
    mov rsp, rbp  ; Restore stack pointer
    pop rbp  ; Restore base pointer
    ret  ; Return to caller

global while_test

while_test:
    push rbp  ; Save old base pointer
    mov rbp, rsp  ; Set up new stack frame
    sub rsp, 64  ; Allocate space for locals (Hack)
    ; Function body
    ; Variable declaration: result
    mov rax, 123  ; Load constant 123
    mov [rbp-32], rax  ; Store to result
    ; Variable declaration: big
    mov rax, 100  ; Load constant 100
    mov [rbp-40], rax  ; Store to big
    ; Variable declaration: small
    mov rax, 1  ; Load constant 1
    mov [rbp-48], rax  ; Store to small
    ; --- While statement ---
start_1:
    ; Evaluate condition
    ; Evaluate comparison for conditional jump
    ; Evaluate left side
    mov rax, [rbp-40]  ; Load variable "big"
    push rax  ; Save left operand
    ; Evaluate right side
    mov rax, [rbp-48]  ; Load variable "small"
    mov rbx, rax  ; Move right to rbx
    pop rax  ; Restore left to rax
    cmp rax, rbx  ; Compare left and right
    jge end_1  ; Jump to end_1 if condition false
    ; Then block
    jmp start_1  ; Keep looping
end_1:
    ; --- End while ---
    ; Return statement
    ; Evaluate return value
    mov rax, [rbp-32]  ; Load variable "result"
    ; (Return value now in rax)
    mov rsp, rbp  ; Restore stack pointer
    pop rbp  ; Restore base pointer
    ret  ; Return to caller
