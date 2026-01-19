[SECTION .text]
[bits 32] ; 表示下边的代码是 32 位汇编代码

extern kernel_main     ; 声明 kernel_main 是一个外部变量

global _start          ; 把自己的 _start 函数声明为全局变量，这样的话，别人就可以用 extern 引用它了
_start:
; 配置 8259a 芯片，响应中断
.config_8259a_chip:
    ; 像主芯片发送 ICW1
    mov al, 0x11
    out 0x20, al

    ; 向从芯片发送 ICW1
    mov al, 0x11
    out 0xa0, al

    ; 向主芯片发送 ICW2
    mov al, 0x20
    out 0x21, al

    ; 向从芯片发送 ICW2
    mov al, 0x28
    out 0xa1, al

    ; 向主芯片发送 ICW3
    mov al, 0x04
    out 0x21, al

    ; 向从芯片发送 ICW3
    mov al, 0x02
    out 0xa1, al

    ; 向主芯片发送 ICW4
    mov al, 0x03
    out 0x21, al

    ; 向从芯片发送 ICW4
    out 0xa1, al

; 屏蔽主芯片所有中断，只接收键盘中断
.enable_8259a_main:
    mov al, 0b11111100
    out 0x21, al

; 屏蔽从芯片所有中断
.enable_8259a_slave:
    mov al, 0b11111111
    out 0xa1, al

; 调用c程序
.enter_c_word:
    call kernel_main   ; 调用从外部引入的 kernel_main 函数

    jmp $