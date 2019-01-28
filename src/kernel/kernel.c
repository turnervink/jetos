/*
*
*	The Kernel
*/
#include <stddef.h>
#include <stdint.h>
#include "../../include/kernel/kernel.h"
#include "../../include/common/hal.h"
#include "../../include/common/add.h"

void _video_sample(uint32_t, uint32_t);

/*
* Kernel's entry point
*/
void main(uint32_t r0, uint32_t r1, uint32_t atags)
{
	_video_sample(128000, 0xFFFF00FF);

	hal_io_serial_init();
	hal_io_serial_puts("Hello, world. Welcome to jetOS!\r\n");

	while (1) hal_io_serial_putc(hal_io_serial_getc());
}
