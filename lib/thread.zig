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
    prev_state: trap_regs.TrapRegs = .{
        .zero = 0,
        .ra = 0,
        .sp = 0,
        .gp = 0,
        .tp = 0,
        .t0 = 0,
        .t1 = 0,
        .t2 = 0,
        .s0 = 0,
        .s1 = 0,
        .a0 = 0,
        .a1 = 0,
        .a2 = 0,
        .a3 = 0,
        .a4 = 0,
        .a5 = 0,
        .a6 = 0,
        .a7 = 0,
        .s2 = 0,
        .s3 = 0,
        .s4 = 0,
        .s5 = 0,
        .s6 = 0,
        .s7 = 0,
        .s8 = 0,
        .s9 = 0,
        .s10 = 0,
        .s11 = 0,
        .t3 = 0,
        .t4 = 0,
        .t5 = 0,
        .t6 = 0,
        .mepc = 0,
        .mstatus = 0,
    },
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

    tmp = csr.read("sstatus");
    csr.write("sstatus", csrs.sstatus);
    csrs.sstatus = tmp;

    tmp = csr.read("sie");
    csr.write("sie", csrs.sie);
    csrs.sie = tmp;

    tmp = csr.read("stvec");
    csr.write("stvec", csrs.stvec);
    csrs.stvec = tmp;

    tmp = csr.read("scounteren");
    csr.write("scounteren", csrs.scounteren);
    csrs.scounteren = tmp;

    tmp = csr.read("sscratch");
    csr.write("sscratch", csrs.sscratch);
    csrs.sscratch = tmp;

    tmp = csr.read("sepc");
    csr.write("sepc", csrs.sepc);
    csrs.sepc = tmp;

    tmp = csr.read("scause");
    csr.write("scause", csrs.scause);
    csrs.scause = tmp;

    tmp = csr.read("stval");
    csr.write("stval", csrs.sbadaddr);
    csrs.sbadaddr = tmp;

    tmp = csr.read("sip");
    csr.write("sip", csrs.sip);
    csrs.sip = tmp;

    tmp = csr.read("satp");
    csr.write("satp", csrs.satp);
    csrs.satp = tmp;
}

pub fn swapPrevState(thread: *ThreadState, regs: *trap_regs.TrapRegs, return_on_resume: bool) void {
    const prev = regs.asWords();
    const saved = thread.prev_state.asWords();
    var i: usize = 0;
    while (i < 32) : (i += 1) {
        const t = saved[i];
        saved[i] = prev[i];
        prev[i] = t;
    }
    saved[0] = if (return_on_resume) 1 else 0;
    swapPrevSmodeCsrs(thread);
}

pub fn cleanSmodeCsrs(thread: *ThreadState) void {
    thread.prev_csrs = .{};
    thread.prev_csrs.scounteren = csr.read("scounteren");
}

pub fn cleanState(thread: *ThreadState) void {
    thread.prev_state = .{
        .zero = 0,
        .ra = 0,
        .sp = 0,
        .gp = 0,
        .tp = 0,
        .t0 = 0,
        .t1 = 0,
        .t2 = 0,
        .s0 = 0,
        .s1 = 0,
        .a0 = 0,
        .a1 = 0,
        .a2 = 0,
        .a3 = 0,
        .a4 = 0,
        .a5 = 0,
        .a6 = 0,
        .a7 = 0,
        .s2 = 0,
        .s3 = 0,
        .s4 = 0,
        .s5 = 0,
        .s6 = 0,
        .s7 = 0,
        .s8 = 0,
        .s9 = 0,
        .s10 = 0,
        .s11 = 0,
        .t3 = 0,
        .t4 = 0,
        .t5 = 0,
        .t6 = 0,
        .mepc = 0,
        .mstatus = 0,
    };
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
