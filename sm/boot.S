.section .text.boot
.global _start
.type _start, @function

_start:
    # M-mode entry: disable interrupts, set stack, jump to Zig SM
    csrw    mstatus, zero
    la      sp, _stack_top
    j       smEntry

.section .bss
.align 16
_stack_bottom:
    .space  8192
_stack_top:
