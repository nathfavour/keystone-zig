//! Platform memory layout — comptime-validated PMP map for QEMU virt / clarigggz.

const pmp = @import("pmp.zig");

pub const qemu_virt = struct {
    pub const sm_base: usize = 0x8000_0000;
    pub const sm_size: usize = 0x0010_0000;

    pub const uart_base: usize = 0x1000_0000;
    pub const uart_size: usize = 0x1000;

    pub const kernel_base: usize = 0x8020_0000;
    pub const kernel_entry: usize = kernel_base; // boot.S _start at image base
    pub const kernel_size: usize = 0x0100_0000;

    pub const enclave_pool_base: usize = 0x9000_0000;
    pub const enclave_pool_size: usize = 0x1000_0000;

    /// Boot-time PMP whitelist. SM owns low RAM + MMIO; kernel gets its DRAM slice.
    pub const boot_map = pmp.Map{
        .regions = &.{
            .{ .name = "uart", .base = uart_base, .size = uart_size, .perm = .rw, .mode = .napot },
        },
    };

    comptime {
        pmp.Map.validate(boot_map);
    }
};

pub const hardware = @import("config").hardware;

pub fn activeLayout() type {
    if (comptime std.mem.eql(u8, hardware, "qemu_virt")) {
        return qemu_virt;
    }
    return qemu_virt; // generic falls back to virt profile for now
}

const std = @import("std");
