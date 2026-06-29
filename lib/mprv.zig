// SPDX-FileCopyrightText: 2026 2026 Nath Favour
//
// SPDX-License-Identifier: AGPL-3.0-or-later

//! MPRV-assisted copies between security domains — parity with `mprv.h`.

const csr = @import("csr.zig");
const std = @import("std");

const MSTATUS_MPRV: usize = 1 << 17;
const MSTATUS_MPP_SHIFT: usize = 11;
const PRV_S: usize = 1;
const REG_BYTES: usize = @sizeOf(usize);
const MPRV_BLOCK: usize = REG_BYTES * 8;

extern fn copy1_from_sm(dst: usize, src: usize) callconv(.c) c_int;
extern fn copy_word_from_sm(dst: usize, src: usize) callconv(.c) c_int;
extern fn copy_block_from_sm(dst: usize, src: usize) callconv(.c) c_int;
extern fn copy1_to_sm(dst: usize, src: usize) callconv(.c) c_int;
extern fn copy_word_to_sm(dst: usize, src: usize) callconv(.c) c_int;
extern fn copy_block_to_sm(dst: usize, src: usize) callconv(.c) c_int;

pub fn copyToSm(dst_buf: []u8, src: usize) bool {
    var src_ptr = src;
    var dst_ptr = @intFromPtr(dst_buf.ptr);
    var len = dst_buf.len;

    if ((src_ptr % REG_BYTES) == 0 and (dst_ptr % REG_BYTES) == 0) {
        while (len >= MPRV_BLOCK) {
            if (copy_block_to_sm(dst_ptr, src_ptr) != 0) return true;
            src_ptr += MPRV_BLOCK;
            dst_ptr += MPRV_BLOCK;
            len -= MPRV_BLOCK;
        }
        while (len >= REG_BYTES) {
            if (copy_word_to_sm(dst_ptr, src_ptr) != 0) return true;
            src_ptr += REG_BYTES;
            dst_ptr += REG_BYTES;
            len -= REG_BYTES;
        }
    }

    while (len > 0) {
        if (copy1_to_sm(dst_ptr, src_ptr) != 0) return true;
        src_ptr += 1;
        dst_ptr += 1;
        len -= 1;
    }
    return false;
}

pub fn copyFromSm(dst: usize, src_buf: []const u8) bool {
    var src_ptr = @intFromPtr(src_buf.ptr);
    var dst_ptr = dst;
    var len = src_buf.len;

    if ((src_ptr % REG_BYTES) == 0 and (dst_ptr % REG_BYTES) == 0) {
        while (len >= MPRV_BLOCK) {
            if (copy_block_from_sm(dst_ptr, src_ptr) != 0) return true;
            src_ptr += MPRV_BLOCK;
            dst_ptr += MPRV_BLOCK;
            len -= MPRV_BLOCK;
        }
        while (len >= REG_BYTES) {
            if (copy_word_from_sm(dst_ptr, src_ptr) != 0) return true;
            src_ptr += REG_BYTES;
            dst_ptr += REG_BYTES;
            len -= REG_BYTES;
        }
    }

    while (len > 0) {
        if (copy1_from_sm(dst_ptr, src_ptr) != 0) return true;
        src_ptr += 1;
        dst_ptr += 1;
        len -= 1;
    }
    return false;
}

pub fn memsetPhys(addr: usize, value: u8, len: usize) void {
    if (len == 0) return;
    const dst = @as([*]volatile u8, @ptrFromInt(addr))[0..len];
    @memset(dst, value);
}
