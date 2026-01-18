[bits 32]
[SECTION .text]

extern printk
; 引入 keyboard.c 文件中的键盘处理函数
extern keymap_handler

global interrupt_handler
interrupt_handler:
    push msg
    call printk
    add esp, 4

    ; 发送EOI
    mov al, 0x20
    out 0x20, al      ; 主片EOI
    iret

; 键盘中断
global keymap_handler_entry
keymap_handler_entry:
    push 0x21 ; 传入中断号
    call keymap_handler
    add esp, 4

    iret

msg:
    db "interrupt_handler...", 10, 0