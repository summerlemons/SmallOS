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

all: ${TARGET}/boot.o ${TARGET}/setup.o ${TARGET}/system.bin
	rm -rf ${TARGET}/${DISK_NAME}
	bximage -q -hd=16 -func=create -sectsize=512 -imgmode=flat ${TARGET}/${DISK_NAME}
	dd if=${TARGET}/boot.o of=${TARGET}/${DISK_NAME} bs=512 count=1 seek=0 conv=notrunc
	dd if=${TARGET}/setup.o of=${TARGET}/${DISK_NAME} bs=512 count=2 seek=1 conv=notrunc
	dd if=${TARGET}/system.bin of=${TARGET}/${DISK_NAME} bs=512 count=60 seek=3 conv=notrunc

${TARGET}/%.o: %.asm
	mkdir -p ${TARGET}
	nasm $< -o $@

${TARGET}/system.bin: ${TARGET}/kernel.elf
	objcopy -O binary $< $@

${TARGET}/kernel.elf: ${TARGET}/head.o ${TARGET}/main.o
	ld -m elf_i386 $^ -o $@ -Ttext 0x1200

${TARGET}/head.o: head.asm
	mkdir -p ${TARGET}
	nasm -f elf32 $< -o $@

${TARGET}/main.o: main.c
	mkdir -p ${TARGET}
	gcc ${CFLAGS} ${DEBUG} -c $< -o $@

clean:
	rm -rf ${TARGET}

bochs: all
	bochs -q -f bochsrc

qemu: all
	qemu-system-x86_64 -hda ${TARGET}/${DISK_NAME}

qemug: all
	qemu-system-i386 -hda ${TARGET}/${DISK_NAME} -S -s