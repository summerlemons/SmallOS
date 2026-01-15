[SECTION .text]
[bits 32] ; 表示下边的代码是 32 位汇编代码

extern kernel_main     ; 声明 kernel_main 是一个外部变量

global _start          ; 把自己的 _start 函数声明为全局变量，这样的话，别人就可以用 extern 引用它了
_start:
    call kernel_main   ; 调用从外部引入的 kernel_main 函数

    ; 测试 CGA 屏幕
    ;mov dx, 0x3D4    ; 表示索引，去控制哪两个字节; 0xB8000 开始（0位置），每 2 字节表示一个字符
    ;mov al, 0x0C
    ;out dx, al       ; 表示要设置内存起始位置(0xB8000 位置开始， 是 0 位置) - 高位
    push 0x0C         ; 传参，第二个参数
    push 0x3D4        ; 传参，第一个参数
    call out_byte     ; 调用函数
    add esp, 8        ; 恢复栈

    ;mov dx, 0x3D5    ; 表示数据寄存器，前边 0x3D4 索引了哪里的地址，这里 0x3D5 就要把数据写入哪里
    ;mov al, 0x0
    ;out dx, al       ; 这里才真正设置屏幕起始位置
    push 0x00
    push 0x3D5
    call out_byte
    add esp, 8

    ;mov dx, 0x3D4
    ;mov al, 0x0D
    ;out dx, al       ; 表示要设置内存起始位置 - 低位
    push 0x0D
    push 0x3D4
    call out_byte
    add esp, 8
    ;mov dx, 0x3D5
    ;mov al, 0x01
    ;out dx, al
    push 0x01
    push 0x3D5
    call out_byte
    add esp, 8

    ;mov dx, 0x3D4
    ;mov al, 0x0E
    ;out dx, al       ; 设置光标的位置 - 高位
    push 0x0E
    push 0x3D4
    call out_byte
    add esp, 8
    ;mov dx, 0x3D5
    ;mov al, 0x01
    ;out dx, al       ; 这里我们把光标设置到第 5 行，第 0 列：80 * 5 = 400 = 0x190：高位 0x01 低位 0x90
    push 0x01
    push 0x3D5
    call out_byte
    add esp, 8

    ;mov dx, 0x3D4
    ;mov al, 0x0F
    ;out dx, al
    push 0x0F
    push 0x3D4
    call out_byte
    add esp, 8
    ;mov dx, 0x3D5
    ;mov al, 0x90
    ;out dx, al
    push 0x90
    push 0x3D5
    call out_byte
    add esp, 8


    jmp $

;============================================================================
; 从某个 16 位端口读取一个字节
; 参数1: 端口号
; 返回： 读取到的字节
;============================================================================
in_byte:
    push ebp
    mov ebp, esp
    mov edx, [esp + 8] ; 32 位下，栈每次取 4 字节，要用 edx 取参数

    xor eax, eax ; 清空 eax 寄存器
    in al, dx
    
    mov esp, ebp
    pop ebp

    ret

;============================================================================
; 向某个 16 位端口写入一个字节
; 参数1: 端口号
; 参数2: 要写入的字节
;============================================================================
out_byte:
    push ebp
    mov ebp, esp

    mov edx, [esp + 8]    ; 端口号
    mov eax, [esp + 12]   ; 要写入的字节，取 al
    out dx, al

    mov esp, ebp
    pop ebp

    ret

;============================================================================
; 从某个 16 位端口读取一个字
; 参数1: 端口号
; 返回： 读取到的字
;============================================================================
in_word:
    push ebp
    mov ebp, esp

    mov edx, [esp + 8]

    xor eax, eax
    in ax, dx

    mov esp, ebp
    pop ebp

    ret

;============================================================================
; 向某个 16 位端口写入一个字
; 参数1: 端口号
; 参数2: 要写入的字
;=============================================================================
out_word:
    push ebp
    mov ebp, esp

    mov edx, [esp + 8]
    mov eax, [esp + 12]
    out dx, ax
    
    mov esp, ebp
    pop ebp

    ret