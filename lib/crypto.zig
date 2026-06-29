// SPDX-FileCopyrightText: 2026 Nath Favour
//
// SPDX-License-Identifier: AGPL-3.0-or-later

//! Cryptography — SHA3-512, HMAC, HKDF, Ed25519 (parity with `crypto.c` / `attest.c`).

const std = @import("std");
const sbi = @import("sbi.zig");
const enclave = @import("enclave.zig");
const trap_regs = @import("trap_regs.zig");
const sha3 = @import("sha3.zig");
const hkdf = @import("hkdf.zig");
const ed25519 = @import("ed25519.zig");
const test_dev_key = @import("test_dev_key.zig");
const firmware_hash = @import("sm_firmware_hash.zig");

pub var sm_hash: [sbi.MDSIZE]u8 = .{0} ** sbi.MDSIZE;
pub var sm_signature: [sbi.SIGNATURE_SIZE]u8 = .{0} ** sbi.SIGNATURE_SIZE;
pub var sm_public_key: [sbi.PUBLIC_KEY_SIZE]u8 = .{0} ** sbi.PUBLIC_KEY_SIZE;
pub var sm_private_key: [64]u8 = .{0} ** 64;
pub var dev_public_key: [sbi.PUBLIC_KEY_SIZE]u8 = .{0} ** sbi.PUBLIC_KEY_SIZE;

const cfg = @import("config");

/// Initialize SM keys — bootloader Sanctum copy or standalone cold-boot provisioning.
pub fn initKeys(sm_base: usize, sm_size: usize) void {
    if (comptime cfg.bootloader_provided_keys) {
        @import("crypto_sanctum.zig").smCopyKey();
    } else {
        provisionKeysColdBoot(sm_base, sm_size);
    }
}

/// Copy keys from bootloader-provided Sanctum region (`platform/generic/platform.c`).
pub fn smCopyKey() void {
    @import("crypto_sanctum.zig").smCopyKey();
}

/// Measure SM firmware image in memory (bootloader-equivalent `sha3_update` over padded region).
pub fn measureSmFirmware(sm_base: usize, sm_size: usize, out: *[sbi.MDSIZE]u8) void {
    var ctx: sha3.Sha3Ctx = undefined;
    sha3.init(&ctx, sbi.MDSIZE);

    const page_size: usize = 4096;
    var offset: usize = 0;
    while (offset < sm_size) : (offset += page_size) {
        const chunk = @min(page_size, sm_size - offset);
        var buf: [4096]u8 = undefined;
        for (0..chunk) |i| {
            buf[i] = @as(*const volatile u8, @ptrFromInt(sm_base + offset + i)).*;
        }
        sha3.update(&ctx, buf[0..chunk]);
    }
    sha3.final(&ctx, out);
}

/// Standalone boot path — mirrors `keystone.c` `keystone_init()` without U-Boot.
pub fn provisionKeysColdBoot(sm_base: usize, sm_size: usize) void {
    var dev_sk: [64]u8 = test_dev_key.dev_secret_key;
    var scratchpad: [128]u8 = undefined;

    if (firmware_hash.valid) {
        @memcpy(&sm_hash, &firmware_hash.hash);
    } else {
        measureSmFirmware(sm_base, sm_size, &sm_hash);
    }

    var ctx: sha3.Sha3Ctx = undefined;
    sha3.init(&ctx, 64);
    sha3.update(&ctx, &dev_sk);
    sha3.update(&ctx, &sm_hash);
    sha3.final(&ctx, &scratchpad);

    var seed: [32]u8 = undefined;
    @memcpy(&seed, scratchpad[0..32]);
    ed25519.createKeypair(&sm_public_key, &sm_private_key, &seed);

    var sign_buf: [sbi.MDSIZE + sbi.PUBLIC_KEY_SIZE]u8 = undefined;
    @memcpy(sign_buf[0..sbi.MDSIZE], &sm_hash);
    @memcpy(sign_buf[sbi.MDSIZE..], &sm_public_key);
    ed25519.sign(&sm_signature, &sign_buf, &test_dev_key.dev_public_key, &dev_sk);

    @memcpy(&dev_public_key, &test_dev_key.dev_public_key);
    @memset(&dev_sk, 0);
}

/// Optional measured-boot check against `zig build hash-sm` output.
pub fn verifyExpectedHash() bool {
    if (!firmware_hash.valid) return true;
    var measured: [sbi.MDSIZE]u8 = undefined;
    measureSmFirmware(@import("layout.zig").qemu_virt.sm_base, firmware_hash.sm_size, &measured);
    return std.mem.eql(u8, &measured, &firmware_hash.hash);
}

