#include "../../include/system/memory.h"

void print_memory_info() {
    u16 memory_info_size = *(u16*)MEMORY_INFO_START_ADDR;
    ards_t* memory_info = (ards_t*)(MEMORY_INFO_START_ADDR + sizeof(u16));
    for (int i = 0; i < memory_info_size; i++) {
        ards_t* ards = memory_info + i;
        printk("base_addr: 0x%08x%08x, length: 0x%08x%08x, type: 0x%x\n", 
            ards->base_addr_high, ards->base_addr_low,
            ards->length_high, ards->length_low, ards->type);
    }
}