// SPDX-FileCopyrightText: 2026 2026 Nath Favour
//
// SPDX-License-Identifier: AGPL-3.0-or-later

//! SHA-3 (Keccak) — clean-room port of `keystone/sm/src/sha3/sha3.c`.

const std = @import("std");

pub const KECCAKF_ROUNDS: usize = 24;

pub const Sha3Ctx = struct {
    st: [200]u8 align(8) = .{0} ** 200,
    pt: i32 = 0,
    rsiz: i32 = 0,
    mdlen: i32 = 0,

    fn q(self: *Sha3Ctx) *[25]u64 {
        return @ptrCast(&self.st);
    }
};

fn rotl64(x: u64, y: u32) u64 {
    return std.math.rotl(u64, x, @as(u6, @truncate(y & 63)));
}

pub fn keccakf(st: *[25]u64) void {
    const keccakf_rndc: [24]u64 = .{
        0x0000000000000001, 0x0000000000008082, 0x800000000000808a,
        0x8000000080008000, 0x000000000000808b, 0x0000000080000001,
        0x8000000080008081, 0x8000000000008009, 0x000000000000008a,
        0x0000000000000088, 0x0000000080008009, 0x000000008000000a,
        0x000000008000808b, 0x800000000000008b, 0x8000000000008089,
        0x8000000000008003, 0x8000000000008002, 0x8000000000000080,
        0x000000000000800a, 0x800000008000000a, 0x8000000080008081,
        0x8000000000008080, 0x0000000080000001, 0x8000000080008008,
    };
    const keccakf_rotc: [24]u32 = .{
        1,  3,  6,  10, 15, 21, 28, 36, 45, 55, 2,  14,
        27, 41, 56, 8,  25, 43, 62, 18, 39, 61, 20, 44,
    };
    const keccakf_piln: [24]usize = .{
        10, 7,  11, 17, 18, 3, 5,  16, 8,  21, 24, 4,
        15, 23, 19, 13, 12, 2, 20, 14, 22, 9,  6,  1,
    };

    var r: usize = 0;
    while (r < KECCAKF_ROUNDS) : (r += 1) {
        var bc: [5]u64 = undefined;
        var i: usize = 0;
        while (i < 5) : (i += 1) {
            bc[i] = st[i] ^ st[i + 5] ^ st[i + 10] ^ st[i + 15] ^ st[i + 20];
        }
        i = 0;
        while (i < 5) : (i += 1) {
            const t = bc[(i + 4) % 5] ^ rotl64(bc[(i + 1) % 5], 1);
            var j: usize = 0;
            while (j < 25) : (j += 5) st[j + i] ^= t;
        }
        var t = st[1];
        i = 0;
        while (i < 24) : (i += 1) {
            const j = keccakf_piln[i];
            bc[0] = st[j];
            st[j] = rotl64(t, keccakf_rotc[i]);
            t = bc[0];
        }
        var j: usize = 0;
        while (j < 25) : (j += 5) {
            i = 0;
            while (i < 5) : (i += 1) bc[i] = st[j + i];
            i = 0;
            while (i < 5) : (i += 1) st[j + i] ^= (~bc[(i + 1) % 5]) & bc[(i + 2) % 5];
        }
        st[0] ^= keccakf_rndc[r];
    }
}

pub fn init(ctx: *Sha3Ctx, mdlen: i32) void {
    @memset(&ctx.st, 0);
    ctx.mdlen = mdlen;
    ctx.rsiz = 200 - 2 * mdlen;
    ctx.pt = 0;
}

pub fn update(ctx: *Sha3Ctx, data: []const u8) void {
    var j = ctx.pt;
    for (data) |byte| {
        ctx.st[@intCast(j)] ^= byte;
        j += 1;
        if (j >= ctx.rsiz) {
            keccakf(ctx.q());
            j = 0;
        }
    }
    ctx.pt = j;
}

pub fn final(ctx: *Sha3Ctx, md: []u8) void {
    ctx.st[@intCast(ctx.pt)] ^= 0x06;
    ctx.st[@intCast(ctx.rsiz - 1)] ^= 0x80;
    keccakf(ctx.q());
    const out_len = @min(md.len, @as(usize, @intCast(ctx.mdlen)));
    @memcpy(md[0..out_len], ctx.st[0..out_len]);
}

pub fn hash(in_bytes: []const u8, md: []u8, mdlen: i32) void {
    var ctx: Sha3Ctx = undefined;
    init(&ctx, mdlen);
    update(&ctx, in_bytes);
    final(&ctx, md);
}

test "sha3-512 empty" {
    var out: [64]u8 = undefined;
    hash(&.{}, &out, 64);
    // Matches `keystone/sm/src/sha3/sha3.c` (differs from NIST FIPS 202 test vectors).
    try std.testing.expect(out[0] == 0xa6);
}
