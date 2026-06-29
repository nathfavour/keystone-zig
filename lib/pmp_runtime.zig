//! Dynamic PMP region allocator — parity with `pmp.c`.

const std = @import("std");
const csr = @import("csr.zig");
const sbi = @import("sbi.zig");

pub const page_size: usize = 4096;
pub const max_regions: usize = 32;
pub const max_regs: usize = 16;

pub const PMP_R: u8 = 0x01;
pub const PMP_W: u8 = 0x02;
pub const PMP_X: u8 = 0x04;
pub const PMP_ALL_PERM: u8 = PMP_R | PMP_W | PMP_X;
pub const PMP_NO_PERM: u8 = 0;
pub const PMP_A_NAPOT: u8 = 3;

pub const Priority = enum { any, top, bottom };
pub const RegionId = i32;
pub const invalid_region: RegionId = -1;

const PmpRegion = struct {
    addr: usize = 0,
    size: usize = 0,
    addrmode: u8 = 0,
    allow_overlap: bool = false,
    reg_idx: i32 = 0,
};

var regions: [max_regions]PmpRegion = .{.{}} ** max_regions;
var region_def_bitmap: u32 = 0;
var reg_bitmap: u32 = 0;
var sm_region_id: RegionId = invalid_region;
var os_region_id: RegionId = invalid_region;

fn setBit(bitmap: *u32, n: u32) void {
    bitmap.* |= @as(u32, 1) << n;
}
fn unsetBit(bitmap: *u32, n: u32) void {
    bitmap.* &= ~(@as(u32, 1) << n);
}
fn testBit(bitmap: u32, n: u32) bool {
    return (bitmap & (@as(u32, 1) << n)) != 0;
}

fn regionValid(rid: RegionId) bool {
    return rid >= 0 and rid < max_regions and testBit(region_def_bitmap, @intCast(rid));
}

fn searchRightmostUnset(bitmap: u32, max: u32, mask: u32) i32 {
    var i: u32 = 0;
    var m = mask;
    while (m < (@as(u32, 1) << max)) : (i += 1) {
        if ((~bitmap & m) == m) return @intCast(i);
        m <<= 1;
    }
    return -1;
}

fn detectOverlap(start: usize, size: usize) bool {
    if (size == 0) return true;
    const input_end = start +% size;
    if (input_end < start) return true;
    for (regions, 0..) |r, i| {
        if (!testBit(region_def_bitmap, @intCast(i))) continue;
        if (r.allow_overlap) continue;
        const end = r.addr + r.size;
        if (r.addr < input_end and end > start) return true;
    }
    return false;
}

fn regionPmpAddr(rid: RegionId) usize {
    const r = regions[@intCast(rid)];
    if (r.addr == 0 and r.size == std.math.maxInt(usize)) return std.math.maxInt(usize);
    return (r.addr | (r.size / 2 - 1)) >> 2;
}

fn writePmpReg(n: u8, pmpaddr: usize, cfg_byte: u8) void {
    const slot = n % 8;
    const shift: u6 = @intCast(slot * 8);
    const mask: usize = ~(@as(usize, 0xFF) << shift);
    const cfg_val: usize = @as(usize, cfg_byte) << shift;

    switch (n) {
        0 => {
            csr.write("pmpaddr0", pmpaddr);
            csr.write("pmpcfg0", (csr.read("pmpcfg0") & mask) | cfg_val);
        },
        1 => {
            csr.write("pmpaddr1", pmpaddr);
            csr.write("pmpcfg0", (csr.read("pmpcfg0") & mask) | cfg_val);
        },
        2 => {
            csr.write("pmpaddr2", pmpaddr);
            csr.write("pmpcfg0", (csr.read("pmpcfg0") & mask) | cfg_val);
        },
        3 => {
            csr.write("pmpaddr3", pmpaddr);
            csr.write("pmpcfg0", (csr.read("pmpcfg0") & mask) | cfg_val);
        },
        4 => {
            csr.write("pmpaddr4", pmpaddr);
            csr.write("pmpcfg0", (csr.read("pmpcfg0") & mask) | cfg_val);
        },
        5 => {
            csr.write("pmpaddr5", pmpaddr);
            csr.write("pmpcfg0", (csr.read("pmpcfg0") & mask) | cfg_val);
        },
        6 => {
            csr.write("pmpaddr6", pmpaddr);
            csr.write("pmpcfg0", (csr.read("pmpcfg0") & mask) | cfg_val);
        },
        7 => {
            csr.write("pmpaddr7", pmpaddr);
            csr.write("pmpcfg0", (csr.read("pmpcfg0") & mask) | cfg_val);
        },
        8 => {
            csr.write("pmpaddr8", pmpaddr);
            csr.write("pmpcfg2", (csr.read("pmpcfg2") & mask) | cfg_val);
        },
        9 => {
            csr.write("pmpaddr9", pmpaddr);
            csr.write("pmpcfg2", (csr.read("pmpcfg2") & mask) | cfg_val);
        },
        10 => {
            csr.write("pmpaddr10", pmpaddr);
            csr.write("pmpcfg2", (csr.read("pmpcfg2") & mask) | cfg_val);
        },
        11 => {
            csr.write("pmpaddr11", pmpaddr);
            csr.write("pmpcfg2", (csr.read("pmpcfg2") & mask) | cfg_val);
        },
        12 => {
            csr.write("pmpaddr12", pmpaddr);
            csr.write("pmpcfg2", (csr.read("pmpcfg2") & mask) | cfg_val);
        },
        13 => {
            csr.write("pmpaddr13", pmpaddr);
            csr.write("pmpcfg2", (csr.read("pmpcfg2") & mask) | cfg_val);
        },
        14 => {
            csr.write("pmpaddr14", pmpaddr);
            csr.write("pmpcfg2", (csr.read("pmpcfg2") & mask) | cfg_val);
        },
        15 => {
            csr.write("pmpaddr15", pmpaddr);
            csr.write("pmpcfg2", (csr.read("pmpcfg2") & mask) | cfg_val);
        },
        else => {},
    }
}

