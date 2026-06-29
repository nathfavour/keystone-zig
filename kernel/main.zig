//! S-mode kernel stub — integration point for clarigggz Core Broker.

const keystone = @import("keystone");
const sbi = keystone.sbi;
const layout = keystone.layout;
const uart = keystone.uart;

const EPM_BASE: usize = layout.qemu_virt.enclave_pool_base;
const EPM_SIZE: usize = 0x0040_0000;
const RUNTIME: usize = EPM_BASE;
const USER: usize = EPM_BASE + 0x0010_0000;
const FREE: usize = EPM_BASE + 0x0020_0000;
const UTM_BASE: usize = EPM_BASE + EPM_SIZE;
const UTM_SIZE: usize = 0x0010_0000;

export fn _start() noreturn {
    uart.write("keystone-zig kernel stub: alive\r\n");
    demoEnclaveLifecycle();
    uart.write("keystone-zig kernel stub: halt\r\n");
    while (true) keystone.csr.wfi();
}

fn demoEnclaveLifecycle() void {
    var args = sbi.CreateArgs{
        .epm_region = .{ .paddr = EPM_BASE, .size = EPM_SIZE },
        .utm_region = .{ .paddr = UTM_BASE, .size = UTM_SIZE },
        .runtime_paddr = RUNTIME,
        .user_paddr = USER,
        .free_paddr = FREE,
        .free_requested = FREE - USER,
    };

    const create = sbi.ecall(
        sbi.extension_id,
        @intFromEnum(sbi.Fid.create_enclave),
        @intFromPtr(&args),
        0, 0, 0, 0, 0,
    );
    if (create.error_code != 0) {
        uart.print("kernel stub: create err={d}\r\n", .{create.error_code});
        return;
    }
    const eid = create.value;
    uart.print("kernel stub: created eid={d}\r\n", .{eid});

    const run = sbi.ecall(
        sbi.extension_id,
        @intFromEnum(sbi.Fid.run_enclave),
        eid,
        0, 0, 0, 0, 0,
    );
    uart.print("kernel stub: run err={d}\r\n", .{run.error_code});

    const destroy = sbi.ecall(
        sbi.extension_id,
        @intFromEnum(sbi.Fid.destroy_enclave),
        eid,
        0, 0, 0, 0, 0,
    );
    uart.print("kernel stub: destroy err={d}\r\n", .{destroy.error_code});
}
