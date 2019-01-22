/*
*
*	The Kernel
*/
#include <stddef.h>
#include <stdint.h>
#include "../../include/kernel/kernel.h"
#include "../../include/common/hal.h"

void _video_sample(void);

/*
* Kernel's entry point
*/
void main(uint32_t r0, uint32_t r1, uint32_t atags)
{
	_video_sample();

	hal_io_serial_init();
	hal_io_serial_putc('H'); hal_io_serial_putc('E'); hal_io_serial_putc('L'); hal_io_serial_putc('L'); hal_io_serial_putc('O');
	hal_io_serial_putc(' ');
	hal_io_serial_putc('W'); hal_io_serial_putc('O'); hal_io_serial_putc('R'); hal_io_serial_putc('L'); hal_io_serial_putc('D'); hal_io_serial_putc('!');
	hal_io_serial_putc('\r');hal_io_serial_putc('\n');

	while (1) hal_io_serial_putc(hal_io_serial_getc());
}
