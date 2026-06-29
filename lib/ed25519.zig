// SPDX-FileCopyrightText: 2026 2026 Nath Favour
//
// SPDX-License-Identifier: AGPL-3.0-or-later

//! Ed25519 signing (SHA3-512) — port of `keystone/sm/src/ed25519/sign.c`.

const std = @import("std");
const sha3 = @import("sha3.zig");
const sc = @import("ed25519/sc.zig");
const ge = @import("ed25519/ge.zig");

/// Sign `message` with Ed25519 using SHA3-512 (Keystone SM variant).
/// `private_key` is 64 bytes (32-byte seed + 32-byte public key).
/// Writes 64-byte signature to `sig` (R || S).
pub fn sign(
    sig: []u8,
    message: []const u8,
    public_key: *const [32]u8,
    private_key: *const [64]u8,
) void {
    var hash: sha3.Sha3Ctx = undefined;
    var hram: [64]u8 = undefined;
    var r: [64]u8 = undefined;
    var R: ge.GeP3 = undefined;

    sha3.init(&hash, 64);
    sha3.update(&hash, private_key[32..]);
    sha3.update(&hash, message);
    sha3.final(&hash, &r);

    sc.sc_reduce(&r);
    ge.ge_scalarmult_base(&R, r[0..32]);
    ge.ge_p3_tobytes(sig[0..32], &R);

    sha3.init(&hash, 64);
    sha3.update(&hash, sig[0..32]);
    sha3.update(&hash, public_key);
    sha3.update(&hash, message);
    sha3.final(&hash, &hram);

    sc.sc_reduce(&hram);
    sc.sc_muladd(sig[32..64], hram[0..32], private_key[0..32], r[0..32]);
}

test "sign smoke" {
    var sig: [64]u8 = undefined;
    const msg = "keystone";
    const pk: [32]u8 = .{0x01} ** 32;
    const sk: [64]u8 = .{0x02} ** 64;
    sign(&sig, msg, &pk, &sk);
    // R and S should be non-trivial for non-degenerate inputs.
    try std.testing.expect(sig[0] != 0 or sig[32] != 0);
}

test {
    _ = sign;
}
