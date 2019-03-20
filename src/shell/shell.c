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
	uint8_t * args[1024];
	uint8_t * token;
	uint8_t c;
	uint8_t seps[] = " ";
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
	
	printf_serial("Got command: %s", input);
	printf_serial("\r\n");
	printf_video("\r\n");
	
	// Split up entered command into single word arguments
	i = 0;
	token = strtok(input, seps);
    while(token != NULL) {
		args[i] = token;
        token = strtok(NULL, seps);
		i++;
    }
	
	if (strcmp(args[0], "sysinfo") == 0) {
		sysinfo();
	} else if (strcmp(args[0], "ls") == 0) {
		ls();
	} else if (strcmp(args[0], "cd") == 0) {
		cd(args[1]);
	} else if (strcmp(args[0], "cat") == 0) {
		cat(args[1]);
	} else if (strcmp(args[0], "bindump") == 0) {
		bindump(args[1]);
	} else if (strcmp(args[0], "testprogram") == 0) {
		testprogram();
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
	
	strcpy(dir, currentDir);
	strcat(dir, "*.*");
	printf_serial("Listing dir: %s", dir);
	
	fh = sdFindFirstFile(dir, &find);	

	do {
		if (find.dwFileAttributes == FILE_ATTRIBUTE_DIRECTORY)
			printf_video("%s <DIR>\r\n", find.cFileName);
		else printf_video("%s\r\n", find.cFileName);										// Display each entry
	} while (sdFindNextFile(fh, &find) != 0);	

	sdFindClose(fh);

	shell_input();
}

static void cd(uint8_t * dir) {
	strcat(currentDir, dir);
	strcat(currentDir, "\\");
	
	printf_serial("New currentDir: %s", currentDir);
	
	shell_input();
}

static void cat(uint8_t * file) {
	char buffer[500];
	HANDLE fHandle = sdCreateFile(file, GENERIC_READ, 0, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
	
	if (fHandle != 0) {
		uint32_t bytesRead;

		if ((sdReadFile(fHandle, &buffer[0], 500, &bytesRead, 0) == true))  {
			buffer[bytesRead-1] = '\0';
			printf_video("%s", &buffer[0]);
		} else {
		  printf_video("Failed to read file %s", file);
		}

		sdCloseHandle(fHandle);
	}
	
	shell_input();
}

static void bindump(uint8_t * file) {
	char buffer[500];
	HANDLE fHandle = sdCreateFile(file, GENERIC_READ, 0, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
	
	if (fHandle != 0) {
		uint32_t bytesRead;

		if ((sdReadFile(fHandle, &buffer[0], 500, &bytesRead, 0) == true))  {
			buffer[bytesRead-1] = '\0';
			
			int i;
			for (i = 0; i < 500; i++) {
				printf_video("%u ", buffer[i]);
			}
		} else {
		  printf_video("Failed to read file %s", file);
		}

		sdCloseHandle(fHandle);
	}
	
	shell_input();
}

static void testprogram() {
	char buffer[500];
	HANDLE fHandle = sdCreateFile("app.bin", GENERIC_READ, 0, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
	
	if (fHandle != 0) {
		uint32_t bytesRead;

		if ((sdReadFile(fHandle, &buffer[0], 500, &bytesRead, 0) == true))  {
			buffer[bytesRead-1] = '\0';
			
			int ret = ((int(*)(void))buffer)();
			printf_video("Process exited with code %d", ret);
		} else {
		  printf_video("Failed to load test program");
		}

		sdCloseHandle(fHandle);
	}
	
	shell_input();
}