OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY {
    KERNEL (rxa) : ORIGIN = 0x80200000, LENGTH = 16M
}

SECTIONS {
    . = ORIGIN(KERNEL);

    .text : {
        *(.text*)
    } > KERNEL

    .rodata : { *(.rodata*) } > KERNEL
    .data : { *(.data*) } > KERNEL
    .bss : {
        *(.bss*)
        *(COMMON)
    } > KERNEL
}
