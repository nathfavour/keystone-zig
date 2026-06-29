OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY {
    ENCLAVE (rxa) : ORIGIN = 0x90000000, LENGTH = 4M
}

SECTIONS {
    . = ORIGIN(ENCLAVE);

    .text : ALIGN(4) {
        KEEP(*(.text.boot))
        *(.text*)
    } > ENCLAVE

    .rodata : ALIGN(4) { *(.rodata*) } > ENCLAVE
    .data : ALIGN(4) { *(.data*) } > ENCLAVE
    .bss : ALIGN(4) {
        *(.bss*)
        *(COMMON)
    } > ENCLAVE
}
