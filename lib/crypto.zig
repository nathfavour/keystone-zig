//! Cryptography stubs — phase 3 full SHA3/Ed25519 parity with `crypto.c` / `attest.c`.

const std = @import("std");
const sbi = @import("sbi.zig");
const enclave = @import("enclave.zig");
const trap_regs = @import("trap_regs.zig");
const mprv = @import("mprv.zig");

pub var sm_hash: [sbi.MDSIZE]u8 = .{0} ** sbi.MDSIZE;
pub var sm_signature: [sbi.SIGNATURE_SIZE]u8 = .{0} ** sbi.SIGNATURE_SIZE;
pub var sm_public_key: [sbi.PUBLIC_KEY_SIZE]u8 = .{0} ** sbi.PUBLIC_KEY_SIZE;
pub var sm_private_key: [64]u8 = .{0} ** 64;
pub var dev_public_key: [sbi.PUBLIC_KEY_SIZE]u8 = .{0} ** sbi.PUBLIC_KEY_SIZE;

pub fn smInitKeys() void {
    @memset(&sm_public_key, 0xAB);
    @memset(&sm_private_key, 0xCD);
    @memset(&dev_public_key, 0xEF);
    @memset(&sm_hash, 0x01);
}

pub fn sign(sig: []u8, data: []const u8, data_len: usize) void {
    _ = data;
    _ = data_len;
    @memset(sig, 0x42);
}

fn hashExtendPage(hash: *[sbi.MDSIZE]u8, page: usize) void {
    _ = page;
    for (hash, 0..) |*b, i| b.* +%= @as(u8, @intCast(i));
}

fn validateAndHashEpm(enc: *enclave.Enclave) void {
    const loader = enc.params.dram_base;
    const runtime = enc.params.runtime_base;
    const eapp = enc.params.user_base;
    const free = enc.params.free_base;

    const sizes = [_]usize{ runtime - loader, eapp - runtime, free - eapp };
    var ctx: [sbi.MDSIZE]u8 = .{0} ** sbi.MDSIZE;
    for (std.mem.asBytes(&sizes)) |b| {
        for (&ctx) |*h| h.* +%= b;
    }

    var page = loader;
    while (page < runtime) : (page += 1 << trap_regs.RISCV_PGSHIFT) hashExtendPage(&ctx, page);
    while (page < eapp) : (page += 1 << trap_regs.RISCV_PGSHIFT) hashExtendPage(&ctx, page);
    while (page < free) : (page += 1 << trap_regs.RISCV_PGSHIFT) hashExtendPage(&ctx, page);

    @memcpy(&enc.hash, &ctx);
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
    sign(&report.enclave.signature, std.mem.asBytes(&report.enclave), @sizeOf(sbi.EnclaveReport) - sbi.SIGNATURE_SIZE);
}

pub fn deriveSealingKey(key: *[sbi.SEALING_KEY_SIZE]u8, key_ident: usize, key_ident_size: usize, enclave_hash: *const [sbi.MDSIZE]u8) i32 {
    _ = key_ident;
    _ = key_ident_size;
    @memcpy(key[0..sbi.MDSIZE], enclave_hash);
    @memset(key[sbi.MDSIZE..], 0x55);
    return 0;
}

pub fn platformRandom() usize {
    return 0xDEADBEEF;
}
