#include "../include/system/kernel.h"
#include "../include/system/gdt.h"
#include "../include/system/idt.h"

// 编写内核主函数
void kernel_main(void) {
    console_init(); // 初始化控制台
    gdt_init();     // 初始化 GDT 表
    idt_init();     // 初始化 IDT 表

    char* s = "Small";
    printk("Welcome to %sOS!\n", s);

    // 打开中断开关
    asm volatile("sti");
}