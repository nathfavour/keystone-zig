//! Minimal enclave runtime — parity with Eyrie entry (params in a1–a7 on first run).

const keystone = @import("keystone");
const sbi = keystone.sbi;
const uart = keystone.uart;

export fn _start() callconv(.naked) noreturn {
    asm volatile (
        \\ call enclaveMain
        \\ 1: wfi
        \\ j 1b
    );
    unreachable;
}

export fn enclaveMain() void {
    uart.write("enclave-hello: secure bubble\r\n");

    const ret = sbi.ecall(
        sbi.extension_id,
        @intFromEnum(sbi.Fid.exit_enclave),
        0,
        0, 0, 0, 0, 0,
    );
    _ = ret;
}
