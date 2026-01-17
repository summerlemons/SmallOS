[ORG 0x500]

[BITS 16]
[SECTION .text]
global _start
_start:
    mov ax, 0x3
    int 0x10

    mov ax, 0
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov si, ax

    mov si, msg
    call print

    ; 打印准备进入保护模式的信息
    mov si, prepare_to_protected_mode_msg
    call print

    ; 准备进入保护模式
    ; 1. 关闭中断
    cli

    ; 2. 加载 gdt 表
    lgdt [gdt_descriptor] ; 将 [gdt_descriptor] 内容放到 gdtr 中

    ; 3. 开启 A20 总线
    in al, 0x92         ; 读取系统控制端口B
    or al, 0b00000010   ; 设置 A20 总线
    out 0x92, al        ; 写回端口

    ; 4. 设置 CR0 寄存器的 PE 位
    mov eax, cr0
    or eax, 0x01   ; 设置CR0的bit 0（PE位）
    mov cr0, eax
    
    jmp 0x08:protected_mode

print:
    mov ah, 0x0e
    mov bh, 0
    mov bl, 0x02
.loop:
    mov al, [si]
    cmp al, 0
    jz .done
    int 0x10

    inc si
    jmp .loop
.done:
    ret

[BITS 32]
protected_mode:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov gs, ax

    ; 这里为什么是 0x9fbff? 因为我们之前看实模式内存分布图，只有两块地方是空白的可以让我们使用的
    ; 就是从 0x500 ~ 0x7bff 和 0x7e00 ~ 0x9fbff 这两块地方是我们可以用的
    ; 先前实模式我们把栈顶和栈底都设置在了 0x7c00 的位置，这里设置栈顶和栈底都为 0x9fbff
    mov esp, 0x9fbff
    mov ebp, esp

    ; 验证进入保护模式
    ; 验证进入成功：直接往屏幕左上角写一个红底白字的 'P'
    mov word [0xb8000], 0x4f50  ; 0x4f 是红底白字属性，0x50 是 'P' 的 ASCII

    ; 开始读取 system.bin 文件，放到内存的 0x1200 处
    ; 保存调用前环境
    push ecx
    push bx
    push edi

    mov ecx, 3  ; 从硬盘哪个扇区开始读。这里尤其要注意，CHS 方式读取扇区从 1 开始，但是 LBA 模式从 0 开始！！
    mov bl, 60  ; 读取的扇区数量
    mov edi, 0x1200    ; 表示数据读到哪个地址
    call read_data_from_disk

    ; 恢复调用前环境
    pop edi
    push bx
    push ecx

    ; 跳转到 setup
    jmp 0x08:0x1200


; 这里我们封装一个函数，用来从硬盘读取数据
;============================================================================
; 函数参数：
; ecx: 从哪个扇区开始读取
; bl: 读取的扇区数量
; edi: 存放读取的数据
; 调用样例：
; mov ecx, 1
; mov bl, 2
; mov edi, 0x500
; call read_data_from_disk
;============================================================================
read_data_from_disk:
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

    xor ecx, ecx               ; 表示清空 ecx
    and bx, 0xFF               ; bx 寄存器中只保留 bl 部分
    mov cx, bx                 ; 要读取几个扇区放到 cx 中

