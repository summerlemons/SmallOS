
#include "../../include/system/kernel.h"
#include "../../include/common/types.h"

/**
 * 通用中断处理程序的 message
 */
char *messages[] = {
    "#DE Divide Error",                         // 0x00
    "#DB Debug",                                // 0x01
    "--  NMI Interrupt",                        // 0x02
    "#BP Breakpoint",                           // 0x03
    "#OF Overflow",                             // 0x04
    "#BR BOUND Range Exceeded",                 // 0x05
    "#UD Invalid Opcode",                       // 0x06
    "#NM Device Not Available",                 // 0x07
    "#DF Double Fault",                         // 0x08
    "    Coprocessor Segment Overrun",          // 0x09 (仅限老式 CPU)
    "#TS Invalid TSS",                          // 0x0A
    "#NP Segment Not Present",                  // 0x0B
    "#SS Stack-Segment Fault",                  // 0x0C
    "#GP General Protection",                   // 0x0D
    "#PF Page Fault",                           // 0x0E
    "--  (Intel reserved. Do not use.)",        // 0x0F
    "#MF x87 FPU Floating-Point Error",         // 0x10
    "#AC Alignment Check",                      // 0x11
    "#MC Machine Check",                        // 0x12
    "#XM SIMD Floating-Point Exception",        // 0x13
    "#VE Virtualization Exception",             // 0x14
    "#CP Control Protection Exception",         // 0x15
    "--  (Intel reserved. Do not use.)",        // 0x16
    "--  (Intel reserved. Do not use.)",        // 0x17
    "--  (Intel reserved. Do not use.)",        // 0x18
    "--  (Intel reserved. Do not use.)",        // 0x19
    "--  (Intel reserved. Do not use.)",        // 0x1A
    "--  (Intel reserved. Do not use.)",        // 0x1B
    "#HV Hypervisor Injection Exception",       // 0x1C (最新虚拟化异常)
    "#VC VMM Communication Exception",          // 0x1D (AMD SEV 相关)
    "#SX Security Exception",                   // 0x1E (Intel TXT 相关)
    "--  (Intel reserved. Do not use.)",        // 0x1F
};

/**
 * 8259a 中断处理芯片的中断处理程序 message
 */
char* hw_interrupt_messages[] = {
    "IDT_0x20: Programmable Interval Timer",
    "IDT_0x21: Keyboard",
    "IDT_0x22: Cascade (PIC Slave)",
    "IDT_0x23: COM2 / COM4",
    "IDT_0x24: COM1 / COM3",
    "IDT_0x25: LPT2",
    "IDT_0x26: Floppy Disk",
    "IDT_0x27: LPT1 / Spurious",
    "IDT_0x28: CMOS Real Time Clock",
    "IDT_0x29: Free (IRQ 9)",
    "IDT_0x2A: Free (IRQ 10)",
    "IDT_0x2B: Free (IRQ 11)",
    "IDT_0x2C: PS2 Mouse",
    "IDT_0x2D: FPU / Coprocessor",
    "IDT_0x2E: Primary IDE",
    "IDT_0x2F: Secondary IDE",
};

typedef struct {
    u32 idt_index;                               // 触发异常的IDT索引
    u32 edi, esi, ebp, esp, ebx, edx, ecx, eax;  // pushad 对应的 8 个通用寄存器
    u32 error_code;                              // 异常代码
    u32 eip, cs, eflags;                         // CPU 调用中断自动压入的 3 个寄存器（前提是不跨段）
} registers_t;

void exception_handler(registers_t registers) {
    printk("\n==========\n");
    printk(" EXCEPTION : %s \n", registers.idt_index <= 0x1f ? messages[registers.idt_index] : hw_interrupt_messages[registers.idt_index - 0x20]);
    printk("    VECTOR : 0x%02X\n", registers.idt_index);
    printk("    EFLAGS : 0x%08X\n", registers.eflags);
    printk("        CS : 0x%02X\n", registers.cs);
    printk("       EIP : 0x%08X\n", registers.eip);
    printk("       ESP : 0x%08X\n", registers.esp);
    printk("Error Code : 0x%08X\n", registers.error_code);
    printk("==========\n");

    while (1);
}
