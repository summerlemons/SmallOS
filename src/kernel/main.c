#include "../include/util/io.h"

#define SCREEN_START 0xB8000      // 显存起始地址
#define SCREEN_END 0xBFFFF        // 显存结束地址
#define SCREEN_BUFFER_SIZE (SCREEN_END - SCREEN_START + 1)  // 显存缓存大小
#define SCREEN_WIDTH 80           // 屏幕宽度
#define SCREEN_HEIGHT 25          // 屏幕高度
#define SCREEN_SIZE (SCREEN_WIDTH * SCREEN_HEIGHT)   // 屏幕显示大小

/**
 * 获取光标位置
 */
unsigned short get_cursor_position() {
    out_byte(0x3d4, 0x0E);
    unsigned char cursor_position_high = in_byte(0x3d5);        // 获取光标高位

    out_byte(0x3d4, 0x0F);
    unsigned char cursor_position_low = in_byte(0x3d5);         // 获取光标低位
    // 光标位置
    return (cursor_position_high << 8) | cursor_position_low;   // 拼接
}

/**
 * 设置光标位置
 */
void set_cursor_position(unsigned short position) {
    out_byte(0x3d4, 0x0E);
    out_byte(0x3d5, (char)(position >> 8));
    out_byte(0x3d4, 0x0F);
    out_byte(0x3d5, (char)(position));
}

/**
 * 输出字符串
 */
void puts(char* str) {
    // 光标位置
    unsigned short cursor_position = get_cursor_position();
    // 遍历字符串
    char* p = str;
    while (*p != '\0') {
        if (*p == '\n') {
            cursor_position = cursor_position + 80 - (cursor_position % 80); // 换行
        } else {
            // 光标位置打印字符
            *(short*)(0xB8000 + cursor_position * 2) = *p | 0x0700; // 这里 0x0700 表示背景
            cursor_position++;
        }
        
        // 字符串移动
        p++;
    }
    set_cursor_position(cursor_position);
}

/**
 * 输出字符
 */
void putc(char c) {
    // 获取光标位置
    unsigned short cursor_position = get_cursor_position();
    // 获取光标位置的字符
    char* p = (char*)(0xB8000 + cursor_position * 2);
    if (c == '\n') {
        cursor_position = cursor_position + 80 - (cursor_position % 80); // 换行
    } else {
        // 赋值
        *p = c;
        // 颜色
        *(p + 1) = 0x07;
    }
    
    // 设置光标位置
    set_cursor_position(cursor_position + 1);
}

/**
 * 输出数字
 */
void putd(int num) {
    if (num == 0) {
        putc('0');
        return;
    }
    if (num < 0) {
        putc('-');
        num = -num;
    }

    // 缓存
    char buf[16];
    int idx = 0;
    int floor;
    // 打印数字每一位
    while ((floor = num % 10) != 0) {
        buf[idx++] = floor + '0';
        num = num / 10;
    }
    while (idx > 0) {
        putc(buf[--idx]);
    }
}

/**
 * 格式化输出
 */
void printf(char* format, ...) {
    char* p = format;
    int arg_index = 1;
    while (*p != '\0') {
        if (*p == '\n') {
            putc('\n');
        }
        if (*p == '%') {
            p++;
            switch (*p) {
                // 处理数字
                case 'd':
                    putd(*(int*)(&format + arg_index)); // 取出第 arg_index 个参数
                    arg_index++;
                    break;
                // 处理字符串
                case 's':
                    puts((char*)*(&format + arg_index));
                    arg_index++;
                    break;
                // 处理字符
                case 'c':
                    putc(*(char*)(&format + arg_index));
                    arg_index++;
                    break;
                // 若都不是，退一格，打印字符
                default:
                    p--;
                    putc(*p);
                    break;
            }
        } else {
            putc(*p);
        }
        p++;
    }
}

// 编写内核主函数
void kernel_main(void) {
    char* video = (char*)0xb8000; // 显存地址，把 0xb8000 地址的变量赋给 video
    *video = 'G';                 // 修改显存的第一个字符为 G
    *(video + 1) = 0x3c;          // 颜色为 0x3e 蓝底红字

    out_byte(0x3d4, 0x0C);        // 表示设置显示开始位置 - 高位
    out_byte(0x3d5, 0x00);        // 表示显示开始位置高位为 0

    out_byte(0x3d4, 0x0D);        // 表示设置显示开始位置 - 低位
    out_byte(0x3d5, 0x00);        // 表示显示开始位置低位为 1

    out_byte(0x3d4, 0x0E);        // 表示设置光标位置 - 高位
    out_byte(0x3d5, 0x01);
    
    out_byte(0x3d4, 0x0F);        // 标识设置光标位置 - 低位
    out_byte(0x3d5, 0x90);        // 组合起来就是设置光标在 0x190 位置，也就是第五行第一列

    char* str = "We have finished the function of puts\n";
    puts(str);

    printf("Hi I am %s, I am %d years old and my gender is %c\n", "Jim", 18, 'M');
}