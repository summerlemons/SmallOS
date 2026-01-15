[SECTION .text]
[bits 32] ; 表示下边的代码是 32 位汇编代码

extern kernel_main     ; 声明 kernel_main 是一个外部变量

global _start          ; 把自己的 _start 函数声明为全局变量，这样的话，别人就可以用 extern 引用它了
_start:
    call kernel_main   ; 调用从外部引入的 kernel_main 函数

    ; 测试 CGA 屏幕
    mov dx, 0x3D4    ; 表示索引，去控制哪两个字节; 0xB8000 开始（0位置），每 2 字节表示一个字符
    mov al, 0x0C
    out dx, al       ; 表示要设置内存起始位置(0xB8000 位置开始， 是 0 位置) - 高位
    mov dx, 0x3D5    ; 表示数据寄存器，前边 0x3D4 索引了哪里的地址，这里 0x3D5 就要把数据写入哪里
    mov al, 0x0
    out dx, al       ; 这里才真正设置屏幕起始位置

    mov dx, 0x3D4
    mov al, 0x0D
    out dx, al       ; 表示要设置内存起始位置 - 低位
    mov dx, 0x3D5
    mov al, 0x01
    out dx, al

    mov dx, 0x3D4
    mov al, 0x0E
    out dx, al       ; 设置光标的位置 - 高位
    mov dx, 0x3D5
    mov al, 0x01
    out dx, al       ; 这里我们把光标设置到第 5 行，第 0 列：80 * 5 = 400 = 0x190：高位 0x01 低位 0x90

    mov dx, 0x3D4
    mov al, 0x0F
    out dx, al
    mov dx, 0x3D5
    mov al, 0x90
    out dx, al


    jmp $