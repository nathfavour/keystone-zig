//! Cryptography — SHA3-512, HMAC, HKDF, Ed25519 (parity with `crypto.c` / `attest.c`).

const std = @import("std");
const sbi = @import("sbi.zig");
const enclave = @import("enclave.zig");
const trap_regs = @import("trap_regs.zig");
const mprv = @import("mprv.zig");
const sha3 = @import("sha3.zig");
const hkdf = @import("hkdf.zig");
const ed25519 = @import("ed25519.zig");

pub var sm_hash: [sbi.MDSIZE]u8 = .{0} ** sbi.MDSIZE;
pub var sm_signature: [sbi.SIGNATURE_SIZE]u8 = .{0} ** sbi.SIGNATURE_SIZE;
pub var sm_public_key: [sbi.PUBLIC_KEY_SIZE]u8 = .{0} ** sbi.PUBLIC_KEY_SIZE;
pub var sm_private_key: [64]u8 = .{0} ** 64;
pub var dev_public_key: [sbi.PUBLIC_KEY_SIZE]u8 = .{0} ** sbi.PUBLIC_KEY_SIZE;

pub fn smInitKeys() void {
    // QEMU / dev profile test keys until platform ROM integration.
    @memset(&sm_public_key, 0xAB);
    @memset(&sm_private_key, 0xCD);
    @memset(&dev_public_key, 0xEF);
    @memset(&sm_hash, 0x01);
}

pub fn sign(sig: []u8, data: []const u8, _: usize) void {
    ed25519.sign(sig, data, &sm_public_key, &sm_private_key);
}

fn hashExtendPage(ctx: *sha3.Sha3Ctx, page: usize) void {
    var buf: [trap_regs.RISCV_PGSIZE]u8 = undefined;
    const old = @import("csr.zig").read("mstatus");
    const mstatus_mprv: usize = 1 << 17;
    const mpp_s: usize = 1 << 11;
    @import("csr.zig").write("mstatus", old | mstatus_mprv | mpp_s);
    for (0..trap_regs.RISCV_PGSIZE) |i| {
        buf[i] = @as(*const volatile u8, @ptrFromInt(page + i)).*;
    }
    @import("csr.zig").write("mstatus", old);
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

    var page = loader;
    while (page < runtime) : (page += trap_regs.RISCV_PGSIZE) hashExtendPage(&ctx, page);
    while (page < eapp) : (page += trap_regs.RISCV_PGSIZE) hashExtendPage(&ctx, page);
    while (page < free) : (page += trap_regs.RISCV_PGSIZE) hashExtendPage(&ctx, page);

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
    sign(&report.enclave.signature, std.mem.asBytes(&report.enclave)[0 .. @sizeOf(sbi.EnclaveReport) - sbi.SIGNATURE_SIZE], 0);
}

pub fn deriveSealingKey(key: *[sbi.SEALING_KEY_SIZE]u8, key_ident: usize, key_ident_size: usize, enclave_hash: *const [sbi.MDSIZE]u8) i32 {
    const info = if (key_ident_size > 0)
        @as([*]const u8, @ptrFromInt(key_ident))[0..key_ident_size]
    else
        &.{};
    return hkdf.hkdfSha3_512(null, enclave_hash, info, key);
}

pub fn platformRandom() usize {
    return 0xDEADBEEF;
}
