#include "../../include/system/pit.h"
#include "../../include/system/idt.h"
#include "../../include/system/kernel.h"
#include "../../include/util/io.h"

void pit_init() {
    // 发送命令字到命令寄存器
    // 0x36 = 通道0 + 读写低高字节 + 模式3（方波）+ 二进制计数
    out_byte(PIT_COMMAND, 0x36);
    
    // 发送分频值的低字节
    out_byte(PIT_CHANNEL0, PIT_FREQ & 0xFF);
    
    // 发送分频值的高字节
    out_byte(PIT_CHANNEL0, (PIT_FREQ >> 8) & 0xFF);
}

void clock_handler(int idt_index) {
    send_eoi(idt_index);
    // printk("0x%x\n", idt_index);
}