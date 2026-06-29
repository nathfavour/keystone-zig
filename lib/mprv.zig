// SPDX-FileCopyrightText: 2026 2026 Nath Favour
//
// SPDX-License-Identifier: AGPL-3.0-or-later

//! MPRV-assisted copies between security domains — parity with `mprv.h`.

const csr = @import("csr.zig");

const MSTATUS_MPRV: usize = 1 << 17;
const MSTATUS_MPP_SHIFT: usize = 11;
const PRV_S: usize = 1;

pub fn copyToSm(dst_buf: []u8, src: usize) bool {
    const old = csr.read("mstatus");
    csr.write("mstatus", old | MSTATUS_MPRV | (PRV_S << MSTATUS_MPP_SHIFT));
  for (dst_buf, 0..) |*d, i| {
        d.* = @as(*const volatile u8, @ptrFromInt(src + i)).*;
    }
    csr.write("mstatus", old);
    return false;
}

pub fn copyFromSm(dst: usize, src_buf: []const u8) bool {
    const old = csr.read("mstatus");
    csr.write("mstatus", old | MSTATUS_MPRV | (PRV_S << MSTATUS_MPP_SHIFT));
    for (src_buf, 0..) |b, i| {
        @as(*volatile u8, @ptrFromInt(dst + i)).* = b;
    }
    csr.write("mstatus", old);
    return false;
}

pub fn memsetPhys(addr: usize, value: u8, len: usize) void {
    if (len == 0) return;
    const dst = @as([*]u8, @ptrFromInt(addr))[0..len];
    @memset(dst, value);
}
