#include <stddef.h>
#include <stdint.h>
#include "kernel.h"

void hal_io_serial_init()
{
  uart_init(void);
}

void hal_io_serial_putc(type serial_id, uint8_t character)
{
  uart_putc(character);
}

void hal_io_serial_getc(t serial_id)
{
  uart_getc();
}

void hal_io_video_init()
{

}
void hal_io_video_putpixel(uint32_t x, uint32_t y, color)
{

}
void hal_io_video_putc(uint32_t x, uint32_t y, color, uint8_t character)
{

}
