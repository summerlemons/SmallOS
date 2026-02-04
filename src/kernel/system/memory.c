#include "../../include/system/memory.h"
#include "../../include/system/kernel.h"
#include "../../include/string/string.h"

int memory_info_size; // 内存信息次数
ards_t* memory_info; // 内存信息

page_frame_manager_t page_frame_manager;

/* ========== 静态函数声明 ========== */
static u32 get_bit_map_idx_by_addr(u32 addr);
static int set_bit_map_by_idx(u32 idx, u32 value);
static inline u32 align_up(u32 value);
static inline u32 align_down(u32 value);
static void bitmap_init(void);

/**
 * 根据地址获取位图索引
 * @param addr 地址
 * @return 位图索引
 */
static u32 get_bit_map_idx_by_addr(u32 addr) {
    return addr / PAGE_SIZE;
}

/**
 * 根据索引设置位图
 * @param idx 位图索引
 * @param value 值
 * @return 0 成功，-1 失败
 */
static int set_bit_map_by_idx(u32 idx, u32 value) {
    if (value != PAGE_USED && value != PAGE_FREE) {
        printk("Invalid value for set_bit_map_by_idx!");
        return -1;
    }
    u32 byte_idx = idx / BITS_PER_BYTE;
    u32 bit_idx = idx % BITS_PER_BYTE;
    if (value == PAGE_USED) {
        page_frame_manager.bitmap[byte_idx] |= (1 << bit_idx);
    } else {
        page_frame_manager.bitmap[byte_idx] &= ~(1 << bit_idx);
    }
    return 0;
}

/**
 * 内存页对齐的计算方法，假如我们 8 字节对齐，但是你的地址是 10, 那么理他最近的就是 8 和 16
 * 如果是向下对齐寻找 8, 计算方法就是 10 = 0b01010; 需要把低三位置为 0，就是 0b1010 & 0b11111000 = 0b1000 = 8
 * 如果是向上对齐寻找 16, 计算方法就是 10 + (8-1) = 0b10001; 需要把低三位置为 0，就是 0b10001 | 0b11111000 = 0b10000 = 16
 */
/**
 * 内存页向上对齐
 */
static inline u32 align_up(u32 value) {
    return (value + PAGE_SIZE - 1) & ~(PAGE_SIZE - 1);
}

/**
 * 内存页向下对齐
 */
static inline u32 align_down(u32 value) {
    return value & ~(PAGE_SIZE - 1);
}

/**
 * 初始化内存信息
 */
void memory_init() { 
    memory_info_size = *(u16*)MEMORY_INFO_START_ADDR;
    memory_info = (ards_t*)(MEMORY_INFO_START_ADDR + sizeof(u16));
}

/**
 * 打印内存信息
 */
void print_memory_info() {
    for (int i = 0; i < memory_info_size; i++) {
        ards_t* ards = memory_info + i;
        printk("base_addr: 0x%08x%08x, length: 0x%08x%08x, type: 0x%x\n", 
            ards->base_addr_high, ards->base_addr_low,
            ards->length_high, ards->length_low, ards->type);
    }
}

/**
 * 初始化内存管理器
 */
void memory_manager_init() {
    // 初始化位图信息
    bitmap_init();

    // 根据E820空闲条目，标记空闲页
    for (int i = 0; i < memory_info_size; i++) {
        ards_t* ards = memory_info + i;
        if (ards->type == 1 && ards->base_addr_low >= VALID_MEMORY_FROM) {
            u32 base_addr = ards->base_addr_low;
            u32 length = ards->length_low;
            u32 end_addr = base_addr + length;
            u32 page_start_address =align_up(base_addr); // 向上取整
            u32 page_end_address = align_down(end_addr); // 向下取整

            for (u32 page_address = page_start_address; page_address < page_end_address; page_address += PAGE_SIZE) {
                int idx = get_bit_map_idx_by_addr(page_address);
                set_bit_map_by_idx(idx, PAGE_FREE);
                page_frame_manager.free_pages++;
                page_frame_manager.used_pages--;
            }
        }
    }

    // 将位图的 Page 页都写为 1
    u32 bitmap_start_page = (u32)page_frame_manager.bitmap / PAGE_SIZE;
    u32 bitmap_end_page = bitmap_start_page + page_frame_manager.bitmap_pages;
    for (u32 page_idx = bitmap_start_page; page_idx < bitmap_end_page; page_idx++) {
        set_bit_map_by_idx(page_idx, PAGE_USED);
        page_frame_manager.used_pages++;
        page_frame_manager.free_pages--;
    }
}

