/*
 * SPDX-FileCopyrightText: 2026 2026 Nath Favour
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

.section .text.boot
.global _start

_start:
    la sp, _stack_top
    j enclaveMain

.section .bss
.align 16
_stack_bottom:
    .space 32768
_stack_top:
