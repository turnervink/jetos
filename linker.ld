
__stack_size__ = DEFINED(__stack_size__) ? __stack_size__ : 0x3000;
 
SECTIONS
{

    . = 0x8000;
	
    __start = .;
    
	__text_start = .;
    .text : {
        KEEP(*(.boot))
        *(.text)
    } 
    __text_end = .;
	
	
	. = ALIGN(4096); /* aligne to page */
    __data_start = .;
    .data :
    {
        *(.data)
    } 
    __data_end = .;
	
 
	. = ALIGN(4096); /* aligne to page */
    __bss_start = .;
    .bss (NOLOAD):
    {
        *(.bss)
    } 
    __bss_end = .;
	
	
	. = ALIGN(4096); /* aligne to page */
	__rodata_start = .;
    .rodata : {
        *(.rodata)
    }
    __rodata_end = .;
	
	
	. = ALIGN(4096); /* aligne to page */
	__stack_start = .;
    .stack (NOLOAD):
    {
        . = . + __stack_size__;
    } 
	__stack_end = .;
	
	__end = .;
}