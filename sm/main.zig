//! Keystone Security Monitor — M-mode root of trust.
//!
//! Boot sequence:
//!   1. `_start` (boot.S) → `smEntry`
//!   2. Install trap vector, apply comptime PMP map
//!   3. Delegate S-mode interrupts, drop to kernel stub at S-mode

const keystone = @import("keystone");
const csr = keystone.csr;
const gpr = keystone.gpr;
const pmp = keystone.pmp;
const sbi = keystone.sbi;
const enclave = keystone.enclave;
const layout = keystone.layout;
const uart = keystone.uart;

var enclaves = enclave.Table.init();
var current_eid: u32 = enclave.invalid_id;

export fn smEntry() noreturn {
    uart.write("keystone-zig SM: boot\r\n");

    installTrapVector();
    applyBootPmpMap();
    delegateToSupervisor();

    const kernel_entry: *const fn () noreturn = @ptrFromInt(layout.qemu_virt.kernel_base);
    uart.write("keystone-zig SM: entering S-mode kernel\r\n");
    enterSupervisor(kernel_entry);
}

fn installTrapVector() void {
    const trap_handler: usize = @intFromPtr(&mTrapHandler);
    csr.write("mtvec", trap_handler);
}

fn applyBootPmpMap() void {
    const map = comptime layout.qemu_virt.boot_map;
    comptime pmp.Map.validate(map);

    inline for (map.regions, 0..) |region, entry| {
        writePmpEntry(@intCast(entry), region.napotAddr(), region.cfgByte());
    }
    csr.sfence_vma();
    uart.write("keystone-zig SM: PMP map applied\r\n");
}

fn writePmpEntry(entry: u8, pmpaddr: usize, cfg_byte: u8) void {
    const slot = entry % 8;
    const shift: u6 = @intCast(slot * 8);
    const mask: usize = ~(@as(usize, 0xFF) << shift);
    const cfg_val: usize = @as(usize, cfg_byte) << shift;

    switch (entry) {
        0 => {
            csr.write("pmpaddr0", pmpaddr);
            csr.write("pmpcfg0", (csr.read("pmpcfg0") & mask) | cfg_val);
        },
        1 => {
            csr.write("pmpaddr1", pmpaddr);
            csr.write("pmpcfg0", (csr.read("pmpcfg0") & mask) | cfg_val);
        },
        2 => {
            csr.write("pmpaddr2", pmpaddr);
            csr.write("pmpcfg0", (csr.read("pmpcfg0") & mask) | cfg_val);
        },
        3 => {
            csr.write("pmpaddr3", pmpaddr);
            csr.write("pmpcfg0", (csr.read("pmpcfg0") & mask) | cfg_val);
        },
        4 => {
            csr.write("pmpaddr4", pmpaddr);
            csr.write("pmpcfg0", (csr.read("pmpcfg0") & mask) | cfg_val);
        },
        5 => {
            csr.write("pmpaddr5", pmpaddr);
            csr.write("pmpcfg0", (csr.read("pmpcfg0") & mask) | cfg_val);
        },
        6 => {
            csr.write("pmpaddr6", pmpaddr);
            csr.write("pmpcfg0", (csr.read("pmpcfg0") & mask) | cfg_val);
        },
        7 => {
            csr.write("pmpaddr7", pmpaddr);
            csr.write("pmpcfg0", (csr.read("pmpcfg0") & mask) | cfg_val);
        },
        8 => {
            csr.write("pmpaddr8", pmpaddr);
            csr.write("pmpcfg2", (csr.read("pmpcfg2") & mask) | cfg_val);
        },
        9 => {
            csr.write("pmpaddr9", pmpaddr);
            csr.write("pmpcfg2", (csr.read("pmpcfg2") & mask) | cfg_val);
        },
        10 => {
            csr.write("pmpaddr10", pmpaddr);
            csr.write("pmpcfg2", (csr.read("pmpcfg2") & mask) | cfg_val);
        },
        11 => {
            csr.write("pmpaddr11", pmpaddr);
            csr.write("pmpcfg2", (csr.read("pmpcfg2") & mask) | cfg_val);
        },
        12 => {
            csr.write("pmpaddr12", pmpaddr);
            csr.write("pmpcfg2", (csr.read("pmpcfg2") & mask) | cfg_val);
        },
        13 => {
            csr.write("pmpaddr13", pmpaddr);
            csr.write("pmpcfg2", (csr.read("pmpcfg2") & mask) | cfg_val);
        },
        14 => {
            csr.write("pmpaddr14", pmpaddr);
            csr.write("pmpcfg2", (csr.read("pmpcfg2") & mask) | cfg_val);
        },
        15 => {
            csr.write("pmpaddr15", pmpaddr);
            csr.write("pmpcfg2", (csr.read("pmpcfg2") & mask) | cfg_val);
        },
        else => unreachable,
    }
}

fn delegateToSupervisor() void {
    csr.write("mideleg", 0x222);
    csr.write("medeleg", 0xB1FF);
}

fn enterSupervisor(entry: *const fn () noreturn) noreturn {
    const kernel_sp: usize = layout.qemu_virt.kernel_base + layout.qemu_virt.kernel_size - 16;
    var mstatus: csr.Mstatus = @bitCast(csr.read("mstatus"));
    mstatus.mpp = csr.Mstatus.mpp_s;
    mstatus.mpie = 1;
    csr.write("mstatus", @bitCast(mstatus));
    csr.write("mepc", @intFromPtr(entry));
    csr.write("satp", 0);
    asm volatile (
        \\ mv sp, %[sp]
        \\ mret
        :
        : [sp] "r" (kernel_sp),
    );
    unreachable;
}

export fn mTrapHandler() void {
    const mcause = csr.read("mcause");
    const is_ecall = (mcause & (1 << 63)) == 0 and (mcause & 0xFF) == 11;

    if (is_ecall) {
        handleSbiEcall();
        return;
    }

    uart.print("keystone-zig SM: unhandled trap mcause=0x{x}\r\n", .{mcause});
    csr.wfi();
}

fn handleSbiEcall() void {
    const ext: u32 = @truncate(gpr.read("a7"));
    const fid: u32 = @truncate(gpr.read("a6"));

    if (ext != sbi.extension_id) {
        returnSbi(.{ .error_code = @intFromEnum(sbi.Error.not_implemented), .value = 0 });
        return;
    }

    const ret: sbi.SbiRet = switch (@as(sbi.Fid, @enumFromInt(fid))) {
        .create_enclave => smCreateEnclave(),
        .destroy_enclave => smDestroyEnclave(),
        .run_enclave => smRunEnclave(),
        .resume_enclave => smResumeEnclave(),
        .stop_enclave => smStopEnclave(),
        .exit_enclave => smExitEnclave(),
        else => sbi.Error.not_implemented.toSbiRet(),
    };

    returnSbi(ret);
}

fn smCreateEnclave() sbi.SbiRet {
    const args_ptr: usize = gpr.read("a0");
    const args: sbi.CreateArgs = @as(*const sbi.CreateArgs, @ptrFromInt(args_ptr)).*;

    const err = enclave.validateCreateArgs(args);
    if (err != .success) return err.toSbiRet();

    const eid = enclaves.allocate() orelse return sbi.Error.no_free_resource.toSbiRet();
    const slot = enclaves.get(eid).?;

    slot.regions[0] = .{
        .pmp_entry = 4,
        .region_type = .epm,
        .base = args.epm_paddr,
        .size = args.epm_size,
    };
    if (args.utm_size > 0) {
        slot.regions[1] = .{
            .pmp_entry = 5,
            .region_type = .utm,
            .base = args.utm_paddr,
            .size = args.utm_size,
        };
    }
    slot.params = .{
        .dram_base = args.epm_paddr,
        .dram_size = args.epm_size,
        .runtime_base = args.epm_paddr,
        .user_base = args.epm_paddr,
        .free_base = args.epm_paddr + args.epm_size,
        .untrusted_base = args.utm_paddr,
        .untrusted_size = args.utm_size,
    };
    slot.state = .fresh;

    uart.print("keystone-zig SM: created enclave eid={d}\r\n", .{eid});
    return .{ .error_code = 0, .value = eid };
}

fn smDestroyEnclave() sbi.SbiRet {
    const eid: u32 = @truncate(gpr.read("a0"));
    return enclaves.destroy(eid).toSbiRet();
}

fn smRunEnclave() sbi.SbiRet {
    const eid: u32 = @truncate(gpr.read("a0"));
    const slot = enclaves.get(eid) orelse return sbi.Error.invalid_id.toSbiRet();
    if (slot.state != .fresh and slot.state != .stopped) return sbi.Error.not_runnable.toSbiRet();

    current_eid = eid;
    slot.state = .running;
    contextSwitchToEnclave(slot, slot.state == .fresh);
    slot.state = .stopped;
    current_eid = enclave.invalid_id;
    return .{ .error_code = 0, .value = 0 };
}

fn smResumeEnclave() sbi.SbiRet {
    return smRunEnclave();
}

fn smStopEnclave() sbi.SbiRet {
    return .{ .error_code = 0, .value = 0 };
}

fn smExitEnclave() sbi.SbiRet {
    const eid = current_eid;
    if (enclaves.get(eid)) |slot| {
        slot.state = .stopped;
    }
    return .{ .error_code = 0, .value = 0 };
}

fn contextSwitchToEnclave(slot: *enclave.Enclave, first_run: bool) void {
    _ = slot;
    _ = first_run;
    uart.write("keystone-zig SM: enclave context switch (stub)\r\n");
}

fn returnSbi(ret: sbi.SbiRet) void {
    gpr.write("a0", @as(usize, @intCast(ret.error_code)));
    gpr.write("a1", ret.value);
    const mepc = csr.read("mepc");
    csr.write("mepc", mepc + 4);
}
