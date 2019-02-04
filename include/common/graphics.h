#include <stddef.h>
#include <stdint.h>
#include "./video.h"

#define DISPLAY_WIDTH 1278
#define DISPLAY_HEIGHT 480

void graphics_init(void);
void put_pixel(uint32_t x, uint32_t y, uint32_t color);
