OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY {
    KERNEL (rxa) : ORIGIN = 0x80200000, LENGTH = 16M
}

SECTIONS {
    . = ORIGIN(KERNEL);

    .text : ALIGN(4) {
        KEEP(*(.text._start))
        KEEP(*(.text.start))
        *(.text*)
    } > KERNEL

    .rodata : ALIGN(4) { *(.rodata*) } > KERNEL
    .data : ALIGN(4) { *(.data*) } > KERNEL
    .bss : ALIGN(4) {
        *(.bss*)
        *(COMMON)
    } > KERNEL
}
