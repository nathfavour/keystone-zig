//! RISC-V Control and Status Register helpers for M-mode.

pub const Mstatus = packed struct(u64) {
    uie: u1 = 0,
    sie: u1 = 0,
    _reserved0: u1 = 0,
    mie: u1 = 0,
    _reserved1: u3 = 0,
    mpie: u1 = 0,
    _reserved2: u1 = 0,
    mpp: u2 = 0,
    _reserved3: u9 = 0,
    mprv: u1 = 0,
    _reserved4: u43 = 0,

    pub const mpp_m: u2 = 3;
    pub const mpp_s: u2 = 1;
    pub const mpp_u: u2 = 0;
};

pub inline fn read(comptime name: []const u8) usize {
    return asm ("csrr %[ret], " ++ name
        : [ret] "=r" (-> usize),
    );
}

pub inline fn write(comptime name: []const u8, value: usize) void {
    asm volatile ("csrw " ++ name ++ ", %[val]"
        :
        : [val] "r" (value),
    );
}

pub inline fn set(comptime name: []const u8, value: usize) void {
    asm volatile ("csrs " ++ name ++ ", %[val]"
        :
        : [val] "r" (value),
    );
}

pub inline fn clear(comptime name: []const u8, value: usize) void {
    asm volatile ("csrc " ++ name ++ ", %[val]"
        :
        : [val] "r" (value),
    );
}

pub inline fn mret() noreturn {
    asm volatile ("mret");
    unreachable;
}

pub inline fn sret() noreturn {
    asm volatile ("sret");
    unreachable;
}

pub inline fn wfi() void {
    asm volatile ("wfi");
}

pub inline fn fence() void {
    asm volatile ("fence");
}

pub inline fn sfence_vma() void {
    asm volatile ("sfence.vma");
}
