#include "../include/system/kernel.h"
#include "../include/system/gdt.h"

// 编写内核主函数
void kernel_main(void) {
    console_init(); // 初始化控制台
    gdt_init();     // 初始化 GDT 表

    char* s = "Small";

    for (int i = 0; i < 10; i++) {
        printk("The os name: %sOS!, times: %d!\n", s, i);
    }
}