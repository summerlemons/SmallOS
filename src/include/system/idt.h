#ifndef _IDT_H_
#define _IDT_H_

#define PIC_M_CTRL  0x20    // 主片的控制端口
#define PIC_M_DATA  0x21    // 主片的数据端口
#define PIC_S_CTRL  0xa0    // 从片的控制端口
#define PIC_S_DATA  0xa1    // 从片的数据端口
#define PIC_EOI     0x20    // 通知中断控制器中断结束

typedef struct interrupt_gate_t {
    short offset0;    // 段内偏移 0 ~ 15 位
    short selector;   // 代码段选择子
    char reserved;    // 保留不用
    char type : 4;    // 任务门/中断门/陷阱门
    char segment : 1; // segment = 0 表示系统段
    char DPL : 2;     // 使用 int 指令访问的最低权限
    char present : 1; // 是否有效
    short offset1;    // 段内偏移 16 ~ 31 位
} __attribute__((packed)) interrupt_gate_t;

typedef struct idt_ptr_t {
    short limit;
    int base;
} __attribute__((packed)) idt_ptr_t;

void idt_init();

void send_eoi(int idt_index);
#endif