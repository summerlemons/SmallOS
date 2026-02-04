#ifndef __MEMORY_H__
#define __MEMORY_H__

#include "../common/types.h"

/**
 * 内存信息起始地址
 */
#define MEMORY_INFO_START_ADDR 0x1000

// 把1M以下内存称为无效内存
#define VALID_MEMORY_FROM 0x100000
#define PAGE_SIZE 4096 // 页大小
#define BITS_PER_BYTE 8  // 每字节的位数
#define PAGE_FREE 0  // 页空闲
#define PAGE_USED 1  // 页已用

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
 * 页帧管理结构体
 */
typedef struct {
    u32 total_pages;      // 总页数
    u32 free_pages;       // 空闲页数
    u32 used_pages;       // 已用页数
    u8* bitmap;           // 位图指针
    u32 bitmap_size;      // 位图大小
    u32 bitmap_pages;     // 位图占用的页数
    u32 start_phys_addr;  // 可用内存起始
    u32 end_phys_addr;    // 可用内存结束
    u32 max_memory;       // 最大内存地址
    u32 available_mem;    // 可用内存
}page_frame_manager_t;

/**
 * 打印内存信息
 */
void print_memory_info();
/**
 * 初始化内存信息
 */
void memory_init();
/**
 * 初始化内存管理
 */
void memory_manager_init();
/**
 * 打印内存管理信息
 */
void print_memory_manager_info();

#endif