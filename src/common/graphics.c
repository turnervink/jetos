#include "../../include/common/graphics.h"

void graphics_init(void) {
  _video_init();
}

void put_pixel(uint32_t x, uint32_t y, uint32_t color) {
  _draw_pixel(x + (1280 * y), color);
}
