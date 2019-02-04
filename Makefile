make:
	arm-none-eabi-as src/kernel/boot.S -o build/boot.o
	arm-none-eabi-as src/common/video.s -o build/video.o
	arm-none-eabi-as src/common/add.s -o build/add.o
	arm-none-eabi-gcc -mcpu=arm6 -fpic -ffreestanding -std=gnu99 -c src/common/hal.c -o build/hal.o -O0
	arm-none-eabi-gcc -mcpu=arm6 -fpic -ffreestanding -std=gnu99 -c src/kernel/kernel.c -o build/kernel.o -O0
		arm-none-eabi-gcc -mcpu=arm6 -fpic -ffreestanding -std=gnu99 -c src/common/graphics.c -o build/graphics.o -O0
	arm-none-eabi-ld build/boot.o build/add.o build/hal.o build/kernel.o build/video.o build/graphics.o -T build/linker.ld -o build/kernel.elf
