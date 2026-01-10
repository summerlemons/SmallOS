[ORG 0x7c00]         ; 这段程序将来要加到内存的0x7c00的位置

[SECTION .data]
BOOT_MAIN_ADDR equ 0x500 ; 这里相当于在程序的代码段定义了一个宏：`#define BOOT_MAIN_ADDR 0x500`

[SECTION .text]      ; 定义代码段
[BITS 16]            ; 定义16位
global _start
_start:
	mov ax, 3        ; 这里也是中断的一种，AH=00表示设置显示模式，详情见下方介绍
    int 0x10

    mov ax, 0        ; 寄存器清0
    mov ss, ax
	mov ds, ax
	mov es, ax
	mov si, ax

    mov si, msg
    call print


    mov ch, 0  ; 柱面：0
    mov dh, 0  ; 磁头：0
    mov cl, 2  ; 扇区：2
    mov bx, BOOT_MAIN_ADDR  ; 加载到 ES:BX = 0x0000:0x500

    mov ah, 0x02 ; 功能：读扇区
    mov al, 2    ; 扇区数：2   表示我要读几个扇区， 1 个扇区 = 512 字节
    mov dl, 0x80   ; 驱动器：0x80=第一个硬盘；0x81=第二个硬盘， 如果是软盘，则驱动器为0x00，0x01编号
    int 0x13

    ; 这里 int 0x13 读取磁盘出错, 就会修改 FLAGS 寄存器的 CF 位 =1，则 jc 跳转命令生效 
    ;jc .read_disk_error

    ; 这里读取硬盘成功，打印跳转到 setup 的信息
    mov si, jmp_to_setup
    call print
    ; 跳转到 setup
    jmp BOOT_MAIN_ADDR


; 如果读取磁盘出错，则打印错误信息
.read_disk_error:
    mov si, read_disk_error
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

jmp_to_setup:
    db "jump to setup...", 10, 13, 0

read_disk_error:
    db "read disk error!", 10, 13, 0
    
times 510 - ($ - $$) db 0  ; 前510字节剩下的都为0
db 0x55, 0xaa        ; 操作系统识别字符，固定值