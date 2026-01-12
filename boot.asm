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


    mov ecx, 1 ; 从硬盘哪个扇区开始读。这里尤其要注意，CHS 方式读取扇区从 1 开始，但是 LBA 模式从 0 开始！！
    mov bl, 1  ; 读取的扇区数量
    
    ; 0x1f2 8bit 指定读取或写入的扇区数
    mov dx, 0x1f2
    mov al, bl
    out dx, al

    ; 0x1f3 8bit iba地址的低八位 0-7
    inc dx
    mov al, cl
    out dx, al

    ; 0x1f4 8bitiba地址的中八位 8-15
    inc dx
    mov al, ch
    out dx, al

    ; 0x1f5 8bitiba地址的高八位 16-23
    inc dx
    shr ecx, 16
    mov al, cl
    out dx, al

    ; 0x1f6 8bit
    ; 0-3 位iba地址的24-27
    ; 4 0表示主盘 1表示从盘
    ; 5、7位固定为1
    ; 6 0表示CHS模式，1表示LAB模式
    inc dx
    mov al, ch  ; 0-3 位iba地址的24-27
    and al, 0b0000_1111  ; 这里把 4-7 的位清零，防止有数据影响
    or al, 0b1110_0000   ; 这里设置 5,6,7 位为1, 5,7 固定就是1, 6 设置 1 表示 LBA 读取
    out dx, al

    ; 0x1f7 8bit  命令或状态端口
    inc dx
    mov al, 0x20
    out dx, al

; 验证状态
; 3 0表示硬盘未准备好与主机交换数据 1表示准备好了
; 7 0表示硬盘不忙 1表示硬盘忙
; 0 0表示前一条指令正常执行 1表示执行出错 出错信息通过0x1f1端口获得
.read_check:
    mov dx, 0x1f7  ; 0x1f7 端口在写完 0x20 之后，就会返回硬盘状态，我们可以从这里读取硬盘状态
    in al, dx      ; 将 0x1f7 端口的数据读入 al
    and al, 0b10001000  ; 取硬盘状态的第3、7位
    cmp al, 0b00001000  ; 当硬盘第 3 位是 1, 第 7 位是 0 时，表示硬盘数据准备好了不忙
    jnz .read_check     ; 如果硬盘没有准备好，则跳转到 .read_check

    ; 开始读数据
    mov dx, 0x1f0     ; 硬盘的数据都是从这个端口读，一次读取 2 字节（16位）
    mov cx, 256       ; 表示读取几次
    mov edi, BOOT_MAIN_ADDR   ; 表示数据读到哪个地址

.read_data:
    in ax, dx         ; 把 dx 寄存器表示的端口的数据读入 ax
    mov [edi], ax     ; 把 ax 寄存器的数据写入 edi 指向的地址
    add edi, 2        ; 一次读取 2 字节，因此读完之后，目的往后移动 2 字节
    ; 循环读取数据, 这个 loop 和 jmp 一样，都是跳转，但是 loop 会受 cx 的影响
    ; loop 跳转之前会先判断 cx 是否为 0, 如果为 0 则跳转到 .read_data, 并且将 cx - 1
    loop .read_data

    mov dx, 0x1f7
    in al, dx
    and al, 0b00000001
    cmp al, 0b00000001 ; 第 0 位为 1 表示有错误
    jz .read_disk_error  ; 读取有误，跳转到 .read_disk_error


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