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

    jmp $



msg:
    db "We have jumped into setup...", 10, 13, 0

prepare_to_protected_mode_msg:
    db "Prepare to enter protected mode...", 10, 13, 0

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
gdt_table_end:

gdt_descriptor:
    dw gdt_table_end - gdt_table_start - 1  ; 将来要放到 gdtr 0 ~ 15 位中的内容
    dd gdt_table_start                      ; 将来要放到 gdtr 16 ~ 47 位中的内容

; 将来 cs 寄存器中要设置的内容
code_selector:
    dw 0b0000_0000_0000_1000
; 将来 ds 寄存器中要设置的内容
data_selector:
    dw 0b0000_0000_0001_0000