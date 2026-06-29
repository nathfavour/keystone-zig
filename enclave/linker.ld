OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY {
    ENCLAVE (rxa) : ORIGIN = 0x90000000, LENGTH = 4M
}

SECTIONS {
    . = ORIGIN(ENCLAVE);
    .text : { *(.text*) } > ENCLAVE
    .rodata : { *(.rodata*) } > ENCLAVE
    .data : { *(.data*) } > ENCLAVE
    .bss : { *(.bss*) *(COMMON) } > ENCLAVE
}