/**
 * 打印内存管理信息
 */
void print_memory_manager_info() {
    printk(
        "max_memory: 0x%x, available_mem: 0x%x(%f G),\nused_pages: %d, free_pages: %d,\ntotal_pages: %d, bitmap_size: %d,\nbitmap_pages: %d\n",
        page_frame_manager.max_memory, page_frame_manager.available_mem, page_frame_manager.available_mem / 1024.0 / 1024.0 / 1024.0,
        page_frame_manager.used_pages, page_frame_manager.free_pages,
        page_frame_manager.total_pages, page_frame_manager.bitmap_size, 
        page_frame_manager.bitmap_pages
    );
}

/**
 * 初始化位图
 */
static void bitmap_init() {
    // 初始化最大内存地址 和 可用内存大小
    page_frame_manager.max_memory = 0;
    page_frame_manager.available_mem = 0;
    page_frame_manager.used_pages = 0;
    page_frame_manager.free_pages = 0;
    // 循环遍历最大内存地址 和 可用内存
    for (int i = 0; i < memory_info_size; i++) {
        ards_t* ards = memory_info + i;
        // 计算最大内存地址
        u32 max_m = ards->base_addr_low + ards->length_low - 1; // 这里之所以 -1 是因为假设地址从 0 开始，长度为 10, 其实最大地址是 0 + 10 - 1 = 9
        if (max_m > page_frame_manager.max_memory) {
            page_frame_manager.max_memory = max_m;
        }
        // 统计可用内存
        if (ards->type == 1 && ards->base_addr_low >= VALID_MEMORY_FROM) { // 忽略小于 1M 的内存
            printk("%u\n", ards->length_low);
            page_frame_manager.available_mem += ards->length_low; // 32 位操作系统下，只使用低 32 位即可
        }
    }
    // 计算管理内存需要的总页数
    page_frame_manager.total_pages = (u32)(((u64)page_frame_manager.max_memory + PAGE_SIZE - 1) / PAGE_SIZE); // 向上取整, 这里类型转换是因为防止出现 u32 溢出问题
    // 计算管理这么多页，需要多少空间存储位图
    page_frame_manager.bitmap_size = (page_frame_manager.total_pages + BITS_PER_BYTE - 1) / BITS_PER_BYTE;
    // 计算位图需要的总页数
    page_frame_manager.bitmap_pages = (u32)(page_frame_manager.bitmap_size + PAGE_SIZE - 1)  / PAGE_SIZE;

    // 为位图分配内存（从空闲区域中找一块）
    // 我们假设从第一个大于1MB的空闲区域中分配，并且这个区域足够大。
    for (int i = 0; i < memory_info_size; i++) {
        ards_t* ards = memory_info + i;
        if (ards->type == 1 && ards->base_addr_low >= VALID_MEMORY_FROM) { // 1M 以上可用空间
            // 获取可用内存区域
            u32 aligned_start = align_up(ards->base_addr_low);
            u32 aligned_end = align_down(ards->base_addr_low + ards->length_low);
            if (aligned_end - aligned_start >= page_frame_manager.bitmap_size) {
                // 找到合适的空闲区域, 为方便管理，这里从 Page 对齐的地方开始使用
                page_frame_manager.bitmap = (u8*)align_up(ards->base_addr_low);
                break;
            }
        }
    }

    if (page_frame_manager.bitmap == 0) {
        printk("No suitable memory for bitmap!");
        while (1);
    }

    // 初始化位图
    memset(page_frame_manager.bitmap, 0xFF, page_frame_manager.bitmap_size); // 全部置为 1, 表示全部不可用
    page_frame_manager.used_pages = page_frame_manager.total_pages; // 这里先将所有页设置为已使用
}