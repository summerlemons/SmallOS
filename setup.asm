[ORG 0x500]

[BITS 16]
[SECTION .text]
global _start
_start:
    mov ax, 0x3
    int 0x10

    mov ax, 0
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov si, ax

    mov si, msg
    call print

    jmp $

print:
    mov ah, 0x0e
    mov bh, 0
    mov bl, 0x02
.loop:
    mov al, [si]
    cmp al, 0
    jz .done
    int 0x10

    inc si
    jmp .loop
.done:
    ret

msg:
    db "We have jumped into setup...", 10, 13, 0