; 这里用来循环读取多个扇区
.selector_loop:
; 验证状态
; 3 0表示硬盘未准备好与主机交换数据 1表示准备好了
; 7 0表示硬盘不忙 1表示硬盘忙
; 0 0表示前一条指令正常执行 1表示执行出错 出错信息通过0x1f1端口获得
.read_check:
    mov dx, 0x1f7  ; 0x1f7 端口在写完 0x20 之后，就会返回硬盘状态，我们可以从这里读取硬盘状态
    in al, dx      ; 将 0x1f7 端口的数据读入 al

    ; 这里检查硬盘有无错误
    ; push ax        ; 保存 al
    ; and al, 0b00000001  ; 取硬盘状态的第0位：0 表示硬盘有错误
    ; cmp al, 0b00000001  ; 1 表示硬盘有错误
    ; jz .read_disk_error

    ; 这里检查硬盘是否繁忙
    ; pop ax
    and al, 0b10001000  ; 取硬盘状态的第3、7位：3 位表示有数据准备好，7 位表示硬盘忙
    cmp al, 0b00001000  ; 当硬盘第 3 位是 1, 第 7 位是 0 时，表示硬盘数据准备好了不忙
    jnz .read_check     ; 如果硬盘没有准备好，则跳转到 .read_check

    ; 开始读数据
    push cx           ; 保存 cx，因为 .selector_loop 会用到
    mov dx, 0x1f0     ; 硬盘的数据都是从这个端口读，一次读取 2 字节（16位）
    mov cx, 256       ; 表示读取几次

.read_data:
    in ax, dx         ; 把 dx 寄存器表示的端口的数据读入 ax
    mov [edi], ax     ; 把 ax 寄存器的数据写入 edi 指向的地址
    add edi, 2        ; 一次读取 2 字节，因此读完之后，目的往后移动 2 字节
    ; 循环读取数据, 这个 loop 和 jmp 一样，都是跳转，但是 loop 会受 cx 的影响
    ; loop 跳转之前会先判断 cx 是否为 0, 如果为 0 则跳转到 .read_data, 并且将 cx - 1
    loop .read_data

    ; 这里表示一个扇区读完，开始检查这个扇区读取状态
    ; mov dx, 0x1f7     ; 获取硬盘状态
    ; in al, dx         ; 硬盘状态读取到 al 寄存器  
    ; and al, 0b00000001
    ; cmp al, 0b00000001 ; 第 0 位为 1 表示有错误
    ; jz .read_disk_error  ; 读取有误，跳转到 .read_disk_error

    pop cx
    loop .selector_loop  ; 继续读取扇区

.done:
    ret


msg:
    db "We have jumped into setup...", 10, 13, 0

prepare_to_protected_mode_msg:
    db "Prepare to enter protected mode...", 10, 13, 0

B8000_SEG_BASE equ 0xb8000
B8000_SEG_LIMIT equ 0x7fff

CODE_SELECTOR equ (1 << 3)
DATA_SELECTOR equ (2 << 3)
B8000_SELECTOR equ (3 << 3)
; 构建 GDT 表
gdt_table_start:
    dd 0, 0 ; db 表示定义字节，dw 表示定义字(1 字 = 2 字节)，dd 表示定义双字(2 字 = 4 字节), dq 4 字 = 8 字节
code_descriptor:
    dw 0xFFFF  ; 段界限 15:0
    dw 0x0000  ; 段基址 15:0
    db 0x00    ; 段基址 23:16
    db 0b1_00_1_1000 ; 段属性
    db 0b1_1_0_0_1111 ; G_D/B_0_AVL 段界限 19:16
    db 0              ; 段基址 31:24
data_descriptor:
    dw 0xFFFF  ; 段界限 15:0
    dw 0x0000  ; 段基址 15:0
    db 0x00    ; 段基址 23:16
    db 0b1_00_1_0010 ; 段属性
    db 0b1_1_0_0_1111 ; G_D/B_0_AVL 段界限 19:16
    db 0              ; 段基址 31:24

b8000_descriptor:
    dw B8000_SEG_LIMIT && 0xFFFF
    dw B8000_SEG_BASE && 0xFFFF
    dw B8000_SEG_BASE >> 16 & 0xff
    ;   P_DPL_S_TYPE
    db 0b1_00_1_0010
    db 0b0_1_00_0000 | (B8000_SEG_LIMIT >> 16 & 0xf)
    db B8000_SEG_BASE >> 24 & 0xff
gdt_table_end:

gdt_descriptor:
    dw gdt_table_end - gdt_table_start - 1  ; 将来要放到 gdtr 0 ~ 15 位中的内容
    dd gdt_table_start                      ; 将来要放到 gdtr 16 ~ 47 位中的内容
