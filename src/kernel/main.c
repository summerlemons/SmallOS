#include "../include/util/io.h"

// 编写内核主函数
void kernel_main(void) {
    char* video = (char*)0xb8000; // 显存地址，把 0xb8000 地址的变量赋给 video
    *video = 'G';                 // 修改显存的第一个字符为 G
    *(video + 1) = 0x3c;          // 颜色为 0x3e 蓝底红字

    out_byte(0x3d4, 0x0C);        // 表示设置显示开始位置 - 高位
    out_byte(0x3d5, 0x00);        // 表示显示开始位置高位为 0

    out_byte(0x3d4, 0x0D);        // 表示设置显示开始位置 - 低位
    out_byte(0x3d5, 0x01);        // 表示显示开始位置低位为 1

    out_byte(0x3d4, 0x0E);        // 表示设置光标位置 - 高位
    out_byte(0x3d5, 0x01);
    
    out_byte(0x3d4, 0x0F);        // 标识设置光标位置 - 低位
    out_byte(0x3d5, 0x90);        // 组合起来就是设置光标在 0x190 位置，也就是第五行第一列
}