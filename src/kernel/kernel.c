/*
*
*	The Kernel
*/
#include <stddef.h>
#include <stdint.h>
#include "../../include/kernel/kernel.h"
#include "../../include/common/hal.h"
#include "../../include/common/add.h"
#include "../../include/common/graphics.h"

/*
* Kernel's entry point
*/
void main(uint32_t r0, uint32_t r1, uint32_t atags)
{
	hal_io_serial_init();
	hal_io_serial_puts("Hello, world. Welcome to jetOS!\r\n");

	hal_io_video_init();

	// Draw some lines
	int i;
	for (i = 0; i < DISPLAY_WIDTH; i++)
		hal_io_video_putpixel(i, 15, 0xFFFFFFFF);

	for (i = 0; i < DISPLAY_HEIGHT; i++)
		hal_io_video_putpixel(20, i, 0xFFFFFFFF);

	while (1) hal_io_serial_putc(hal_io_serial_getc());
}
