; Stage Two

[bits 16]
[org 0x7C00]

two_start:
    cli

    xor ax, ax
    mov ds, ax
    mov es, ax

    mov ss, ax
    mov sp, 0x9000

    mov si, stage_two_msg
    call print_string
.halt:
    hlt
    jmp .halt

print_string:
  pusha
.nextchar:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp .nextchar
.done:
    popa
    ret

stage_two_msg db "stage2: load kernel...", 0
