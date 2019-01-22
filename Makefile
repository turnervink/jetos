make:
	arm-none-eabi-as src/kernel/boot.S -o build/boot.o
	arm-none-eabi-as include/common/video_sample.s -o build/video_sample.o
		arm-none-eabi-gcc -mcpu=arm6 -fpic -ffreestanding -std=gnu99 -c src/common/hal.c -o build/hal.o -O0
	arm-none-eabi-gcc -mcpu=arm6 -fpic -ffreestanding -std=gnu99 -c src/kernel/kernel.c -o build/kernel.o -O0
	arm-none-eabi-ld build/boot.o build/video_sample.o build/hal.o build/kernel.o -T build/linker.ld -o build/kernel.elf
