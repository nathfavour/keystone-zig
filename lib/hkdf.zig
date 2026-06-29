//! HKDF-SHA3-512 — port of `keystone/sm/src/hkdf_sha3_512/hkdf_sha3_512.c`.

const hmac_sha3 = @import("hmac_sha3.zig");

pub const HASH_LEN: usize = hmac_sha3.HASH_LEN;

fn divCeil(op1: usize, op2: usize) usize {
    return (op1 + op2 - 1) / op2;
}

pub fn extract(salt: ?[]const u8, ikm: []const u8, prk: *[HASH_LEN]u8) void {
    var null_salt: [HASH_LEN]u8 = .{0} ** HASH_LEN;
    const s = if (salt) |s0| if (s0.len > 0) s0 else null_salt[0..] else null_salt[0..];
    hmac_sha3.hmac(s, ikm, prk);
}

pub fn expand(prk: []const u8, info: []const u8, okm: []u8) i32 {
    if (prk.len < HASH_LEN) return -1;
    if (okm.len > 255 * HASH_LEN) return -1;

    const n = divCeil(okm.len, HASH_LEN);
    var t: [HASH_LEN]u8 = undefined;
    var i: u8 = 1;
    while (i <= n) : (i += 1) {
        var ctx: hmac_sha3.HmacSha3Ctx = undefined;
        hmac_sha3.init(&ctx, prk[0..HASH_LEN]);
        if (i > 1) hmac_sha3.update(&ctx, &t);
        hmac_sha3.update(&ctx, info);
        hmac_sha3.update(&ctx, &.{i});
        hmac_sha3.final(&ctx, &t);

        const offset = (@as(usize, i) - 1) * HASH_LEN;
        if (i < n) {
            @memcpy(okm[offset .. offset + HASH_LEN], &t);
        } else {
            @memcpy(okm[offset..], t[0 .. okm.len - offset]);
        }
    }
    return 0;
}

pub fn hkdfSha3_512(salt: ?[]const u8, ikm: []const u8, info: []const u8, okm: []u8) i32 {
    if (okm.len > 255 * HASH_LEN) return -1;
    var prk: [HASH_LEN]u8 = undefined;
    extract(salt, ikm, &prk);
    return expand(&prk, info, okm);
}
