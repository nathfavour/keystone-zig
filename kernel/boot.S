.section .text.boot
.global _start

_start:
    # early UART marker before stack setup
    li t0, 0x10000000
    li t1, 'K'
    sb t1, 0(t0)
    la sp, _stack_top
    j kernelMain

.section .bss
.align 16
_stack_bottom:
    .space 65536
_stack_top:
