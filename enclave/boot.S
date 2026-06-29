.section .text.boot
.global _start

_start:
    li t0, 0x10000000
    li t1, 'E'
    sb t1, 0(t0)
    la sp, _stack_top
    j enclaveMain

.section .bss
.align 16
_stack_bottom:
    .space 32768
_stack_top:
