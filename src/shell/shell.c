#include <stddef.h>
#include <stdbool.h>
#include <stdint.h>

#include "shell.h"
#include "../hal/hal.h"

void shell_init() {
	shell_input();
}

static void shell_input() {
	hal_io_video_puts("\n\r$ ", 2, VIDEO_COLOR_GREEN);
	hal_io_serial_puts(SerialA, "\n\r$ ");
	
	uint8_t input[1024];
	while (1) {
		c = hal_io_serial_getc(SerialA);
		
		if (c == 13) break;
		
		printf_serial("%c", c);
		printf_video("%c", c);
	}
}