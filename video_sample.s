/*
*  Video Sample 
*
*	From here (+ a few modifications):
*   https://github.com/mmuszkow/NoOsBootstrap/tree/master/arm
*
*/


@ The bootloader will print text to UART and display 
@ white "NO OS" bitmap on video output

@ I chose Raspberry Pi cause it's very popular and
@ it has a Video Controller with HDMI/Composite output
@ that can be easily programmed via mailbox interface

.section .text
.globl _video_sample
.align 2

@@@@@@@@@@@@@@ START @@@@@@@@@@@@@

_video_sample:
	push {lr}

    @ set Video Controller resolution to 640x480x16bit
    @ 16-bit, cause the 8-bit depth needs a palette
    @ and I'm too lazy to set it up
    ldr r1, =vc_set_res
    bl  mb0_c8_write
    bl  mb0_c8_read
    tst r0, #0x80000000
    beq .vc_init_fail

    @ get VC framebuffer address
    ldr r1, =vc_alloc_fb
    bl  mb0_c8_write
    bl  mb0_c8_read
    tst r0, #0x80000008
    beq .vc_init_fail

    @ check if the address is correct
    ldr r0, [r1, #20]
    cmp r0, #0
    beq .vc_init_fail

    @ draw "NO OS" text
    bl vc_draw_no_os_bmp
    
	pop {pc}

.vc_init_fail:
    ldr r1, =txt_vc_fail
    bl uart0_puts

halt:
    wfe @ low-power mode
    b halt

@@@@@@@@@@@@@@ UART @@@@@@@@@@@@@

.equ UART0BASE,  0x3F201000 @ for raspi2 & 3, 0x20201000 for raspi1
.equ UART0_CR,   UART0BASE + 0x30
.equ UART0_ICR,  UART0BASE + 0x44
.equ UART0_IBRD, UART0BASE + 0x24
.equ UART0_FBRD, UART0BASE + 0x28
.equ UART0_LCRH, UART0BASE + 0x2C
.equ UART0_IMSC, UART0BASE + 0x38
.equ UART0_FR,   UART0BASE + 0x18
.equ UART0_DR,   UART0BASE + 0x00
.equ GPIO_BASE,  0x3F200000 @ for raspi2 & 3, 0x20200000 for raspi1
.equ GPPUD,      GPIO_BASE + 0x94
.equ GPPUDCLK0,  GPIO_BASE + 0x98

.macro wait, count, reg0 = r1
    mov  \reg0, \count
1001: 
    sub \reg0, #1
    cmp \reg0, #0
    bne 1001b
.endm

.macro mem_write, addr, val, reg0 = r1, reg1 = r2
    ldr \reg0, =\addr
    ldr \reg1, =\val
    str \reg1, [\reg0]
.endm

@ init UART0 to 115200, no parity
uart0_init:
    mem_write UART0_CR, #0               @ disable UART0
    mem_write GPPUD, #0                  @ disable pull up/down for all GPIO pins
    wait #150
    mem_write GPPUDCLK0, #0b1100000000000000
    wait #150
    mem_write GPPUDCLK0,  #0
    mem_write UART0_ICR,  #0x7FF         @ clear pending interrupts
    mem_write UART0_IBRD, #1             @ divider = 3000000 / (16 * 115200) = 1.627 = ~1
    mem_write UART0_FBRD, #40            @ fractional part register = (.627 * 64) + 0.5 = 40.6 = ~40
    mem_write UART0_LCRH, #0b1110000     @ enable FIFO & 8 bit data transmissio (1 stop bit, no parity)
    mem_write UART0_IMSC, #0b11111110010 @ mask all interrupts
    mem_write UART0_CR,   #0b1100000001  @ enable UART0, receive & transfer part of UART
    mov pc, lr

@ writes null-terminated strting to UART0
@ r1 - string pointer
uart0_puts:
    ptr    .req r1
    char   .req r2
    dr     .req r3
    status .req r4
    ldr dr,     =UART0_DR 
    ldr status, =UART0_FR
.putc_loop:
    ldr r0, [status]    @ wait for UART0 to be ready
    tst r0, #0x20
    bne .putc_loop
    ldrb char, [ptr]    @ char = *str
    cmp char, #0        @ jump to end if char == 0
    beq .uart0_puts_end
    str char, [dr]      @ *UART0_DR = char
    add ptr, ptr, #1    @ str++
    b .putc_loop
.uart0_puts_end:
    .unreq ptr
    .unreq char
    .unreq dr
    .unreq status
    mov pc, lr

@@@@@@@@@@@@@@@ VC @@@@@@@@@@@@@@

.equ MBOX0, 0x3f00b880

@ writes to mailbox #0, channel 8
@ r1 - message
mb0_c8_write:
    message .req r1
    mailbox .req r3
    status  .req r2

    ldr mailbox, =MBOX0
.mb0_full:
    ldr status, [mailbox, #0x18]
    tst status, #0x80000000  @ mailbox full flag
    bne .mb0_full 
    add message, #8          @ channel 8
    str message, [mailbox, #0x20] @ write addr
    sub message, #8

    .unreq mailbox
    .unreq message
    .unreq status
    mov pc, lr

@ reads from mailbox #0, channel 8
@ r1 - message
@ returns status in r0
mb0_c8_read:
    message .req r1
    mailbox .req r2
    status  .req r3
    value   .req r4

    ldr mailbox, =MBOX0
.mb0_empty:
    ldr status, [mailbox, #0x18] 
    tst status, #0x40000000  @ mailbox empty flag
    bne .mb0_empty

    ldr value, [mailbox] @ check if the message channel is 8
    and r0, value, #0xf
    teq r0, #8
    bne .mb0_empty

    ldr r0, [message, #4] 
    .unreq message
    .unreq mailbox
    .unreq status
    .unreq value
    mov pc, lr

@ draws "NO OS" bitmap to fb
@ r0 - fb address
vc_draw_no_os_bmp:
    fb    .req r0
    white .req r1
    ldr white, =#0xFFFFFFFF
	ldr r2, =#282150
	add fb, r2
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #56]
	str white, [fb, #60]
	str white, [fb, #64]
	str white, [fb, #68]
	str white, [fb, #72]
	str white, [fb, #76]
	str white, [fb, #120]
	str white, [fb, #124]
	str white, [fb, #128]
	str white, [fb, #132]
	str white, [fb, #136]
	str white, [fb, #140]
	str white, [fb, #168]
	str white, [fb, #172]
	str white, [fb, #176]
	str white, [fb, #180]
	str white, [fb, #184]
	str white, [fb, #188]
	str white, [fb, #192]
	str white, [fb, #196]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #56]
	str white, [fb, #60]
	str white, [fb, #64]
	str white, [fb, #68]
	str white, [fb, #72]
	str white, [fb, #76]
	str white, [fb, #120]
	str white, [fb, #124]
	str white, [fb, #128]
	str white, [fb, #132]
	str white, [fb, #136]
	str white, [fb, #140]
	str white, [fb, #168]
	str white, [fb, #172]
	str white, [fb, #176]
	str white, [fb, #180]
	str white, [fb, #184]
	str white, [fb, #188]
	str white, [fb, #192]
	str white, [fb, #196]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #56]
	str white, [fb, #60]
	str white, [fb, #64]
	str white, [fb, #68]
	str white, [fb, #72]
	str white, [fb, #76]
	str white, [fb, #120]
	str white, [fb, #124]
	str white, [fb, #128]
	str white, [fb, #132]
	str white, [fb, #136]
	str white, [fb, #140]
	str white, [fb, #168]
	str white, [fb, #172]
	str white, [fb, #176]
	str white, [fb, #180]
	str white, [fb, #184]
	str white, [fb, #188]
	str white, [fb, #192]
	str white, [fb, #196]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #56]
	str white, [fb, #60]
	str white, [fb, #64]
	str white, [fb, #68]
	str white, [fb, #72]
	str white, [fb, #76]
	str white, [fb, #120]
	str white, [fb, #124]
	str white, [fb, #128]
	str white, [fb, #132]
	str white, [fb, #136]
	str white, [fb, #140]
	str white, [fb, #168]
	str white, [fb, #172]
	str white, [fb, #176]
	str white, [fb, #180]
	str white, [fb, #184]
	str white, [fb, #188]
	str white, [fb, #192]
	str white, [fb, #196]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #56]
	str white, [fb, #60]
	str white, [fb, #64]
	str white, [fb, #68]
	str white, [fb, #72]
	str white, [fb, #76]
	str white, [fb, #120]
	str white, [fb, #124]
	str white, [fb, #128]
	str white, [fb, #132]
	str white, [fb, #136]
	str white, [fb, #140]
	str white, [fb, #168]
	str white, [fb, #172]
	str white, [fb, #176]
	str white, [fb, #180]
	str white, [fb, #184]
	str white, [fb, #188]
	str white, [fb, #192]
	str white, [fb, #196]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #56]
	str white, [fb, #60]
	str white, [fb, #64]
	str white, [fb, #68]
	str white, [fb, #72]
	str white, [fb, #76]
	str white, [fb, #120]
	str white, [fb, #124]
	str white, [fb, #128]
	str white, [fb, #132]
	str white, [fb, #136]
	str white, [fb, #140]
	str white, [fb, #168]
	str white, [fb, #172]
	str white, [fb, #176]
	str white, [fb, #180]
	str white, [fb, #184]
	str white, [fb, #188]
	str white, [fb, #192]
	str white, [fb, #196]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #56]
	str white, [fb, #60]
	str white, [fb, #64]
	str white, [fb, #68]
	str white, [fb, #72]
	str white, [fb, #76]
	str white, [fb, #120]
	str white, [fb, #124]
	str white, [fb, #128]
	str white, [fb, #132]
	str white, [fb, #136]
	str white, [fb, #140]
	str white, [fb, #168]
	str white, [fb, #172]
	str white, [fb, #176]
	str white, [fb, #180]
	str white, [fb, #184]
	str white, [fb, #188]
	str white, [fb, #192]
	str white, [fb, #196]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #56]
	str white, [fb, #60]
	str white, [fb, #64]
	str white, [fb, #68]
	str white, [fb, #72]
	str white, [fb, #76]
	str white, [fb, #120]
	str white, [fb, #124]
	str white, [fb, #128]
	str white, [fb, #132]
	str white, [fb, #136]
	str white, [fb, #140]
	str white, [fb, #168]
	str white, [fb, #172]
	str white, [fb, #176]
	str white, [fb, #180]
	str white, [fb, #184]
	str white, [fb, #188]
	str white, [fb, #192]
	str white, [fb, #196]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #8]
	str white, [fb, #12]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #48]
	str white, [fb, #52]
	str white, [fb, #80]
	str white, [fb, #84]
	str white, [fb, #112]
	str white, [fb, #116]
	str white, [fb, #144]
	str white, [fb, #148]
	str white, [fb, #160]
	str white, [fb, #164]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #8]
	str white, [fb, #12]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #48]
	str white, [fb, #52]
	str white, [fb, #80]
	str white, [fb, #84]
	str white, [fb, #112]
	str white, [fb, #116]
	str white, [fb, #144]
	str white, [fb, #148]
	str white, [fb, #160]
	str white, [fb, #164]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #8]
	str white, [fb, #12]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #48]
	str white, [fb, #52]
	str white, [fb, #80]
	str white, [fb, #84]
	str white, [fb, #112]
	str white, [fb, #116]
	str white, [fb, #144]
	str white, [fb, #148]
	str white, [fb, #160]
	str white, [fb, #164]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #8]
	str white, [fb, #12]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #48]
	str white, [fb, #52]
	str white, [fb, #80]
	str white, [fb, #84]
	str white, [fb, #112]
	str white, [fb, #116]
	str white, [fb, #144]
	str white, [fb, #148]
	str white, [fb, #160]
	str white, [fb, #164]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #8]
	str white, [fb, #12]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #48]
	str white, [fb, #52]
	str white, [fb, #80]
	str white, [fb, #84]
	str white, [fb, #112]
	str white, [fb, #116]
	str white, [fb, #144]
	str white, [fb, #148]
	str white, [fb, #160]
	str white, [fb, #164]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #8]
	str white, [fb, #12]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #48]
	str white, [fb, #52]
	str white, [fb, #80]
	str white, [fb, #84]
	str white, [fb, #112]
	str white, [fb, #116]
	str white, [fb, #144]
	str white, [fb, #148]
	str white, [fb, #160]
	str white, [fb, #164]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #8]
	str white, [fb, #12]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #48]
	str white, [fb, #52]
	str white, [fb, #80]
	str white, [fb, #84]
	str white, [fb, #112]
	str white, [fb, #116]
	str white, [fb, #144]
	str white, [fb, #148]
	str white, [fb, #160]
	str white, [fb, #164]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #8]
	str white, [fb, #12]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #48]
	str white, [fb, #52]
	str white, [fb, #80]
	str white, [fb, #84]
	str white, [fb, #112]
	str white, [fb, #116]
	str white, [fb, #144]
	str white, [fb, #148]
	str white, [fb, #160]
	str white, [fb, #164]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #16]
	str white, [fb, #20]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #48]
	str white, [fb, #52]
	str white, [fb, #80]
	str white, [fb, #84]
	str white, [fb, #112]
	str white, [fb, #116]
	str white, [fb, #144]
	str white, [fb, #148]
	str white, [fb, #168]
	str white, [fb, #172]
	str white, [fb, #176]
	str white, [fb, #180]
	str white, [fb, #184]
	str white, [fb, #188]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #16]
	str white, [fb, #20]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #48]
	str white, [fb, #52]
	str white, [fb, #80]
	str white, [fb, #84]
	str white, [fb, #112]
	str white, [fb, #116]
	str white, [fb, #144]
	str white, [fb, #148]
	str white, [fb, #168]
	str white, [fb, #172]
	str white, [fb, #176]
	str white, [fb, #180]
	str white, [fb, #184]
	str white, [fb, #188]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #16]
	str white, [fb, #20]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #48]
	str white, [fb, #52]
	str white, [fb, #80]
	str white, [fb, #84]
	str white, [fb, #112]
	str white, [fb, #116]
	str white, [fb, #144]
	str white, [fb, #148]
	str white, [fb, #168]
	str white, [fb, #172]
	str white, [fb, #176]
	str white, [fb, #180]
	str white, [fb, #184]
	str white, [fb, #188]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #16]
	str white, [fb, #20]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #48]
	str white, [fb, #52]
	str white, [fb, #80]
	str white, [fb, #84]
	str white, [fb, #112]
	str white, [fb, #116]
	str white, [fb, #144]
	str white, [fb, #148]
	str white, [fb, #168]
	str white, [fb, #172]
	str white, [fb, #176]
	str white, [fb, #180]
	str white, [fb, #184]
	str white, [fb, #188]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #16]
	str white, [fb, #20]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #48]
	str white, [fb, #52]
	str white, [fb, #80]
	str white, [fb, #84]
	str white, [fb, #112]
	str white, [fb, #116]
	str white, [fb, #144]
	str white, [fb, #148]
	str white, [fb, #168]
	str white, [fb, #172]
	str white, [fb, #176]
	str white, [fb, #180]
	str white, [fb, #184]
	str white, [fb, #188]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #16]
	str white, [fb, #20]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #48]
	str white, [fb, #52]
	str white, [fb, #80]
	str white, [fb, #84]
	str white, [fb, #112]
	str white, [fb, #116]
	str white, [fb, #144]
	str white, [fb, #148]
	str white, [fb, #168]
	str white, [fb, #172]
	str white, [fb, #176]
	str white, [fb, #180]
	str white, [fb, #184]
	str white, [fb, #188]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #16]
	str white, [fb, #20]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #48]
	str white, [fb, #52]
	str white, [fb, #80]
	str white, [fb, #84]
	str white, [fb, #112]
	str white, [fb, #116]
	str white, [fb, #144]
	str white, [fb, #148]
	str white, [fb, #168]
	str white, [fb, #172]
	str white, [fb, #176]
	str white, [fb, #180]
	str white, [fb, #184]
	str white, [fb, #188]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #16]
	str white, [fb, #20]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #48]
	str white, [fb, #52]
	str white, [fb, #80]
	str white, [fb, #84]
	str white, [fb, #112]
	str white, [fb, #116]
	str white, [fb, #144]
	str white, [fb, #148]
	str white, [fb, #168]
	str white, [fb, #172]
	str white, [fb, #176]
	str white, [fb, #180]
	str white, [fb, #184]
	str white, [fb, #188]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #24]
	str white, [fb, #28]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #48]
	str white, [fb, #52]
	str white, [fb, #80]
	str white, [fb, #84]
	str white, [fb, #112]
	str white, [fb, #116]
	str white, [fb, #144]
	str white, [fb, #148]
	str white, [fb, #192]
	str white, [fb, #196]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #24]
	str white, [fb, #28]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #48]
	str white, [fb, #52]
	str white, [fb, #80]
	str white, [fb, #84]
	str white, [fb, #112]
	str white, [fb, #116]
	str white, [fb, #144]
	str white, [fb, #148]
	str white, [fb, #192]
	str white, [fb, #196]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #24]
	str white, [fb, #28]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #48]
	str white, [fb, #52]
	str white, [fb, #80]
	str white, [fb, #84]
	str white, [fb, #112]
	str white, [fb, #116]
	str white, [fb, #144]
	str white, [fb, #148]
	str white, [fb, #192]
	str white, [fb, #196]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #24]
	str white, [fb, #28]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #48]
	str white, [fb, #52]
	str white, [fb, #80]
	str white, [fb, #84]
	str white, [fb, #112]
	str white, [fb, #116]
	str white, [fb, #144]
	str white, [fb, #148]
	str white, [fb, #192]
	str white, [fb, #196]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #24]
	str white, [fb, #28]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #48]
	str white, [fb, #52]
	str white, [fb, #80]
	str white, [fb, #84]
	str white, [fb, #112]
	str white, [fb, #116]
	str white, [fb, #144]
	str white, [fb, #148]
	str white, [fb, #192]
	str white, [fb, #196]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #24]
	str white, [fb, #28]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #48]
	str white, [fb, #52]
	str white, [fb, #80]
	str white, [fb, #84]
	str white, [fb, #112]
	str white, [fb, #116]
	str white, [fb, #144]
	str white, [fb, #148]
	str white, [fb, #192]
	str white, [fb, #196]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #24]
	str white, [fb, #28]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #48]
	str white, [fb, #52]
	str white, [fb, #80]
	str white, [fb, #84]
	str white, [fb, #112]
	str white, [fb, #116]
	str white, [fb, #144]
	str white, [fb, #148]
	str white, [fb, #192]
	str white, [fb, #196]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #24]
	str white, [fb, #28]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #48]
	str white, [fb, #52]
	str white, [fb, #80]
	str white, [fb, #84]
	str white, [fb, #112]
	str white, [fb, #116]
	str white, [fb, #144]
	str white, [fb, #148]
	str white, [fb, #192]
	str white, [fb, #196]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #56]
	str white, [fb, #60]
	str white, [fb, #64]
	str white, [fb, #68]
	str white, [fb, #72]
	str white, [fb, #76]
	str white, [fb, #120]
	str white, [fb, #124]
	str white, [fb, #128]
	str white, [fb, #132]
	str white, [fb, #136]
	str white, [fb, #140]
	str white, [fb, #160]
	str white, [fb, #164]
	str white, [fb, #168]
	str white, [fb, #172]
	str white, [fb, #176]
	str white, [fb, #180]
	str white, [fb, #184]
	str white, [fb, #188]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #56]
	str white, [fb, #60]
	str white, [fb, #64]
	str white, [fb, #68]
	str white, [fb, #72]
	str white, [fb, #76]
	str white, [fb, #120]
	str white, [fb, #124]
	str white, [fb, #128]
	str white, [fb, #132]
	str white, [fb, #136]
	str white, [fb, #140]
	str white, [fb, #160]
	str white, [fb, #164]
	str white, [fb, #168]
	str white, [fb, #172]
	str white, [fb, #176]
	str white, [fb, #180]
	str white, [fb, #184]
	str white, [fb, #188]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #56]
	str white, [fb, #60]
	str white, [fb, #64]
	str white, [fb, #68]
	str white, [fb, #72]
	str white, [fb, #76]
	str white, [fb, #120]
	str white, [fb, #124]
	str white, [fb, #128]
	str white, [fb, #132]
	str white, [fb, #136]
	str white, [fb, #140]
	str white, [fb, #160]
	str white, [fb, #164]
	str white, [fb, #168]
	str white, [fb, #172]
	str white, [fb, #176]
	str white, [fb, #180]
	str white, [fb, #184]
	str white, [fb, #188]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #56]
	str white, [fb, #60]
	str white, [fb, #64]
	str white, [fb, #68]
	str white, [fb, #72]
	str white, [fb, #76]
	str white, [fb, #120]
	str white, [fb, #124]
	str white, [fb, #128]
	str white, [fb, #132]
	str white, [fb, #136]
	str white, [fb, #140]
	str white, [fb, #160]
	str white, [fb, #164]
	str white, [fb, #168]
	str white, [fb, #172]
	str white, [fb, #176]
	str white, [fb, #180]
	str white, [fb, #184]
	str white, [fb, #188]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #56]
	str white, [fb, #60]
	str white, [fb, #64]
	str white, [fb, #68]
	str white, [fb, #72]
	str white, [fb, #76]
	str white, [fb, #120]
	str white, [fb, #124]
	str white, [fb, #128]
	str white, [fb, #132]
	str white, [fb, #136]
	str white, [fb, #140]
	str white, [fb, #160]
	str white, [fb, #164]
	str white, [fb, #168]
	str white, [fb, #172]
	str white, [fb, #176]
	str white, [fb, #180]
	str white, [fb, #184]
	str white, [fb, #188]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #56]
	str white, [fb, #60]
	str white, [fb, #64]
	str white, [fb, #68]
	str white, [fb, #72]
	str white, [fb, #76]
	str white, [fb, #120]
	str white, [fb, #124]
	str white, [fb, #128]
	str white, [fb, #132]
	str white, [fb, #136]
	str white, [fb, #140]
	str white, [fb, #160]
	str white, [fb, #164]
	str white, [fb, #168]
	str white, [fb, #172]
	str white, [fb, #176]
	str white, [fb, #180]
	str white, [fb, #184]
	str white, [fb, #188]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #56]
	str white, [fb, #60]
	str white, [fb, #64]
	str white, [fb, #68]
	str white, [fb, #72]
	str white, [fb, #76]
	str white, [fb, #120]
	str white, [fb, #124]
	str white, [fb, #128]
	str white, [fb, #132]
	str white, [fb, #136]
	str white, [fb, #140]
	str white, [fb, #160]
	str white, [fb, #164]
	str white, [fb, #168]
	str white, [fb, #172]
	str white, [fb, #176]
	str white, [fb, #180]
	str white, [fb, #184]
	str white, [fb, #188]
	add fb, #1280
	str white, [fb, #0]
	str white, [fb, #4]
	str white, [fb, #32]
	str white, [fb, #36]
	str white, [fb, #56]
	str white, [fb, #60]
	str white, [fb, #64]
	str white, [fb, #68]
	str white, [fb, #72]
	str white, [fb, #76]
	str white, [fb, #120]
	str white, [fb, #124]
	str white, [fb, #128]
	str white, [fb, #132]
	str white, [fb, #136]
	str white, [fb, #140]
	str white, [fb, #160]
	str white, [fb, #164]
	str white, [fb, #168]
	str white, [fb, #172]
	str white, [fb, #176]
	str white, [fb, #180]
	str white, [fb, #184]
	str white, [fb, #188]
	add fb, #1280
    mov pc, lr

@ raspi mailbox requests, must be padded to 16 bytes
.align 4
vc_set_res:  .word 80, 0                      @ total size, code (0=req)
             .word 0x00048003, 8, 8, 640, 480 @ set physical size (640x480)
             .word 0x00048004, 8, 8, 640, 480 @ set virtual size (640x480)
             .word 0x00048005, 4, 4, 16       @ set depth (16-bit)
             .word 0, 0, 0, 0                 @ end tag & padding

vc_alloc_fb: .word 32, 0                      @ total size, code (0=req)
             .word 0x00040001, 8, 4, 16, 0    @ allocate framebuffer
             .word 0                          @ end tag & padding

.align 2
txt_welcome: .asciz "No OS installed\r\n"
txt_vc_fail: .asciz "VC initialization failed\r\n"
