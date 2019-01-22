/*
*
*	The Kernel
*/
#include <stddef.h>
#include <stdint.h>
#include "../../include/kernel/kernel.h"
#include "../../include/kernel/uart.h"

void _video_sample(void);

/*
* Kernel's entry point
*/
void main(uint32_t r0, uint32_t r1, uint32_t atags)
{
	_video_sample();

	//Begin the one-line typewriter
	uart_init();

	uart_putc( 'T' );
	uart_putc( 'y' );
	uart_putc( 'p' );
	uart_putc( 'e' );
	uart_putc( 'w' );
	uart_putc( 'r' );
	uart_putc( 'i' );
	uart_putc( 't' );
	uart_putc( 'e' );
	uart_putc( 'r' );
	uart_putc( ':' );
	uart_putc( '\n' );
	uart_putc( '\r' );

	while (1)
		uart_putc(uart_getc());  // <<---- This is why your CPU goes crazy when you run the kernel
}
