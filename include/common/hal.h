#include <stddef.h>
#include <stdint.h>

void hal_io_serial_init();
void hal_io_serial_putc(uint8_t character);
void hal_io_serial_puts(uint8_t *str);
uint8_t hal_io_serial_getc();
void hal_io_video_init();
void hal_io_video_putpixel(uint32_t x, uint32_t y, uint32_t color);
void hal_io_video_putc(uint32_t x, uint32_t y, uint32_t color, uint8_t character);
void hal_io_video_puts(uint32_t y, uint32_t color, uint8_t *str);
