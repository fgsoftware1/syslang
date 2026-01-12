global next

next:
    push rbp  ; Save old base pointer
    mov rbp, rsp  ; Set up new stack frame
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
    jmp end_0  ; Skip else block
else_0:
    ; Else block
end_0:
    ; --- End if ---
    ; Return statement
    ; Evaluate return value
    mov rax, 65  ; Load character literal (65)
    ; (Return value now in rax)
    mov rsp, rbp  ; Restore stack pointer
    pop rbp  ; Restore base pointer
    ret  ; Return to caller

global add

add:
    push rbp  ; Save old base pointer
    mov rbp, rsp  ; Set up new stack frame
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
global test

test:
    push rbp  ; Save old base pointer
    mov rbp, rsp  ; Set up new stack frame
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
    je else_1  ; Jump to else_1 if condition false
    ; Then block
    ; Return statement
    ; Evaluate return value
    mov rax, 5  ; Load constant 5
    ; (Return value now in rax)
    jmp end_1  ; Skip else block
else_1:
    ; Else block
    ; Return statement
    ; Evaluate return value
    mov rax, 10  ; Load constant 10
    ; (Return value now in rax)
end_1:
    ; --- End if ---
    mov rsp, rbp  ; Restore stack pointer
    pop rbp  ; Restore base pointer
    ret  ; Return to caller
