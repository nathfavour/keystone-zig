// SPDX-FileCopyrightText: 2026 2026 Nath Favour
//
// SPDX-License-Identifier: AGPL-3.0-or-later

//! Enclave lifecycle and context switching — parity with `enclave.c`.

const std = @import("std");
const enclave = @import("enclave.zig");
const sbi = @import("sbi.zig");
const trap_regs = @import("trap_regs.zig");
const thread = @import("thread.zig");
const cpu = @import("cpu.zig");
const pmp_runtime = @import("pmp_runtime.zig");
const mprv = @import("mprv.zig");
const csr = @import("csr.zig");
const crypto = @import("crypto.zig");

fn contextSwitchToEnclave(regs: *trap_regs.TrapRegs, eid: u32, load_parameters: bool) void {
    const enc = enclave.getMut(eid).?;

    thread.swapPrevState(&enc.threads[0], regs, true);
    thread.swapPrevMepc(&enc.threads[0], regs, regs.mepc);
    thread.swapPrevMstatus(&enc.threads[0], regs, regs.mstatus);

    csr.write("mideleg", 0);

    if (load_parameters) {
        regs.mepc = enc.params.runtime_base;
        regs.mstatus = 1 << trap_regs.MSTATUS_MPP_SHIFT;
        regs.a1 = enc.params.dram_base;
        regs.a2 = enc.params.dram_size;
        regs.a3 = enc.params.runtime_base;
        regs.a4 = enc.params.user_base;
        regs.a5 = enc.params.free_base;
        regs.a6 = enc.params.untrusted_base;
        regs.a7 = enc.params.untrusted_size;
        csr.write("satp", 0);
    } else {
        csr.write("satp", enc.encl_satp);
    }

    thread.switchVectorEnclave();
    _ = pmp_runtime.osmPmpSet(pmp_runtime.PMP_NO_PERM);

    for (enc.regions) |r| {
        if (r.region_type != .invalid) {
            _ = pmp_runtime.pmpSetKeystone(r.pmp_rid, pmp_runtime.PMP_ALL_PERM);
        }
    }

    cpu.enterEnclaveContext(eid);
}

fn contextSwitchToHost(regs: *trap_regs.TrapRegs, eid: u32, return_on_resume: bool) void {
    const enc = enclave.getMut(eid).?;

    for (enc.regions) |r| {
        if (r.region_type != .invalid) {
            _ = pmp_runtime.pmpSetKeystone(r.pmp_rid, pmp_runtime.PMP_NO_PERM);
        }
    }
    _ = pmp_runtime.osmPmpSet(pmp_runtime.PMP_ALL_PERM);

    csr.write("mideleg", trap_regs.MIP_SSIP | trap_regs.MIP_STIP | trap_regs.MIP_SEIP);

    thread.swapPrevState(&enc.threads[0], regs, return_on_resume);
    thread.swapPrevMepc(&enc.threads[0], regs, regs.mepc);
    thread.swapPrevMstatus(&enc.threads[0], regs, regs.mstatus);

    thread.switchVectorHost();

    const pending = csr.read("mip");
    if (pending & trap_regs.MIP_MTIP != 0) {
        csr.clear("mip", trap_regs.MIP_MTIP);
        csr.set("mip", trap_regs.MIP_STIP);
    }
    if (pending & trap_regs.MIP_MSIP != 0) {
        csr.clear("mip", trap_regs.MIP_MSIP);
        csr.set("mip", trap_regs.MIP_SSIP);
    }
    if (pending & trap_regs.MIP_MEIP != 0) {
        csr.clear("mip", trap_regs.MIP_MEIP);
        csr.set("mip", trap_regs.MIP_SEIP);
    }

    cpu.exitEnclaveContext();
}

pub fn copyCreateArgs(src: usize, dest: *sbi.CreateArgs) sbi.Error {
    var buf: [@sizeOf(sbi.CreateArgs)]u8 = undefined;
    if (mprv.copyToSm(&buf, src)) return .region_overlaps;
    @memcpy(std.mem.asBytes(dest), &buf);
    return .success;
}

