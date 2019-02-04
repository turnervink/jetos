.section .text
.align 2

.globl _add
_add:
  push {lr}
  add r0, r0, r1
  pop {pc}
