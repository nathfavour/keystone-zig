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
    # M-mode entry: disable interrupts, set stack, jump to Zig SM
    csrw    mstatus, zero
    la      sp, _stack_top
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
