//! Keystone Security Monitor — M-mode root of trust.
//! Parity target: `sm.c`, `sm-sbi.c`, `sm-sbi-opensbi.c`.

const keystone = @import("keystone");
const csr = keystone.csr;
const sbi = keystone.sbi;
const enclave = keystone.enclave;
const enclave_ops = keystone.enclave_ops;
const layout = keystone.layout;
const uart = keystone.uart;
const pmp_runtime = keystone.pmp_runtime;
const cpu = keystone.cpu;
const crypto = keystone.crypto;
const trap_regs = keystone.trap_regs;

export fn smEntry() noreturn {
    uart.write("keystone-zig SM: boot\r\n");

    crypto.smInitKeys();
    enclave.initMetadata();

    const ierr = pmp_runtime.smInitRegions(layout.qemu_virt.sm_base, layout.qemu_virt.sm_size);
    if (ierr != .success) {
        uart.write("keystone-zig SM: PMP init failed\r\n");
        while (true) csr.wfi();
    }

    delegateToSupervisor();
    threadHostVector();

    uart.write("keystone-zig SM: entering S-mode kernel\r\n");
    enterSupervisor(layout.qemu_virt.kernel_entry);
}

fn threadHostVector() void {
    csr.write("mtvec", @intFromPtr(&mTrapHandler));
}

fn delegateToSupervisor() void {
    // Kernel sets these once its trap vector is live.
    csr.write("mideleg", 0);
    csr.write("medeleg", 0);
}

extern fn drop_to_supervisor(entry: usize, sp: usize) noreturn;

fn enterSupervisor(entry: usize) noreturn {
    const kernel_sp: usize = layout.qemu_virt.kernel_base + layout.qemu_virt.kernel_size - 16;
    drop_to_supervisor(entry, kernel_sp);
}

export fn handleMachineTrap(regs_ptr: *trap_regs.TrapRegs) void {
    const mcause = csr.read("mcause");
    const is_interrupt = (mcause >> 63) != 0;
    const code = mcause & 0xFF;

    if (!is_interrupt and code == 11) {
        handleSbiEcall(regs_ptr);
        return;
    }

    uart.print("keystone-zig SM: trap mcause=0x{x} mtval=0x{x} mepc=0x{x}\r\n", .{ mcause, csr.read("mtval"), csr.read("mepc") });
    while (true) csr.wfi();
}

fn handleSbiEcall(regs: *trap_regs.TrapRegs) void {
    const ext: u32 = @truncate(regs.a7);
    const fid: u32 = @truncate(regs.a6);

    if (ext != sbi.extension_id) {
        setRegError(regs, .not_implemented);
        regs.a1 = 0;
        regs.mepc += 4;
        return;
    }

    if (fid <= sbi.fid_range_deprecated) {
        setRegError(regs, .not_implemented);
        regs.mepc += 4;
        return;
    }

    if (fid <= sbi.fid_range_host and cpu.isEnclaveContext()) {
        setRegError(regs, .sbi_prohibited);
        regs.mepc += 4;
        return;
    }

    if (fid > sbi.fid_range_host and fid <= sbi.fid_range_enclave and !cpu.isEnclaveContext()) {
        setRegError(regs, .sbi_prohibited);
        regs.mepc += 4;
        return;
    }

    const err: sbi.Error = switch (@as(sbi.Fid, @enumFromInt(fid))) {
        .create_enclave => handleCreate(regs),
        .destroy_enclave => handleDestroy(regs),
        .run_enclave => handleRun(regs),
        .resume_enclave => handleResume(regs),
        .random => handleRandom(regs),
        .attest_enclave => handleAttest(regs),
        .get_sealing_key => handleSealingKey(regs),
        .stop_enclave => handleStop(regs),
        .exit_enclave => handleExit(regs),
        else => .not_implemented,
    };

    if (err == .success or @intFromEnum(err) >= 100_000) {
        // Non-context-switch returns advance mepc here.
        // run/resume/exit/stop modify frame and return via mret without +4.
        switch (@as(sbi.Fid, @enumFromInt(fid))) {
            .run_enclave, .resume_enclave, .exit_enclave, .stop_enclave => {},
            else => regs.mepc += 4,
        }
    }
}

fn setRegError(regs: *trap_regs.TrapRegs, err: sbi.Error) void {
    regs.a0 = @as(usize, @bitCast(@as(i64, @intFromEnum(err))));
}

fn handleCreate(regs: *trap_regs.TrapRegs) sbi.Error {
    var args: sbi.CreateArgs = undefined;
    const ce = enclave_ops.copyCreateArgs(regs.a0, &args);
    if (ce != .success) {
        setRegError(regs, ce);
        return ce;
    }
    var eid: u32 = undefined;
    const err = enclave_ops.createEnclave(&eid, args);
    setRegError(regs, err);
    regs.a1 = if (err == .success) eid else 0;
    if (err == .success) uart.print("keystone-zig SM: enclave {d}\r\n", .{eid});
    return err;
}

fn handleDestroy(regs: *trap_regs.TrapRegs) sbi.Error {
    const eid: u32 = @truncate(regs.a0);
    const err = enclave_ops.destroyEnclave(eid);
    setRegError(regs, err);
    return err;
}

fn handleRun(regs: *trap_regs.TrapRegs) sbi.Error {
    const eid: u32 = @truncate(regs.a0);
    const err = enclave_ops.runEnclave(regs, eid);
    if (err != .success) setRegError(regs, err);
    return err;
}

fn handleResume(regs: *trap_regs.TrapRegs) sbi.Error {
    const eid: u32 = @truncate(regs.a0);
    const err = enclave_ops.resumeEnclave(regs, eid);
    if (err != .success) setRegError(regs, err);
    return err;
}

fn handleExit(regs: *trap_regs.TrapRegs) sbi.Error {
    const retval = regs.a0;
    const err = enclave_ops.exitEnclave(regs, cpu.getEnclaveId());
    setRegError(regs, err);
    regs.a1 = retval;
    return err;
}

fn handleStop(regs: *trap_regs.TrapRegs) sbi.Error {
    const request = regs.a0;
    const err = enclave_ops.stopEnclave(regs, request, cpu.getEnclaveId());
    setRegError(regs, err);
    return err;
}

fn handleAttest(regs: *trap_regs.TrapRegs) sbi.Error {
    const err = enclave_ops.attestEnclave(regs.a0, regs.a1, regs.a2, cpu.getEnclaveId());
    setRegError(regs, err);
    return err;
}

fn handleSealingKey(regs: *trap_regs.TrapRegs) sbi.Error {
    const err = enclave_ops.getSealingKey(regs.a0, regs.a1, regs.a2, cpu.getEnclaveId());
    setRegError(regs, err);
    return err;
}

fn handleRandom(regs: *trap_regs.TrapRegs) sbi.Error {
    regs.a1 = crypto.platformRandom();
    regs.a0 = 0;
    return .success;
}

extern fn mTrapHandler() callconv(.naked) void;
