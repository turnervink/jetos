#include <stddef.h>
#include <stdint.h>
#include "kernel.h"

void hal_io_serial_init();
void hal_io_serial_putc(type serial_id, uint8_t character);
void hal_io_serial_getc(type serial_id);
void hal_io_video_init();
void hal_io_video_putpixel(uint32_t x, uint32_t y, type color);
void hal_io_video_putc(uint32_t x, uint32_t y, type color, type character);
