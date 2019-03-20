#include <stddef.h>
#include <stdbool.h>
#include <stdint.h>
#include <string.h>

#include "shell.h"
#include "../hal/hal.h"
#include "../drivers/stdio/emb-stdio.h"
#include "../drivers/sdcard/SDCard.h"

uint8_t currentDir[1024] = "\\";

void shell_init() {
	shell_input();
}

static void shell_input() {
	uint8_t input[1024];
	uint8_t c;
	int i = 0;
	
	hal_io_video_puts("\n\r$ ", 2, VIDEO_COLOR_GREEN);
	hal_io_serial_puts(SerialA, "\n\r$ ");
	
	while (1) {
		c = hal_io_serial_getc(SerialA);
		
		if (c == 13) break;
		
		printf_serial("%c", c);
		printf_video("%c", c);
		input[i] = c;
		i++;
	}
	
	input[i+1] = '\0';
	
	printf_serial("\r\n");
	printf_video("\r\n");
	
	if (strcmp(input, "sysinfo") == 0) {
		sysinfo();
	} else if (strcmp(input, "ls") == 0) {
		ls();
	}		
	else {
		printf_serial("\r\nUnknown command\r\n");
		printf_video("\r\nUnknown command\r\n");
		
		shell_input();
	}
}

static void sysinfo() {
	printf_serial("jetOS Version 2\r\n");
	printf_video("jetOS Version 2\r\n");
	
	shell_input();
}

static void ls() {
	HANDLE fh;
	FIND_DATA find;
	uint8_t dir[1024];
	
	strcat(currentDir, dir);
	strcat(dir, "*");
	
	fh = sdFindFirstFile(dir, &find);	

	do {
		if (find.dwFileAttributes == FILE_ATTRIBUTE_DIRECTORY)
			printf_video("%s <DIR>\r\n", find.cFileName);
		else printf_video("%s\r\n", find.cFileName);										// Display each entry
	} while (sdFindNextFile(fh, &find) != 0);	

	sdFindClose(fh);

	shell_input();
}