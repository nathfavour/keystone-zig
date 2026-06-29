//! S-mode kernel stub — integration point for clarigggz Core Broker.
//!
//! Issues Keystone SBI ecalls to the Security Monitor for enclave lifecycle.
//! In production, this file is replaced by clarigggz kernel entry.

const keystone = @import("keystone");
const sbi = keystone.sbi;
const uart = keystone.uart;

export fn _start() noreturn {
    uart.write("keystone-zig kernel stub: alive\r\n");
    demoEnclaveLifecycle();
    uart.write("keystone-zig kernel stub: halt\r\n");
    while (true) {
        keystone.csr.wfi();
    }
}

fn demoEnclaveLifecycle() void {
    var args = sbi.CreateArgs{
        .epm_paddr = 0x9000_0000,
        .epm_size = 0x0040_0000,
        .utm_paddr = 0x9400_0000,
        .utm_size = 0x0010_0000,
    };

    const create = sbi.ecall(
        sbi.extension_id,
        @intFromEnum(sbi.Fid.create_enclave),
        @intFromPtr(&args),
        0, 0, 0, 0, 0,
    );

    if (create.error_code != 0) {
        uart.print("kernel stub: create failed err={d}\r\n", .{create.error_code});
        return;
    }

    const eid = create.value;
    uart.print("kernel stub: enclave {d} created\r\n", .{eid});

    const run = sbi.ecall(
        sbi.extension_id,
        @intFromEnum(sbi.Fid.run_enclave),
        eid,
        0, 0, 0, 0, 0,
    );
    uart.print("kernel stub: run returned err={d}\r\n", .{run.error_code});
}
