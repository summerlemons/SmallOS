#ifndef __SYSTEM_H__
#define __SYSTEM_H__

#include "../console/stdarg.h"

int vsprintf(char* buf, const char* fmt, va_list arg);

int printk(const char* fmt, ...);

#endif