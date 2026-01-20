TARGET = target
DISK_NAME = hd.img

CFLAGS:= -m32 # 32 位的程序
CFLAGS+= -masm=intel    # 告诉 GCC 在生成的汇编代码中使用 Intel 语法
CFLAGS+= -fno-builtin	# 不需要 gcc 内置函数
CFLAGS+= -nostdinc		# 不需要标准头文件
CFLAGS+= -fno-pic		# 不需要位置无关的代码  position independent code
CFLAGS+= -fno-pie		# 不需要位置无关的可执行程序 position independent executable
CFLAGS+= -nostdlib		# 不需要标准库
CFLAGS+= -fno-stack-protector	# 不需要栈保护

# strip 函数会执行以下两个动作：
# 去除首尾空格：删除字符串开头和末尾的所有空格。
# 压缩中间空格：将字符串中间连续出现的多个空格（或制表符）合并为一个单一的空格。
CFLAGS:=$(strip ${CFLAGS}) 

DEBUG:= -g

all: ${TARGET}/bootloader/boot.o ${TARGET}/bootloader/setup.o ${TARGET}/system.bin
	rm -rf ${TARGET}/${DISK_NAME}
	bximage -q -hd=16 -func=create -sectsize=512 -imgmode=flat ${TARGET}/${DISK_NAME}
	dd if=${TARGET}/bootloader/boot.o of=${TARGET}/${DISK_NAME} bs=512 count=1 seek=0 conv=notrunc
	dd if=${TARGET}/bootloader/setup.o of=${TARGET}/${DISK_NAME} bs=512 count=2 seek=1 conv=notrunc
	dd if=${TARGET}/system.bin of=${TARGET}/${DISK_NAME} bs=512 count=60 seek=3 conv=notrunc

# 编译 bootloader/%.asm 中的引导程序
${TARGET}/bootloader/%.o: src/bootloader/%.asm
	mkdir -p ${TARGET}/bootloader/
	nasm $< -o $@

# 将 elf 格式的文件转换成纯机器码的文件
${TARGET}/system.bin: ${TARGET}/kernel.elf
	objcopy -O binary $< $@

# 链接 bootloader/head.o 和 kernel/main.o 到 kernel.elf
${TARGET}/kernel.elf: ${TARGET}/bootloader/head.o \
	${TARGET}/kernel/main.o \
	${TARGET}/kernel/util/io.o \
	${TARGET}/kernel/console/console.o \
	${TARGET}/kernel/string/string.o \
	${TARGET}/kernel/system/printk.o \
	${TARGET}/kernel/system/vsprintf.o \
	${TARGET}/kernel/system/gdt.o \
	${TARGET}/kernel/system/idt.o \
	${TARGET}/kernel/system/interrupt_handler.o \
	${TARGET}/kernel/system/keyboard.o \
	${TARGET}/kernel/system/exception.o \
	${TARGET}/kernel/system/pit.o
	ld -m elf_i386 $^ -o $@ -Ttext 0x1200

# 编译 bootloader/head.asm 用来将汇编与 C 语言进行链接
${TARGET}/bootloader/head.o: src/bootloader/head.asm
	mkdir -p ${TARGET}/bootloader/
	nasm -f elf32 $< -o $@

# 编译 kernel/util 文件夹里边的工具类
${TARGET}/kernel/util/%.o: src/kernel/util/%.asm
	mkdir -p ${TARGET}/kernel/util/
	nasm -f elf32 $< -o $@

# 编译 C 语言内核文件的主入口文件
${TARGET}/kernel/main.o: src/kernel/main.c
	mkdir -p ${TARGET}/kernel/
	gcc ${CFLAGS} ${DEBUG} -c $< -o $@


${TARGET}/kernel/console/%.o: src/kernel/console/%.c
	mkdir -p ${TARGET}/kernel/console/
	gcc ${CFLAGS} ${DEBUG} -c $< -o $@

${TARGET}/kernel/string/%.o: src/kernel/string/%.c
	mkdir -p ${TARGET}/kernel/string/
	gcc ${CFLAGS} ${DEBUG} -c $< -o $@

${TARGET}/kernel/system/%.o: src/kernel/system/%.c
	mkdir -p ${TARGET}/kernel/system/
	gcc ${CFLAGS} ${DEBUG} -c $< -o $@

${TARGET}/kernel/system/%.o: src/kernel/system/%.asm
	mkdir -p ${TARGET}/kernel/system/
	nasm -f elf32 $< -o $@

clean:
	rm -rf ${TARGET}

bochs: all
	bochs -q -f bochsrc

qemu: all
	qemu-system-x86_64 -hda ${TARGET}/${DISK_NAME}

qemug: all
	qemu-system-i386 -hda ${TARGET}/${DISK_NAME} -S -s