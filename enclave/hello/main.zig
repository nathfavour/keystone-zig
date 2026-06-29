//! Minimal enclave application — runs in isolated S-mode bubble (phase 2).
//!
//! No Eyrie runtime: clarigggz microkernel talks to SM directly.

const keystone = @import("keystone");
const sbi = keystone.sbi;
const uart = keystone.uart;

export fn enclave_main(params: sbi.RuntimeParams) void {
    _ = params;
    uart.write("enclave-hello: inside secure bubble\r\n");

    _ = sbi.ecall(
        sbi.extension_id,
        @intFromEnum(sbi.Fid.exit_enclave),
        0, 0, 0, 0, 0, 0,
    );
}
