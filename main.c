// 编写内核主函数
void kernel_main(void) {
    char* video = (char*)0xb8000; // 显存地址，把 0xb8000 地址的变量赋给 video
    *video = 'G';                 // 修改显存的第一个字符为 G
    *(video + 1) = 0x3c;          // 颜色为 0x3e 蓝底红字

    while(1);
}