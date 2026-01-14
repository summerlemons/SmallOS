[SECTION .text]
[bits 32] ; 表示下边的代码是 32 位汇编代码

extern kernel_main     ; 声明 kernel_main 是一个外部变量

global _start          ; 把自己的 _start 函数声明为全局变量，这样的话，别人就可以用 extern 引用它了
_start:
    call kernel_main   ; 调用从外部引入的 kernel_main 函数

    jmp $