rm -rf ./target
mkdir target
nasm boot.asm -o target/boot.o
nasm setup.asm -o target/setup.o
bximage -q -hd=16 -func=create -sectsize=512 -imgmode=flat target/hd.img
dd if=target/boot.o of=target/hd.img bs=512 count=1 seek=0 conv=notrunc
dd if=target/setup.o of=target/hd.img bs=512 count=2 seek=1 conv=notrunc
bochs -q -f bochsrc