//! General-purpose register access from inline assembly (not CSRs).

pub inline fn read(comptime reg: []const u8) usize {
    return asm ("mv %[ret], " ++ reg
        : [ret] "=r" (-> usize),
    );
}

pub inline fn write(comptime reg: []const u8, value: usize) void {
    asm volatile ("mv " ++ reg ++ ", %[val]"
        :
        : [val] "r" (value),
    );
}
