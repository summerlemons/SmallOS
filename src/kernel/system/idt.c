#include "../../include/system/idt.h"
#include "../../include/system/kernel.h"

#define INTERRUPT_TABLE_SIZE 256

// 中断描述符表
interrupt_gate_t interrupt_table[INTERRUPT_TABLE_SIZE] = {0};
// idtr 寄存器值
idt_ptr_t idt_ptr = {0};
// 从外部引入的中断处理函数，目前我们把所有的中断处理函数都用这一个函数处理
extern void interrupt_handler();

void idt_init() {
    printk("idt_init...\n");
    for (int i = 0; i < INTERRUPT_TABLE_SIZE; ++i) {
        interrupt_gate_t* p = &interrupt_table[i];

        int handler = interrupt_handler;

        p->offset0 = handler & 0xffff;
        p->offset1 = (handler >> 16) & 0xffff;
        p->selector = 1 << 3; // 代码段
        p->reserved = 0;      // 保留不用
        p->type = 0b1110;     // 中断门
        p->segment = 0;       // 系统段
        p->DPL = 0;           // 内核态
        p->present = 1;       // 有效
    }

    // 将中断描述符表地址写入 idtr 寄存器
    idt_ptr.limit = INTERRUPT_TABLE_SIZE * 8;
    idt_ptr.base = &interrupt_table;

    // 加载中断描述符表到 idtr 寄存器
    asm volatile("lidt idt_ptr");
    printk("idt_init done. the address of ths idt table is: 0x%x\n", idt_ptr.base);
}