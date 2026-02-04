#ifndef __STDARG_H
#define __STDARG_H
typedef char* va_list;

// 将类型 t 的大小向上对齐到 4 字节（int 的大小）
#define __va_rounded_size(t) (((sizeof(t) + sizeof(int) - 1) / sizeof(int)) * sizeof(int))

// 修改后的 va_start：跳过最后一个固定参数
#define va_start(p, last) (p = (va_list)&last + __va_rounded_size(last))

// 修改后的 va_arg：根据类型 t 的实际对齐大小移动指针
#define va_arg(p, t) (*(t *)((p += __va_rounded_size(t)) - __va_rounded_size(t)))

#define va_end(p) (p = 0)

#endif