fn unsetPmpReg(n: u8) void {
    writePmpReg(n, 0, 0);
}

pub fn pmpInit() void {
    var i: u8 = 0;
    while (i < max_regs) : (i += 1) unsetPmpReg(i);
}

pub fn pmpSetKeystone(rid: RegionId, perm: u8) sbi.Error {
    if (!regionValid(rid)) return .pmp_failure;
    const r = regions[@intCast(rid)];
    const cfg_byte: u8 = r.addrmode | (perm & PMP_ALL_PERM);
    writePmpReg(@intCast(r.reg_idx), regionPmpAddr(rid), cfg_byte);
    csr.sfence_vma();
    return .success;
}

pub fn pmpUnset(rid: RegionId) sbi.Error {
    if (!regionValid(rid)) return .pmp_failure;
    unsetPmpReg(@intCast(regions[@intCast(rid)].reg_idx));
    csr.sfence_vma();
    return .success;
}

pub fn pmpSetGlobal(rid: RegionId, perm: u8) sbi.Error {
    return pmpSetKeystone(rid, perm);
}

pub fn pmpUnsetGlobal(rid: RegionId) sbi.Error {
    _ = pmpUnset(rid);
    return pmpSetKeystone(rid, PMP_NO_PERM);
}

fn napotRegionInit(start: usize, size: usize, priority: Priority, rid_out: *RegionId, allow_overlap: bool) sbi.Error {
    if (size == 0) return .illegal_argument;
    if (!(size == std.math.maxInt(usize) and start == 0)) {
        if (!std.math.isPowerOfTwo(size)) return .illegal_argument;
        if (start % size != 0) return .illegal_argument;
        if (size % page_size != 0) return .illegal_argument;
        if (start % page_size != 0) return .illegal_argument;
    }
    if (!allow_overlap and detectOverlap(start, size)) return .region_overlaps;

    const region_idx = searchRightmostUnset(region_def_bitmap, max_regions, 1);
    if (region_idx < 0) return .no_free_resource;

    const reg_idx: i32 = switch (priority) {
        .any => searchRightmostUnset(reg_bitmap, max_regs, 1),
        .top => if (testBit(reg_bitmap, 0)) -1 else 0,
        .bottom => @intCast(max_regs - 1),
    };
    if (reg_idx < 0) return .no_free_resource;

    const rid: RegionId = region_idx;
    regions[@intCast(rid)] = .{
        .addr = start,
        .size = size,
        .addrmode = PMP_A_NAPOT,
        .allow_overlap = allow_overlap,
        .reg_idx = reg_idx,
    };
    setBit(&region_def_bitmap, @intCast(rid));
    setBit(&reg_bitmap, @intCast(reg_idx));
    rid_out.* = rid;
    return .success;
}

pub fn pmpRegionInit(start: usize, size: usize, priority: Priority, rid_out: *RegionId, allow_overlap: bool) sbi.Error {
    return napotRegionInit(start, size, priority, rid_out, allow_overlap);
}

pub fn pmpRegionFree(rid: RegionId) sbi.Error {
    if (!regionValid(rid)) return .pmp_failure;
    const reg_idx: u32 = @intCast(regions[@intCast(rid)].reg_idx);
    unsetBit(&region_def_bitmap, @intCast(rid));
    unsetBit(&reg_bitmap, reg_idx);
    regions[@intCast(rid)] = .{};
    return .success;
}

pub fn pmpRegionGetAddr(rid: RegionId) usize {
    if (!regionValid(rid)) return 0;
    return regions[@intCast(rid)].addr;
}

pub fn pmpRegionGetSize(rid: RegionId) usize {
    if (!regionValid(rid)) return 0;
    return regions[@intCast(rid)].size;
}

pub fn osmPmpSet(perm: u8) sbi.Error {
    if (!regionValid(os_region_id)) return .pmp_failure;
    return pmpSetKeystone(os_region_id, perm);
}

pub fn smInitRegions(sm_base: usize, sm_size: usize) sbi.Error {
    pmpInit();
    var rid: RegionId = undefined;
    const e1 = pmpRegionInit(sm_base, sm_size, .top, &rid, false);
    if (e1 != .success) return e1;
    sm_region_id = rid;
    const e2 = pmpSetKeystone(sm_region_id, PMP_NO_PERM);
    if (e2 != .success) return e2;

    const e3 = pmpRegionInit(0, std.math.maxInt(usize), .bottom, &rid, true);
    if (e3 != .success) return e3;
    os_region_id = rid;
    return pmpSetKeystone(os_region_id, PMP_ALL_PERM);
}
