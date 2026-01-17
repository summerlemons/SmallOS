#ifndef __TTY_H__
#define __TTY_H__

#include "../common/types.h"

void console_init(void);
void console_write(char* buf, u32 count);

#endif