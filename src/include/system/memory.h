#ifndef __MEMORY_H__
#define __MEMORY_H__

#include "../common/types.h"

/**
 * 内存信息起始地址
 */
#define MEMORY_INFO_START_ADDR 0x1000

/**
 * 内存描述结构体
 */
typedef struct {
    u32 base_addr_low;   // 起始物理地址的低 32 位
    u32 base_addr_high;  // 起始物理地址的高 32 位
    u32 length_low;      // 内存段长度的低 32 位
    u32 length_high;     // 内存段长度的高 32 位
    u32 type;            // 该内存段的类型
} __attribute__((packed)) ards_t;

/**
 * 打印内存信息
 */
void print_memory_info();

#endif