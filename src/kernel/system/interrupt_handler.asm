[bits 32]
[SECTION .text]

extern printk

global interrupt_handler
interrupt_handler:
    push msg
    call printk
    add esp, 4

    ; 发送EOI
    mov al, 0x20
    out 0x20, al      ; 主片EOI
    iret

msg:
    db "interrupt_handler...", 10, 0