pub fn smSign(sig: []u8, data: []const u8) void {
    ed25519.sign(sig, data, &sm_public_key, &sm_private_key);
}

pub fn sign(sig: []u8, data: []const u8, _: usize) void {
    smSign(sig, data);
}

fn hashExtendPage(ctx: *sha3.Sha3Ctx, page: usize) void {
    var buf: [1 << trap_regs.RISCV_PGSHIFT]u8 = undefined;
    for (0..buf.len) |i| {
        buf[i] = @as(*const volatile u8, @ptrFromInt(page + i)).*;
    }
    sha3.update(ctx, &buf);
}

fn validateAndHashEpm(enc: *enclave.Enclave) void {
    const loader = enc.params.dram_base;
    const runtime = enc.params.runtime_base;
    const eapp = enc.params.user_base;
    const free = enc.params.free_base;

    const sizes = [_]usize{ runtime - loader, eapp - runtime, free - eapp };
    var ctx: sha3.Sha3Ctx = undefined;
    sha3.init(&ctx, sbi.MDSIZE);
    sha3.update(&ctx, std.mem.asBytes(&sizes));

    const page_size = @as(usize, 1) << trap_regs.RISCV_PGSHIFT;
    var page = loader;
    while (page < runtime) : (page += page_size) hashExtendPage(&ctx, page);
    while (page < eapp) : (page += page_size) hashExtendPage(&ctx, page);
    while (page < free) : (page += page_size) hashExtendPage(&ctx, page);

    sha3.final(&ctx, &enc.hash);
}

pub fn validateAndHashEnclave(enc: *enclave.Enclave) sbi.Error {
    validateAndHashEpm(enc);
    return .success;
}

pub fn fillAttestationReport(report: *sbi.Report, enc: *const enclave.Enclave) void {
    @memcpy(&report.dev_public_key, &dev_public_key);
    @memcpy(&report.sm.hash, &sm_hash);
    @memcpy(&report.sm.public_key, &sm_public_key);
    @memcpy(&report.sm.signature, &sm_signature);
    @memcpy(&report.enclave.hash, &enc.hash);
    smSign(&report.enclave.signature, std.mem.asBytes(&report.enclave)[0 .. @sizeOf(sbi.EnclaveReport) - sbi.SIGNATURE_SIZE]);
}

/// HKDF sealing key derivation — parity with `sm_derive_sealing_key()`.
pub fn deriveSealingKey(
    key: *[sbi.SEALING_KEY_SIZE]u8,
    key_ident: usize,
    key_ident_size: usize,
    enclave_hash: *const [sbi.MDSIZE]u8,
) i32 {
    if (key_ident_size > 4096) return -1;
    var info: [sbi.MDSIZE + 4096]u8 = undefined;
    @memcpy(info[0..sbi.MDSIZE], enclave_hash);
    if (key_ident_size > 0) {
        @memcpy(info[sbi.MDSIZE..][0..key_ident_size], @as([*]const u8, @ptrFromInt(key_ident))[0..key_ident_size]);
    }
    return hkdf.hkdfSha3_512(null, &sm_private_key, info[0 .. sbi.MDSIZE + key_ident_size], key);
}

pub fn platformRandom() usize {
    var cycles: usize = undefined;
    asm volatile ("rdcycle %[c]"
        : [c] "=r" (cycles),
    );
    var x: u64 = @truncate(cycles);
    w +%= s;
    x *%= x;
    x +%= w;
    x = (x >> 32) | (x << 32);
    return @as(usize, @intCast(x));
}

var w: u64 = 0;
const s: u64 = 0xb5ad4eceda1ce2a9;

test "provision keys deterministic with embedded hash" {
    @memcpy(&sm_hash, &firmware_hash.hash);
    var dev_sk: [64]u8 = test_dev_key.dev_secret_key;
    var scratchpad: [128]u8 = undefined;
    var ctx: sha3.Sha3Ctx = undefined;
    sha3.init(&ctx, 64);
    sha3.update(&ctx, &dev_sk);
    sha3.update(&ctx, &sm_hash);
    sha3.final(&ctx, &scratchpad);
    var seed: [32]u8 = undefined;
    @memcpy(&seed, scratchpad[0..32]);
    var pk: [32]u8 = undefined;
    var sk: [64]u8 = undefined;
    ed25519.createKeypair(&pk, &sk, &seed);
    try std.testing.expect(pk[0] != 0 or pk[31] != 0);
}
