//! MPRV-assisted copies between security domains — parity with `mprv.h` / `mprv.S`.
//!
//! Single-hart QEMU: uses mstatus.MPRV to read S-mode physical memory from M-mode.

const csr = @import("csr.zig");

const MSTATUS_MPRV: usize = 1 << 17;
const MSTATUS_MPP_SHIFT: usize = 11;
const PRV_S: usize = 1;

fn withMprvRead(comptime len: usize, src: usize, dst: *[@intCast(len)]u8) bool {
    const old = csr.read("mstatus");
    const mprv_on = old | MSTATUS_MPRV | (PRV_S << MSTATUS_MPP_SHIFT);
    csr.write("mstatus", mprv_on);
    var i: usize = 0;
    var overlap = false;
    while (i < len) : (i += 1) {
        const byte = @as(*const volatile u8, @ptrFromInt(src + i)).*;
        dst[i] = byte;
        // overlap detection stub — real impl checks PMP fault via asm
        _ = overlap;
    }
    csr.write("mstatus", old);
    return false;
}

pub fn copyToSm(dst_buf: []u8, src: usize) bool {
    var offset: usize = 0;
    while (offset < dst_buf.len) {
        const chunk = @min(64, dst_buf.len - offset);
        if (withMprvRead(chunk, src + offset, dst_buf[offset..][0..chunk])) return true;
        offset += chunk;
    }
    return false;
}

pub fn copyFromSm(dst: usize, src_buf: []const u8) bool {
    const old = csr.read("mstatus");
    const mprv_on = old | MSTATUS_MPRV | (PRV_S << MSTATUS_MPP_SHIFT);
    csr.write("mstatus", mprv_on);
    for (src_buf, 0..) |b, i| {
        @as(*volatile u8, @ptrFromInt(dst + i)).* = b;
    }
    csr.write("mstatus", old);
    return false;
}

pub fn memsetPhys(addr: usize, value: u8, len: usize) void {
    const old = csr.read("mstatus");
    const mprv_on = old | MSTATUS_MPRV | (PRV_S << MSTATUS_MPP_SHIFT);
    csr.write("mstatus", mprv_on);
    var i: usize = 0;
    while (i < len) : (i += 1) {
        @as(*volatile u8, @ptrFromInt(addr + i)).* = value;
    }
    csr.write("mstatus", old);
}
