make:
	arm-none-eabi-as src/kernel/boot.S -o build/boot.o
	arm-none-eabi-as include/common/video_sample.s -o build/video_sample.o
		arm-none-eabi-gcc -mcpu=arm6 -fpic -ffreestanding -std=gnu99 -c src/kernel/uart.c -o build/uart.o -O0
	arm-none-eabi-gcc -mcpu=arm6 -fpic -ffreestanding -std=gnu99 -c src/kernel/kernel.c -o build/kernel.o -O0
	arm-none-eabi-ld build/boot.o build/video_sample.o build/uart.o build/kernel.o -T build/linker.ld -o build/kernel.elf
