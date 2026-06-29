//! QEMU virt UART (16550) — minimal polled TX for early SM debug.

const std = @import("std");
const layout = @import("layout.zig");

const uart_base = layout.qemu_virt.uart_base;
const THR: *volatile u8 = @ptrFromInt(uart_base);
const LSR: *volatile u8 = @ptrFromInt(uart_base + 5);
const lsr_thre: u8 = 1 << 5;

pub fn putc(c: u8) void {
    while ((LSR.* & lsr_thre) == 0) {}
    THR.* = c;
}

pub fn write(bytes: []const u8) void {
    for (bytes) |b| putc(b);
}

pub fn print(comptime fmt: []const u8, args: anytype) void {
    var buf: [128]u8 = undefined;
    const formatted = std.fmt.bufPrint(&buf, fmt, args) catch return;
    write(formatted);
}
