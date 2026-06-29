//! Minimal enclave runtime — parity with Eyrie entry.

const keystone = @import("keystone");
const sbi = keystone.sbi;
const uart = keystone.uart;

export fn enclaveMain() void {
    uart.write("enclave-hello: secure bubble\r\n");

    _ = sbi.ecall(
        sbi.extension_id,
        @intFromEnum(sbi.Fid.exit_enclave),
        0,
        0, 0, 0, 0, 0,
    );
}