fn cleanEnclaveMemory(utbase: usize, utsize: usize) void {
    if (utsize > 0) mprv.memsetPhys(utbase, 0, utsize);
}

pub fn createEnclave(eid_out: *u32, args: sbi.CreateArgs) sbi.Error {
    if (!enclave.isCreateArgsValid(args)) return .illegal_argument;

    const base = args.epm_region.paddr;
    const size = args.epm_region.size;
    const utbase = args.utm_region.paddr;
    const utsize = args.utm_region.size;

    var eid: u32 = undefined;
    const ae = enclave.allocEid(&eid);
    if (ae != .success) return ae;

    var region: pmp_runtime.RegionId = undefined;
    var shared: pmp_runtime.RegionId = undefined;

    const pr = pmp_runtime.pmpRegionInit(base, size, .any, &region, false);
    if (pr != .success) {
        enclave.freeEid(eid);
        return .pmp_failure;
    }

    if (utsize > 0) {
        const ps = pmp_runtime.pmpRegionInit(utbase, utsize, .bottom, &shared, false);
        if (ps != .success) {
            _ = pmp_runtime.pmpRegionFree(region);
            enclave.freeEid(eid);
            return .pmp_failure;
        }
    } else {
        shared = pmp_runtime.invalid_region;
    }

    if (pmp_runtime.pmpSetGlobal(region, pmp_runtime.PMP_NO_PERM) != .success) {
        if (shared != pmp_runtime.invalid_region) _ = pmp_runtime.pmpRegionFree(shared);
        _ = pmp_runtime.pmpRegionFree(region);
        enclave.freeEid(eid);
        return .pmp_failure;
    }

    cleanEnclaveMemory(utbase, utsize);

    const enc = enclave.getMut(eid).?;
    enc.eid = eid;
    enc.regions[0] = .{ .pmp_rid = region, .region_type = .epm };
    if (shared != pmp_runtime.invalid_region)
        enc.regions[1] = .{ .pmp_rid = shared, .region_type = .utm };
    enc.encl_satp = (base >> trap_regs.RISCV_PGSHIFT) | (trap_regs.SATP_MODE_SV39 << 60);
    enc.n_thread = 0;
    enc.params = .{
        .dram_base = base,
        .dram_size = size,
        .runtime_base = args.runtime_paddr,
        .user_base = args.user_paddr,
        .free_base = args.free_paddr,
        .untrusted_base = utbase,
        .untrusted_size = utsize,
        .free_requested = args.free_requested,
    };
    thread.cleanState(&enc.threads[0]);

    const he = crypto.validateAndHashEnclave(enc);
    if (he != .success) {
        _ = pmp_runtime.pmpUnsetGlobal(region);
        if (shared != pmp_runtime.invalid_region) _ = pmp_runtime.pmpRegionFree(shared);
        _ = pmp_runtime.pmpRegionFree(region);
        enclave.freeEid(eid);
        return he;
    }

    enc.state = .fresh;
    eid_out.* = eid;
    return .success;
}

pub fn destroyEnclave(eid: u32) sbi.Error {
    const enc = enclave.get(eid) orelse return .invalid_id;
    if (@intFromEnum(enc.state) > @intFromEnum(enclave.State.stopped)) return .not_destroyable;

    enclave.getMut(eid).?.state = .destroying;

    for (&enclave.getMut(eid).?.regions) |*r| {
        if (r.region_type == .invalid or r.region_type == .utm) continue;
        const rid = r.pmp_rid;
        const b = pmp_runtime.pmpRegionGetAddr(rid);
        const sz = pmp_runtime.pmpRegionGetSize(rid);
        mprv.memsetPhys(b, 0, sz);
        _ = pmp_runtime.pmpUnsetGlobal(rid);
        _ = pmp_runtime.pmpRegionFree(rid);
        r.* = .{};
    }

    const ut_idx = enclave.getRegionIndex(eid, .utm);
    if (ut_idx >= 0) {
        const rid = enclave.getMut(eid).?.regions[@intCast(ut_idx)].pmp_rid;
        _ = pmp_runtime.pmpRegionFree(rid);
    }

    const e = enclave.getMut(eid).?;
    e.encl_satp = 0;
    e.n_thread = 0;
    e.params = .{
        .dram_base = 0,
        .dram_size = 0,
        .runtime_base = 0,
        .user_base = 0,
        .free_base = 0,
        .untrusted_base = 0,
        .untrusted_size = 0,
        .free_requested = 0,
    };
    for (&e.regions) |*r| r.* = .{};
    enclave.freeEid(eid);
    return .success;
}

