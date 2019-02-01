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
	hal_io_serial_puts("Hello, world. Welcome to jetOS!\r\n");

	hal_io_video_init();

	int i, j;

	// Fill the screen
	// for (i = 0; i < DISPLAY_HEIGHT; i++) {
	// 	for (j = 0; i < DISPLAY_WIDTH; j++) {
	// 		hal_io_video_putpixel(j, i, 0x111111);
	// 	}
	// }

	// Draw n A
	// for (i = 0; i < 30; i++)
	// 	hal_io_video_putpixel(i, 0, 0xFFFFFFFF);
	//
	// for (i = 0; i < 30; i++)
	// 	hal_io_video_putpixel(0, i, 0xFFFFFFFF);
	//
	// for (i = 0; i < 30; i++)
	// 	hal_io_video_putpixel(30, i, 0xFFFFFFFF);
	//
	// for (i = 0; i < 30; i++)
	// 	hal_io_video_putpixel(i, 15, 0xFFFFFFFF);

	hal_io_video_putc(0, 0, 0xFFFFFFFF, 'J');
	hal_io_video_putc(CHAR_WIDTH, 0, 0xFFFFFFFF, 'E');
	hal_io_video_putc(CHAR_WIDTH * 2, 0, 0xFFFFFFFF, 'T');
	hal_io_video_putc(CHAR_WIDTH * 3, 0, 0xFFFFFFFF, 'O');
	hal_io_video_putc(CHAR_WIDTH * 4, 0, 0xFFFFFFFF, 'S');

	while (1) hal_io_serial_putc(hal_io_serial_getc());
}
