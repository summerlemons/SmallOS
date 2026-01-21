#include "../include/system/kernel.h"
#include "../include/system/gdt.h"
#include "../include/system/idt.h"
#include "../include/system/memory.h"

// 编写内核主函数
void kernel_main(void) {
    console_init(); // 初始化控制台
    gdt_init();     // 初始化 GDT 表
    idt_init();     // 初始化 IDT 表
    print_memory_info(); // 打印内存信息

    // 打开中断开关
    asm volatile("sti");

    char* s = "Small";
    printk("Welcome to %sOS!\n", s);
}