pub fn runEnclave(regs: *trap_regs.TrapRegs, eid: u32) sbi.Error {
    const enc = enclave.get(eid) orelse return .invalid_id;
    if (enc.state != .fresh) return .not_fresh;

    enclave.getMut(eid).?.state = .running;
    enclave.getMut(eid).?.n_thread += 1;

    contextSwitchToEnclave(regs, eid, true);
    return .success;
}

pub fn resumeEnclave(regs: *trap_regs.TrapRegs, eid: u32) sbi.Error {
    const enc = enclave.get(eid) orelse return .invalid_id;
    if (!(enc.state == .running or enc.state == .stopped)) return .not_resumable;
    if (enc.n_thread >= enclave.max_encl_threads) return .not_resumable;

    enclave.getMut(eid).?.n_thread += 1;
    enclave.getMut(eid).?.state = .running;

    contextSwitchToEnclave(regs, eid, false);
    return .success;
}

pub fn exitEnclave(regs: *trap_regs.TrapRegs, eid: u32) sbi.Error {
    const enc = enclave.get(eid) orelse return .not_running;
    if (enc.state != .running) return .not_running;

    enclave.getMut(eid).?.n_thread -= 1;
    if (enclave.getMut(eid).?.n_thread == 0) enclave.getMut(eid).?.state = .stopped;

    contextSwitchToHost(regs, eid, false);
    return .success;
}

pub fn stopEnclave(regs: *trap_regs.TrapRegs, request: u64, eid: u32) sbi.Error {
    const enc = enclave.get(eid) orelse return .not_running;
    if (enc.state != .running) return .not_running;

    enclave.getMut(eid).?.n_thread -= 1;
    if (enclave.getMut(eid).?.n_thread == 0) enclave.getMut(eid).?.state = .stopped;

    contextSwitchToHost(regs, eid, request == trap_regs.STOP_EDGE_CALL_HOST);

    return switch (request) {
        trap_regs.STOP_TIMER_INTERRUPT => .interrupted,
        trap_regs.STOP_EDGE_CALL_HOST => .edge_call_host,
        else => .unknown,
    };
}

pub fn attestEnclave(report_ptr: usize, data: usize, size: usize, eid: u32) sbi.Error {
    if (size > sbi.ATTEST_DATA_MAXLEN) return .illegal_argument;
    const enc = enclave.get(eid) orelse return .not_initialized;
    if (@intFromEnum(enc.state) < @intFromEnum(enclave.State.fresh)) return .not_initialized;

    var report: sbi.Report = undefined;
    var data_buf: [sbi.ATTEST_DATA_MAXLEN]u8 = undefined;
    if (size > 0) {
        if (mprv.copyToSm(data_buf[0..size], data)) return .not_accessible;
    }
    @memcpy(report.enclave.data[0..size], data_buf[0..size]);
    report.enclave.data_len = size;

    crypto.fillAttestationReport(&report, enc);

    if (mprv.copyFromSm(report_ptr, std.mem.asBytes(&report))) return .illegal_argument;
    return .success;
}

pub fn getSealingKey(sealing_key: usize, key_ident: usize, key_ident_size: usize, eid: u32) sbi.Error {
    const enc = enclave.get(eid) orelse return .unknown;
    var key_struct: sbi.SealingKey = undefined;
    if (crypto.deriveSealingKey(&key_struct.key, key_ident, key_ident_size, &enc.hash) != 0)
        return .unknown;
    crypto.smSign(&key_struct.signature, &key_struct.key);
    if (mprv.copyFromSm(sealing_key, std.mem.asBytes(&key_struct))) return .illegal_argument;
    return .success;
}
