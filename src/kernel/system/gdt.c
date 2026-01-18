#include "../../include/common/types.h"
#include "../../include/system/gdt.h"
#include "../../include/system/kernel.h"
#include "../../include/string/string.h"
#define GDT_SIZE 256 // gdt表中最大多少个描述符

u64 gdt[GDT_SIZE]; // 256 个描述符存的地方

gdt_ptr_t gdt_ptr; // 存 gdtr 寄存器的值

int r3_code_selector;
int r3_data_selector;

static void r3_gdt_code_item(int gdt_index, int base, int limit) {
    // 在实模式时已经构建了4个全局描述符(0, code, data, b8000)，所以从4开始
    if (gdt_index < 4) {
        printk("the gdt_index:%d has been used...\n", gdt_index);
        return;
    }

    if (gdt_index >= GDT_SIZE) {
        printk("the gdt_index:%d is out of range...\n", gdt_index);
    }

    gdt_item_t* gdt_item = (gdt_item_t*)&gdt[gdt_index];
    gdt_item->limit_low = limit & 0xFFFF;
    gdt_item->base_low = base & 0xFFFF;
    gdt_item->type = 0b1000;
    gdt_item->segment = 1;
    gdt_item->DPL = 0b11;  // r3 就全都是3级权限
    gdt_item->present = 1;
    gdt_item->limit_high = (limit >> 16) & 0xF;
    gdt_item->available = 0;
    gdt_item->long_mode = 0;  // 非 64 位模式，所以是 0
    gdt_item->big = 1;
    gdt_item->granularity = 1;
    gdt_item->base_high = (base >> 24) & 0xFF;
}

static void r3_gdt_data_item(int gdt_index, int base, int limit) {
    if (gdt_index < 4) {
        printk("the gdt_index:%d has been used...\n", gdt_index);
        return;
    }

    if (gdt_index >= GDT_SIZE) {
        printk("the gdt_index:%d is out of range...\n", gdt_index);
    }

    gdt_item_t* gdt_item = (gdt_item_t*)&gdt[gdt_index];
    gdt_item->limit_low = limit & 0xFFFF;
    gdt_item->base_low = base & 0xFFFF;
    gdt_item->type = 0b0010;
    gdt_item->segment = 1;
    gdt_item->DPL = 0b11;  // r3 就全都是3级权限
    gdt_item->present = 1;
    gdt_item->limit_high = (limit >> 16) & 0xF;
    gdt_item->available = 0;
    gdt_item->long_mode = 0;  // 非 64 位模式，所以是 0
    gdt_item->big = 1;
    gdt_item->granularity = 1;
    gdt_item->base_high = (base >> 24) & 0xFF;
}

void gdt_init() { 
    printk("gdt_init...\n");
    __asm__ volatile ("sgdt gdt_ptr"); // 获取 gdtr 寄存器的值，写入到 gdt_ptr 中
    memcpy(&gdt, gdt_ptr.base, gdt_ptr.limit + 1); // 将 gdt 表中的内容复制到 gdt 中

    // 创建r3用的段描述符：代码段、数据段
    r3_gdt_code_item(4, 0, 0xfffff);
    r3_gdt_data_item(5, 0, 0xfffff);

    // 创建r3用的选择子：代码段、数据段
    r3_code_selector = 4 << 3 | 0b11;
    r3_data_selector = 5 << 3 | 0b11;

    gdt_ptr.base = &gdt;
    gdt_ptr.limit = sizeof(gdt) - 1;

    __asm__ volatile ("lgdt gdt_ptr"); // 设置 gdtr 寄存器的值
    printk("gdt_init done. the address of ths gdt table is: 0x%x\n", gdt_ptr.base);
}