; Stage One

%assign STAGE_TWO_SECTORS 32 ; TODO: sectors to read for stage two
%assign STAGE_TWO_LBA 1 ; stage two located at LBA 1

[bits 16] ; 16 bit "real" mode
[org 0x7C00] ; set addresses relative to 0x7C00

one_start:
  cli ; [Cl]ear [I]nterrupts
  xor ax, ax ; AX = 0
  mov ds, ax ; [D]ata [S]egment = 0
  mov es, ax ; [E]xtra [S]egment = 0
  ; subsequent BIOS calls may overwrite DL
  mov [boot_drive], dl ; [D]rive [L]etter

  mov ss, ax ; [S]tack [S]egment
  mov sp, 0x7B00 ; [S]tack [P]ointer, below our boot sector

  mov si, stage_one_msg ; [S]ource [I]ndex
  call print_string

  ; TODO: move reading into stage two (with FAT support)
  mov si, dap ; [D]isk [A]ddress [P]acket
  mov dl, [boot_drive]
  ; INT 13h, AH=42h (extended read)
  mov ah, 0x42
  int 0x13

  jc .disk_error ; if CF ([C]arry [F]lag) is set

  jmp 0x0000:0x8000 ; jump to stage two
.disk_error:
    mov si, err_msg
    call print_string
.halt:
    hlt
    jmp .halt

; strings must end with 0
print_string:
  pusha
.nextchar:
    ; equivalent to:
    ;   mov al, [si]
    ;   inc si
    lodsb ; [L]oa[D] [S]tring [B]yte
    ; equivalent to: cmp al, 0
    test al, al ; check if current byte is 0
    jz .done ; if 0, done
    mov ah, 0x0E ; BIOS teletype character output
    int 0x10 ; prints character at cursor (AL)
    jmp .nextchar
.done:
    popa
    ret

; [D]ata [B]ytes, trailing zero for zero byte terminator
stage_one_msg db "stage1: load stage2...", 0
err_msg db "stage1: disk read failed", 0

; Disk Address Packet
; 0: size (0x10)
; 1: reserved (0)
; 2-3: number of sectors to transfer (word)
; 4-5: buffer offset (word)
; 6-7: buffer segment (word)
; 8-15: starting LBA (qword, little-endian)
dap:
  db 0x10, 0x00 ; size = 16, reserved = 0
  dw STAGE_TWO_SECTORS ; number of sectors to read
  ; physical address = segment * 16 + offset
  dw 0x8000 ; offset
  dw 0x0000 ; segment
  ; stage two will be loaded from 0x8000
  dq STAGE_TWO_LBA

boot_drive db 0 ; reserve space to store boot_drive

times 510-($-$$) db 0 ; fill to 510 bytes
dw 0xAA55 ; write signature in remaining 2 bytes
