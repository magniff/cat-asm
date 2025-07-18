%DEFINE BUFFER_SIZE 4096000

%DEFINE READ_SYSCALL  0
%DEFINE WRITE_SYSCALL 1
%DEFINE OPEN_SYSCALL  2
%DEFINE CLOSE_SYSCALL 3
%DEFINE EXIT_SYSCALL  60

section .bss
    buffer: resb BUFFER_SIZE

section .text
    global _start

%macro WRITE 3
    mov rax, WRITE_SYSCALL
    mov rdi, %1
    mov rsi, %2
    mov rdx, %3
    syscall
%endmacro

%macro EXIT 1
    mov rax, EXIT_SYSCALL
    mov rdi, %1
    syscall
%endmacro

%macro READ 3
    mov rax, READ_SYSCALL
    mov rdi, %1
    mov rsi, %2
    mov rdx, %3
    syscall
%endmacro

%macro OPEN 1
    mov rax, OPEN_SYSCALL
    mov rdi, %1
    mov rsi, 0
    mov rdx, 0
    syscall
%endmacro

%macro CLOSE 1
    mov rax, CLOSE_SYSCALL
    mov rdi, %1
    mov rsi, 0
    mov rdx, 0
    syscall
%endmacro

_start:
    mov qword [rsp - 8], 0
    all_files:
        inc qword [rsp - 8]
        mov r10, qword [rsp - 8]
        cmp r10, qword [rsp]
        jge .done

        OPEN [rsp + 8 + r10 * 8]

        mov r12, rax
        mov rsi, r12
        cmp r12, 0

        jl .cant_open

        .read_chunk:
            READ r12, buffer, BUFFER_SIZE
            mov r11, rax
            cmp r11, 0
            je .complete_file
            WRITE 1, buffer, r11
            jmp .read_chunk
        
        .complete_file:
            CLOSE r12
            jmp all_files

        .done:
            EXIT 0

        .cant_open:
            mov rax, [rsp + 8 + r10 * 8]
            call .compute_string_len
            mov r9, rax
            WRITE 2, error_message, error_message_len
            WRITE 2, [rsp + 8 + r10 * 8], r9
            WRITE 2, newline, 1
            EXIT r12

        .compute_string_len:
            push rbp
            mov rbp, rsp
            sub rsp, 8
            mov qword [rbp - 8], 0
            .inner:
                cmp byte [rax], 0
                je .return
                inc rax
                inc byte [rbp - 8]
                jmp .inner
            .return:
                mov rax, qword [rbp -8]
                mov rsp, rbp
                pop rbp
                ret

    ; inline strings to keep the bin size small
    error_message: db "cat: Cant open the file: "
    error_message_len: equ $-error_message
    newline: db 0xa
