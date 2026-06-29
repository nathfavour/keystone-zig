//! Dynamic PMP region allocator — parity with `pmp.c`.

const std = @import("std");
const csr = @import("csr.zig");
const sbi = @import("sbi.zig");

pub const page_size: usize = 4096;
pub const granule: usize = 4;
pub const max_regions: usize = 32;
pub const max_regs: usize = 16;

pub const PMP_R: u8 = 0x01;
pub const PMP_W: u8 = 0x02;
pub const PMP_X: u8 = 0x04;
pub const PMP_ALL_PERM: u8 = PMP_R | PMP_W | PMP_X;
pub const PMP_NO_PERM: u8 = 0;

pub const PMP_A_OFF: u8 = 0;
pub const PMP_A_TOR: u8 = 1;
pub const PMP_A_NA4: u8 = 2;
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

fn getFreeRegionIdx() i32 {
    return searchRightmostUnset(region_def_bitmap, max_regions, 1);
}

fn getFreeRegIdx() i32 {
    return searchRightmostUnset(reg_bitmap, max_regs, 1);
}

fn getConseqFreeRegIdx() i32 {
    return searchRightmostUnset(reg_bitmap, max_regs, 0x3);
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
    if (r.addrmode == PMP_A_NAPOT) return (r.addr | (r.size / 2 - 1)) >> 2;
    if (r.addrmode == PMP_A_TOR) return (r.addr + r.size) >> 2;
    return 0;
}

fn writePmpReg(n: u8, pmpaddr: usize, cfg_byte: u8) void {
    const slot = n % 8;
    const shift: u6 = @intCast(slot * 8);
    const mask: usize = ~(@as(usize, 0xFF) << shift);
    const cfg_val: usize = @as(usize, cfg_byte) << shift;

    inline for (0..16) |entry| {
        if (entry == n) {
            switch (entry) {
                0...7 => {
                    csr.write(@concat("pmpaddr", .{entry}), pmpaddr);
                    const cfg_name = "pmpcfg0";
                    csr.write(cfg_name, (csr.read(cfg_name) & mask) | cfg_val);
                },
                8...15 => {
                    const idx = entry - 8;
                    csr.write(@concat("pmpaddr", .{entry}), pmpaddr);
                    _ = idx;
                    const cfg_name = "pmpcfg2";
                    csr.write(cfg_name, (csr.read(cfg_name) & mask) | cfg_val);
                },
                else => unreachable,
            }
        }
    }
}

fn unsetPmpReg(n: u8) void {
    writePmpReg(n, 0, 0);
}

pub fn pmpInit() void {
    var i: u8 = 0;
    while (i < max_regs) : (i += 1) {
        unsetPmpReg(i);
    }
}

pub fn pmpSetKeystone(rid: RegionId, perm: u8) sbi.Error {
    if (!regionValid(rid)) return .pmp_failure;
    const r = regions[@intCast(rid)];
    const reg_idx: u8 = @intCast(r.reg_idx);
    const cfg_byte: u8 = r.addrmode | (perm & PMP_ALL_PERM);
    writePmpReg(reg_idx, regionPmpAddr(rid), cfg_byte);
    if (r.addrmode == PMP_A_TOR and r.reg_idx > 0) {
        writePmpReg(reg_idx - 1, r.addr >> 2, 0);
    }
    csr.sfence_vma();
    return .success;
}

pub fn pmpUnset(rid: RegionId) sbi.Error {
    if (!regionValid(rid)) return .pmp_failure;
    const reg_idx: u8 = @intCast(regions[@intCast(rid)].reg_idx);
    unsetPmpReg(reg_idx);
    const r = regions[@intCast(rid)];
    if (r.addrmode == PMP_A_TOR and r.reg_idx > 0) unsetPmpReg(reg_idx - 1);
    csr.sfence_vma();
    return .success;
}

pub fn pmpSetGlobal(rid: RegionId, perm: u8) sbi.Error {
    return pmpSetKeystone(rid, perm); // single-hart: no IPI
}

pub fn pmpUnsetGlobal(rid: RegionId) sbi.Error {
    _ = pmpUnset(rid);
    return pmpSetKeystone(rid, PMP_NO_PERM);
}

fn napotRegionInit(start: usize, size: usize, priority: Priority, rid_out: *RegionId, allow_overlap: bool) sbi.Error {
    if (size == 0) return .illegal_argument;
    if (!(size == std.math.maxInt(usize) and start == 0)) {
        if (size & (size - 1) != 0) return .illegal_argument;
        if (start & (size - 1) != 0) return .illegal_argument;
        if (size % page_size != 0) return .illegal_argument;
        if (start % page_size != 0) return .illegal_argument;
    }
    if (!allow_overlap and detectOverlap(start, size)) return .region_overlaps;

    const region_idx = getFreeRegionIdx();
    if (region_idx < 0) return .no_free_resource;

    const reg_idx: i32 = switch (priority) {
        .any => getFreeRegIdx(),
        .top => if (testBit(reg_bitmap, 0)) -1 else 0,
        .bottom => max_regs - 1,
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
    if (size == 0) return .illegal_argument;
    if ((size == std.math.maxInt(usize) and start == 0) or
        (std.math.isPowerOfTwo(size) and start % size == 0))
    {
        return napotRegionInit(start, size, priority, rid_out, allow_overlap);
    }
    // TOR path omitted for now — use NAPOT-aligned regions
    _ = priority;
    _ = allow_overlap;
    _ = rid_out;
    return .illegal_argument;
}

pub fn pmpRegionFree(rid: RegionId) sbi.Error {
    if (!regionValid(rid)) return .pmp_failure;
    const reg_idx: u32 = @intCast(regions[@intCast(rid)].reg_idx);
    unsetBit(&region_def_bitmap, @intCast(rid));
    unsetBit(&reg_bitmap, reg_idx);
    if (regions[@intCast(rid)].addrmode == PMP_A_TOR and regions[@intCast(rid)].reg_idx > 0)
        unsetBit(&reg_bitmap, reg_idx - 1);
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
    try pmpRegionInit(sm_base, sm_size, .top, &rid, false);
    sm_region_id = rid;
    try pmpSetKeystone(sm_region_id, PMP_NO_PERM);

    try pmpRegionInit(0, std.math.maxInt(usize), .bottom, &rid, true);
    os_region_id = rid;
    try pmpSetKeystone(os_region_id, PMP_ALL_PERM);
    return .success;
}

pub fn getSmRegionId() RegionId {
    return sm_region_id;
}

pub fn getOsRegionId() RegionId {
    return os_region_id;
}
