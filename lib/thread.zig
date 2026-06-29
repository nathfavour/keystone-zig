//! Enclave thread state and host<->enclave context swap — parity with `thread.c`.

const trap_regs = @import("trap_regs.zig");
const csr = @import("csr.zig");

pub const SmCsrs = struct {
    sstatus: usize = 0,
    sedeleg: usize = 0,
    sideleg: usize = 0,
    sie: usize = 0,
    stvec: usize = 0,
    scounteren: usize = 0,
    sscratch: usize = 0,
    sepc: usize = 0,
    scause: usize = 0,
    sbadaddr: usize = 0,
    sip: usize = 0,
    satp: usize = 0,
};

pub const ThreadState = struct {
    prev_mpp: i32 = -1,
    prev_mepc: usize = 0,
    prev_mstatus: usize = 0,
    prev_csrs: SmCsrs = .{},
    prev_state: trap_regs.TrapRegs = .{ .zero = 0 } ** 1,
};

pub fn swapPrevMstatus(thread: *ThreadState, regs: *trap_regs.TrapRegs, current_mstatus: usize) void {
    const mask = trap_regs.mstatus_swap_mask;
    const tmp = thread.prev_mstatus;
    thread.prev_mstatus = (current_mstatus & ~mask) | (regs.mstatus & mask);
    regs.mstatus = (current_mstatus & ~mask) | (tmp & mask);
}

pub fn swapPrevMepc(thread: *ThreadState, regs: *trap_regs.TrapRegs, current_mepc: usize) void {
    const tmp = thread.prev_mepc;
    thread.prev_mepc = current_mepc;
    regs.mepc = tmp;
}

pub fn swapPrevSmodeCsrs(thread: *ThreadState) void {
    const csrs = &thread.prev_csrs;
    var tmp: usize = undefined;

    inline for (.{
        .{ "sstatus", &csrs.sstatus },
        .{ "sie", &csrs.sie },
        .{ "stvec", &csrs.stvec },
        .{ "scounteren", &csrs.scounteren },
        .{ "sscratch", &csrs.sscratch },
        .{ "sepc", &csrs.sepc },
        .{ "scause", &csrs.scause },
        .{ "stval", &csrs.sbadaddr },
        .{ "sip", &csrs.sip },
        .{ "satp", &csrs.satp },
    }) |pair| {
        tmp = csr.read(pair[0]);
        csr.write(pair[0], pair[1].*);
        pair[1].* = tmp;
    }
}

pub fn swapPrevState(thread: *ThreadState, regs: *trap_regs.TrapRegs, return_on_resume: bool) void {
    const prev = regs.asWords();
    const saved = thread.prev_state.asWords();
    var i: usize = 0;
    while (i < 32) : (i += 1) {
        const tmp = saved[i];
        saved[i] = prev[i];
        prev[i] = tmp;
    }
    saved[0] = if (return_on_resume) 1 else 0;
    swapPrevSmodeCsrs(thread);
}

pub fn cleanSmodeCsrs(thread: *ThreadState) void {
    thread.prev_csrs = .{};
    thread.prev_csrs.scounteren = csr.read("scounteren");
}

pub fn cleanState(thread: *ThreadState) void {
    thread.prev_state = .{ .zero = 0 } ** 1;
    thread.prev_mpp = -1;
    cleanSmodeCsrs(thread);
}

pub fn switchVectorEnclave() void {
    csr.write("mtvec", @intFromPtr(&trapVectorEnclave));
}

pub fn switchVectorHost() void {
    csr.write("mtvec", @intFromPtr(&mTrapHandler));
}

extern fn trapVectorEnclave() callconv(.naked) void;
extern fn mTrapHandler() callconv(.naked) void;
