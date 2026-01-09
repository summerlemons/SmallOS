[ORG 0x7c00]         ; 这段程序将来要加到内存的0x7c00的位置

[SECTION .text]      ; 定义代码段
[BITS 16]            ; 定义16位
global _start
_start:
	mov ax, 3        ; 这里也是中断的一种，AH=00表示设置显示模式，详情贱下方介绍
    int 0x10

    mov ax, 0        ; 寄存器清0
    mov ss, ax
	mov ds, ax
	mov es, ax
	mov si, ax

    mov si, msg
    call print

    jmp $

print:               ; 实现print打印函数
	mov ah, 0x0e     ; 设置中断为AH=0EH/INT 0x10
    mov bh, 0        ; 设置页码
    mov bl, 0x01     ; 设置颜色
.loop:
	mov al, [si]     ; 设置要打印的字符
	cmp al, 0        ; 对比是否结束
    jz .done
	int 0x10

    inc si           ; 字符串循环
	jmp .loop
.done:
	ret

msg:                 ; 定义的字符串
	db "hello SmallOS...", 10, 13, 0
    
times 510 - ($ - $$) db 0  ; 前510字节剩下的都为0
db 0x55, 0xaa        ; 操作系统识别字符，固定值