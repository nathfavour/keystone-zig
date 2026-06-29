//! Keystone-Zig shared library — clean-room RISC-V TEE primitives.
//!
//! Design reference: Berkeley Keystone enclave model (PMP + SM + SBI).
//! Implementation: native Zig, freestanding, no C/C++ Keystone dependency.

pub const csr = @import("csr.zig");
pub const gpr = @import("gpr.zig");
pub const pmp = @import("pmp.zig");
pub const sbi = @import("sbi.zig");
pub const enclave = @import("enclave.zig");
pub const layout = @import("layout.zig");
pub const uart = @import("uart.zig");

test {
    _ = csr;
    _ = pmp;
    _ = sbi;
    _ = enclave;
    _ = layout;
    @import("std").testing.refAllDecls(@This());
}
