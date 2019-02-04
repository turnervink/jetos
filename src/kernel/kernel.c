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
#include "../../include/common/alpha.h"

/*
* Kernel's entry point
*/
void main(uint32_t r0, uint32_t r1, uint32_t atags)
{
	hal_io_serial_init();
	hal_io_serial_puts("Welcome to jetOS!\r\n");

	hal_io_video_init();

	// Draw a sentence on the screen
	hal_io_video_puts(0, 0xFFFFFFFF, "WELCOME TO JETOS!");

	// Draw a character on the screen
	hal_io_video_putc(50, 50, 0xFFFFFFFF, 'X');

	// Draw a line of pixels on the screen
	int i;
	for (i = 0; i < 50; i++) {
		hal_io_video_putpixel(i, 75, 0xFFFFFFFF);
	}

	while (1) hal_io_serial_putc(hal_io_serial_getc());
}
