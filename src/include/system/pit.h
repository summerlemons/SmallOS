#ifndef __PIT_H__
#define __PIT_H__ 

// PIT端口定义
#define PIT_CHANNEL0    0x40    // 通道0端口
#define PIT_CHANNEL1    0x41    // 通道1端口
#define PIT_CHANNEL2    0x42    // 通道2端口
#define PIT_COMMAND     0x43    // 命令寄存器端口

// PIT频率常量
#define PIT_BASE_FREQ   1193180 // PIT的基础频率（Hz）
// 我们要设置的 PIT 中断频率
#define HZ 100
// 分频器
#define PIT_FREQ (PIT_BASE_FREQ / HZ)

void pit_init();

#endif