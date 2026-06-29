//! HMAC-SHA3-512 — port of `keystone/sm/src/hmac_sha3/hmac_sha3.c`.

const sha3 = @import("sha3.zig");

pub const HASH_LEN: usize = 64;
pub const BLOCK_LEN: usize = 72;

pub const HmacSha3Ctx = struct {
    sha3_ctx: sha3.Sha3Ctx = .{},
    key: [BLOCK_LEN]u8 = .{0} ** BLOCK_LEN,
};

fn prepareKey(key: []const u8, out: *[BLOCK_LEN]u8) void {
    if (key.len > BLOCK_LEN) {
        var digest: [HASH_LEN]u8 = undefined;
        sha3.hash(key, &digest, HASH_LEN);
        @memcpy(out[0..HASH_LEN], &digest);
        @memset(out[HASH_LEN..], 0);
    } else {
        @memcpy(out[0..key.len], key);
        @memset(out[key.len..], 0);
    }
}

pub fn init(ctx: *HmacSha3Ctx, key: []const u8) void {
    prepareKey(key, &ctx.key);
    var ipad: [BLOCK_LEN]u8 = undefined;
    for (ctx.key, 0..) |b, i| ipad[i] = b ^ 0x36;
    sha3.init(&ctx.sha3_ctx, HASH_LEN);
    sha3.update(&ctx.sha3_ctx, &ipad);
}

pub fn update(ctx: *HmacSha3Ctx, text: []const u8) void {
    if (text.len > 0) sha3.update(&ctx.sha3_ctx, text);
}

pub fn final(ctx: *HmacSha3Ctx, out: *[HASH_LEN]u8) void {
    var inner_hash: [HASH_LEN]u8 = undefined;
    sha3.final(&ctx.sha3_ctx, &inner_hash);

    var opad: [BLOCK_LEN]u8 = undefined;
    for (ctx.key, 0..) |b, i| opad[i] = b ^ 0x5c;

    var outer: sha3.Sha3Ctx = undefined;
    sha3.init(&outer, HASH_LEN);
    sha3.update(&outer, &opad);
    sha3.update(&outer, &inner_hash);
    sha3.final(&outer, out);
}

pub fn hmac(key: []const u8, text: []const u8, out: *[HASH_LEN]u8) void {
    var ctx: HmacSha3Ctx = undefined;
    init(&ctx, key);
    update(&ctx, text);
    final(&ctx, out);
}
