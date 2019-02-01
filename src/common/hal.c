#include <stddef.h>
#include <stdint.h>
#include "../../include/common/hal.h"
#include "../../include/kernel/uart.h"
#include "../../include/common/graphics.h"
#include "../../include/common/alpha.h"

static void uart_init(void);
static void uart_putc(uint8_t);
static uint8_t uart_getc();
static uint32_t memory_read(uint32_t);
static void memory_write(uint32_t, uint32_t);
static void delay(int32_t);

void hal_io_serial_init()
{
  uart_init();
}

void hal_io_serial_putc(uint8_t character)
{
  uart_putc(character);
}

void hal_io_serial_puts(uint8_t *str)
{
  uint8_t *c;
  for (c = str; *c != '\0'; c++) uart_putc(*c);
}

uint8_t hal_io_serial_getc()
{
  uart_getc();
}

void hal_io_video_init()
{
  graphics_init();
}

void hal_io_video_putpixel(uint32_t x, uint32_t y, uint32_t color)
{
  put_pixel(x, y, color);
}

void hal_io_video_putc(uint32_t x, uint32_t y, uint32_t color, uint8_t character)
{
  int i, j;
  for (i = 0; i < 10; i++) {
		for (j = 0; j < 20; j++) {
			if (alpha[character - 33][i][j] == 1) {
				put_pixel(j + x, i + y, color);
			}
		}
	}
}

void hal_io_video_puts(uint8_t *str, uint32_t row, uint32_t color) {
  uint8_t *c;
  int offset = 0;

  for (c = str; *c != '\0'; c++) {
    hal_io_video_putc(offset, row, color, *c);
    offset += CHAR_WIDTH;
  }
}

/*
*	From
*	https://wiki.osdev.org/Raspberry_Pi_Bare_Bones#Building_a_Cross-Compiler
*
*/
void uart_init(void)
{
	// Disable UART0.
	memory_write(UART0_CR, 0x00000000);
	// Setup the GPIO pin 14 && 15.

	// Disable pull up/down for all GPIO pins & delay for 150 cycles.
	memory_write(GPPUD, 0x00000000);
	delay(150);

	// Disable pull up/down for pin 14,15 & delay for 150 cycles.
	memory_write(GPPUDCLK0, (1 << 14) | (1 << 15));
	delay(150);

	// Write 0 to GPPUDCLK0 to make it take effect.
	memory_write(GPPUDCLK0, 0x00000000);

	// Clear pending interrupts.
	memory_write(UART0_ICR, 0x7FF);

	// Set integer & fractional part of baud rate.
	// Divider = UART_CLOCK/(16 * Baud)
	// Fraction part register = (Fractional part * 64) + 0.5
	// UART_CLOCK = 3000000; Baud = 115200.

	// Divider = 3000000 / (16 * 115200) = 1.627 = ~1.
	memory_write(UART0_IBRD, 1);
	// Fractional part register = (.627 * 64) + 0.5 = 40.6 = ~40.
	memory_write(UART0_FBRD, 40);

	// Enable FIFO & 8 bit data transmissio (1 stop bit, no parity).
	memory_write(UART0_LCRH, (1 << 4) | (1 << 5) | (1 << 6));

	// Mask all interrupts.
	memory_write(UART0_IMSC, (1 << 1) | (1 << 4) | (1 << 5) | (1 << 6) | (1 << 7) | (1 << 8) | (1 << 9) | (1 << 10));

	// Enable UART0, receive & transfer part of UART.
	memory_write(UART0_CR, (1 << 0) | (1 << 8) | (1 << 9));
}

void uart_putc(uint8_t c)
{
	//wait for it to be ready
	while ( memory_read(UART0_FR) & (1 << 5) );

	//write
	memory_write(UART0_DR, c);
}

uint8_t uart_getc(void)
{
    //wait for it to be ready
    while (memory_read(UART0_FR) & (1 << 4));

		//write
    return memory_read(UART0_DR);
}

void memory_write(uint32_t address, uint32_t v)
{
	*(volatile uint32_t*)address = v;
}

uint32_t memory_read(uint32_t address)
{
	return *(volatile uint32_t*)address;
}

/*
*	From
*	https://wiki.osdev.org/Raspberry_Pi_Bare_Bones#Building_a_Cross-Compiler
*
*/
void delay(int32_t count)
{
	asm volatile("__delay_%=: subs %[count], %[count], #1; bne __delay_%=\n"
		 : "=r"(count): [count]"0"(count) : "cc");
}
