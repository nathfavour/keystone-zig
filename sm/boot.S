/*
 * SPDX-FileCopyrightText: 2026 2026 Nath Favour
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

.section .text.boot
.global _start
.global sm_stack_top
.type _start, @function

_start:
    # M-mode entry: disable interrupts, set stack, zero BSS, jump to Zig SM
    csrw    mstatus, zero
    la      sp, _stack_top
    la      t0, __bss_start
    la      t1, __bss_end
1:
    bgeu    t0, t1, 2f
    sd      zero, 0(t0)
    addi    t0, t0, 8
    j       1b
2:
    j       smEntry

.section .bss
.align 16
_stack_bottom:
    .space  8192
_stack_top:

.section .bss.trap
.align 16
_sm_stack_bottom:
    .space  8192
sm_stack_top:
