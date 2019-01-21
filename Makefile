make:
	arm-none-eabi-as boot.S -o out/boot.o
	arm-none-eabi-as video_sample.s -o out/video_sample.o
	arm-none-eabi-gcc -mcpu=arm6 -fpic -ffreestanding -std=gnu99 -c kernel.c -o out/kernel.o -O0
	arm-none-eabi-ld out/boot.o out/video_sample.o out/kernel.o -T linker.ld -o out/kernel.elf
