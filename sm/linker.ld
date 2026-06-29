/*
 * SPDX-FileCopyrightText: 2026 2026 Nath Favour
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY {
    SM (rxa) : ORIGIN = 0x80000000, LENGTH = 1M
}

SECTIONS {
    . = ORIGIN(SM);

    .text : {
        KEEP(*(.text.boot))
        *(.text*)
    } > SM

    .rodata : {
        *(.rodata*)
    } > SM

    .data : {
        *(.data*)
    } > SM

    .bss : {
        *(.bss*)
        *(COMMON)
    } > SM
}
