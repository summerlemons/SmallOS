TARGET = target
DISK_NAME = hd.img

all: ${TARGET}/boot.o ${TARGET}/setup.o
	rm -rf ${TARGET}/${DISK_NAME}
	bximage -q -hd=16 -func=create -sectsize=512 -imgmode=flat ${TARGET}/${DISK_NAME}
	dd if=${TARGET}/boot.o of=${TARGET}/${DISK_NAME} bs=512 count=1 seek=0 conv=notrunc
	dd if=${TARGET}/setup.o of=${TARGET}/${DISK_NAME} bs=512 count=2 seek=1 conv=notrunc

${TARGET}/%.o: %.asm
	mkdir -p ${TARGET}
	nasm $< -o $@

clean:
	rm -rf ${TARGET}

bochs:
	bochs -q -f bochsrc

qemu:
	qemu-system-x86_64 -hda ${TARGET}/${DISK_NAME}