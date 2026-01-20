[bits 32]
[SECTION .text]

extern printk
; 引入 keyboard.c 文件中的键盘处理函数
extern keymap_handler
; 引入 exception.c 文件中的异常处理函数: exception_handler
extern exception_handler
; 引入 clock.c 文件中的时钟处理函数: clock_handler
extern clock_handler

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

; 时钟中断
global clock_handler_entry
clock_handler_entry:
    push 0x20
    call clock_handler
    add esp, 4

    iret


; 无错误码的中断处理宏定义
%macro INTERRUPT_HANDLER 1
global interrupt_handler_%1
interrupt_handler_%1:
    push 0    ; 有错误码的中断会压入错误码，这里是没有错误码的中断处理函数，所以我们压入 0 表示占位
    pushad    ; 这个命令会把所有通用寄存器压入栈中，顺序是 EAX, ECX, EDX, EBX, ESP, EBP, ESI, EDI
    push %1   ; 压入中断号
    call exception_handler

    add esp, 4
    popad
    add esp, 4

    iret
%endmacro

; 有错误码的中断处理宏定义
%macro INTERRUPT_HANDLER_WITH_ERROR_CODE 1
global interrupt_handler_with_error_code_%1
interrupt_handler_with_error_code_%1:
    ; 这里 CPU 会将错误码压入栈中
    pushad
    push %1
    call exception_handler

    add esp, 4
    popad
    add esp, 4

    iret
%endmacro


; 中断处理函数定义
; --- 批量生成中断入口函数 ---
%assign i 0
%rep 48 ; 表示循环 48 次： i: 0 ~ 47 
    %if i == 8 || (i >= 10 && i <= 14) || i == 17 || i == 21 || i == 29 || i == 30
        INTERRUPT_HANDLER_WITH_ERROR_CODE i
    %else
        INTERRUPT_HANDLER i
    %endif
    %assign i i+1
%endrep

; --- 批量生成跳转表 ---
global interrupt_handler_table
interrupt_handler_table:
%assign i 0
%rep 48
    %if i == 8 || (i >= 10 && i <= 14) || i == 17 || i == 21 || i == 29 || i == 30
        dd interrupt_handler_with_error_code_%[i]
    %else
        dd interrupt_handler_%[i]
    %endif
    %assign i i+1
%endrep

msg:
    db "interrupt_handler...", 10, 0