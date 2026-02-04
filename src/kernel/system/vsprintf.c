/**
 *  该文件的代码摘自linux内核，会用就行，不用深究
 */
#include "../../include/system/system.h"
#include "../../include/system/kernel.h"
#include "../../include/string/string.h"
#include "../../include/console/stdarg.h"

/* we use this so that we can do without the ctype library */
#define is_digit(c)	((c) >= '0' && (c) <= '9')

static int skip_atoi(const char **s)
{
    int i=0;

    while (is_digit(**s))
        i = i*10 + *((*s)++) - '0';
    return i;
}

#define ZEROPAD	1		/* pad with zero */
#define SIGN	2		/* unsigned/signed long */
#define PLUS	4		/* show plus */
#define SPACE	8		/* space if plus */
#define LEFT	16		/* left justified */
#define SPECIAL	32		/* 0x */
#define SMALL	64		/* use 'abcdef' instead of 'ABCDEF' */

#define do_div(n,base) ({ \
int __res; \
__asm__("div %4":"=a" (n),"=d" (__res):"0" (n),"1" (0),"r" (base)); \
__res; })

static char * number(char * str, int num, int base, int size, int precision
        ,int type)
{
    char c,sign,tmp[36];
    const char *digits="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    int i;

    if (type&SMALL) digits="0123456789abcdefghijklmnopqrstuvwxyz";
    if (type&LEFT) type &= ~ZEROPAD;
    if (base<2 || base>36)
        return 0;
    c = (type & ZEROPAD) ? '0' : ' ' ;
    if (type&SIGN && num<0) {
        sign='-';
        num = -num;
    } else
        sign=(type&PLUS) ? '+' : ((type&SPACE) ? ' ' : 0);
    if (sign) size--;
    if (type&SPECIAL) {
        if (base==16) size -= 2;
        else if (base==8) size--;
    }
    i=0;
    if (num==0)
        tmp[i++]='0';
    else while (num!=0)
            tmp[i++]=digits[do_div(num,base)];
    if (i>precision) precision=i;
    size -= precision;
    if (!(type&(ZEROPAD+LEFT)))
        while(size-->0)
            *str++ = ' ';
    if (sign)
        *str++ = sign;
    if (type&SPECIAL) {
        if (base==8)
            *str++ = '0';
        else if (base==16) {
            *str++ = '0';
            *str++ = digits[33];
        }
    }
    if (!(type&LEFT))
        while(size-->0)
            *str++ = c;
    while(i<precision--)
        *str++ = '0';
    while(i-->0)
        *str++ = tmp[i];
    while(size-->0)
        *str++ = ' ';
    return str;
}

int vsprintf(char *buf, const char *fmt, va_list args) {
    int len;
    int i;
    char * str;
    char *s;
    int *ip;

    int flags;		/* flags to number() */

    int field_width;	/* width of output field */
    int precision;		/* min. # of digits for integers; max
				   number of chars for from string */
    int qualifier;		/* 'h', 'l', or 'L' for integer fields */

    for (str=buf ; *fmt ; ++fmt) {
        if (*fmt != '%') {
            *str++ = *fmt;
            continue;
        }

        /* process flags */
        flags = 0;
        repeat:
        ++fmt;		/* this also skips first '%' */
        switch (*fmt) {
            case '-': flags |= LEFT; goto repeat;
            case '+': flags |= PLUS; goto repeat;
            case ' ': flags |= SPACE; goto repeat;
            case '#': flags |= SPECIAL; goto repeat;
            case '0': flags |= ZEROPAD; goto repeat;
        }

        /* get field width */
        field_width = -1;
        if (is_digit(*fmt))
            field_width = skip_atoi(&fmt);
        else if (*fmt == '*') {
            /* it's the next argument */
            field_width = va_arg(args, int);
            if (field_width < 0) {
                field_width = -field_width;
                flags |= LEFT;
            }
        }

        /* get the precision */
        precision = -1;
        if (*fmt == '.') {
            ++fmt;
            if (is_digit(*fmt))
                precision = skip_atoi(&fmt);
            else if (*fmt == '*') {
                /* it's the next argument */
                precision = va_arg(args, int);
            }
            if (precision < 0)
                precision = 0;
        }

        /* get the conversion qualifier */
        qualifier = -1;
        if (*fmt == 'h' || *fmt == 'l' || *fmt == 'L') {
            qualifier = *fmt;
            ++fmt;
        }

        switch (*fmt) {
            case 'c':
                if (!(flags & LEFT))
                    while (--field_width > 0)
                        *str++ = ' ';
                *str++ = (unsigned char) va_arg(args, int);
                while (--field_width > 0)
                    *str++ = ' ';
                break;

            case 's':
                s = va_arg(args, char *);
                len = strlen(s);
                if (precision < 0)
                    precision = len;
                else if (len > precision)
                    len = precision;

                if (!(flags & LEFT))
                    while (len < field_width--)
                        *str++ = ' ';
                for (i = 0; i < len; ++i)
                    *str++ = *s++;
                while (len < field_width--)
                    *str++ = ' ';
                break;

            case 'o':
                str = number(str, va_arg(args, unsigned long), 8,
                            field_width, precision, flags);
                break;

            case 'p':
                if (field_width == -1) {
                    field_width = 8;
                    flags |= ZEROPAD;
                }
                str = number(str,
                             (unsigned long) va_arg(args, void *), 16,
                            field_width, precision, flags);
                break;

            case 'x':
                flags |= SMALL;
            case 'X':
                str = number(str, va_arg(args, unsigned long), 16,
                            field_width, precision, flags);
                break;

            case 'd':
            case 'i':
                flags |= SIGN;
            case 'u':
                str = number(str, va_arg(args, unsigned long), 10,
                            field_width, precision, flags);
                break;

            case 'n':
                ip = va_arg(args, int *);
                *ip = (str - buf);
                break;

            case 'f': {
                double num = va_arg(args, double);
                
                // 1. 处理负数
                if (num < 0) {
                    *str++ = '-';
                    num = -num;
                }

                // 2. 提取整数部分和小数部分
                int i_part = (int)num;
                double f_part = num - (double)i_part;

                // 3. 确定精度 (默认为 6 位)
                if (precision < 0) precision = 6;

                // 4. 先打印整数部分
                // 调用你代码里的 number(str, num, base, size, precision, type)
                str = number(str, i_part, 10, field_width, 0, flags);

                // 5. 打印小数点
                *str++ = '.';

                // 6. 计算小数部分的数值
                // 例如 0.123 变成 123
                for (int i = 0; i < precision; i++) {
                    f_part *= 10;
                }
                int f_int = (int)(f_part + 0.5); // +0.5 是为了四舍五入

                // 7. 打印小数部分
                // 注意：这里必须强制补零（ZEROPAD），且宽度等于精度
                // 比如 0.001 必须打印成 "001" 而不是 "1"
                str = number(str, f_int, 10, precision, precision, ZEROPAD);
                break;
            }
            default:
                if (*fmt != '%')
                    *str++ = '%';
                if (*fmt)
                    *str++ = *fmt;
                else
                    --fmt;
                break;
        }
    }
    *str = '\0';
    return str-buf;
}