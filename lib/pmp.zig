// SPDX-FileCopyrightText: 2026 2026 Nath Favour
//
// SPDX-License-Identifier: AGPL-3.0-or-later

//! Comptime Physical Memory Protection (PMP) map generation and validation.
//!
//! Rationale: PMP bitmasks are error-prone in C macros. Zig `comptime` validates
//! non-overlapping regions and emits correct NAPOT/TOR encodings before boot.

const std = @import("std");

pub const page_size: usize = 4096;
pub const granule: usize = 4;

pub const Perm = packed struct(u8) {
    r: bool = false,
    w: bool = false,
    x: bool = false,
    _reserved: u5 = 0,

    pub fn toPmpCfg(self: Perm) u8 {
        var cfg: u8 = 0;
        if (self.r) cfg |= 0x01;
        if (self.w) cfg |= 0x02;
        if (self.x) cfg |= 0x04;
        return cfg;
    }

    pub const none = Perm{};
    pub const rw = Perm{ .r = true, .w = true };
    pub const rwx = Perm{ .r = true, .w = true, .x = true };
};

pub const AddrMode = enum(u2) {
    off = 0,
    tor = 1,
    na4 = 2,
    napot = 3,
};

pub const Region = struct {
    name: []const u8,
    base: usize,
    size: usize,
    perm: Perm,
    mode: AddrMode = .napot,

    pub fn end(self: Region) usize {
        return self.base + self.size;
    }

    pub fn napotAddr(self: Region) usize {
        std.debug.assert(self.mode == .napot);
        std.debug.assert(self.size >= granule and std.math.isPowerOfTwo(self.size));
        return (self.base >> 2) | ((self.size >> 3) - 1);
    }

    pub fn cfgByte(self: Region) u8 {
        return self.perm.toPmpCfg() | (@as(u8, @intFromEnum(self.mode)) << 3) | 0x80;
    }
};

pub const Map = struct {
    regions: []const Region,

    pub fn validate(comptime map: Map) void {
        comptime {
            for (map.regions, 0..) |a, i| {
                if (a.size == 0) @compileError("PMP region '" ++ a.name ++ "' has zero size");
                if (a.base % granule != 0) @compileError("PMP region '" ++ a.name ++ "' base not granule-aligned");
                if (a.size % granule != 0) @compileError("PMP region '" ++ a.name ++ "' size not granule-aligned");
                for (map.regions[i + 1 ..]) |b| {
                    const overlap = a.base < b.end() and b.base < a.end();
                    if (overlap) @compileError("PMP overlap: '" ++ a.name ++ "' and '" ++ b.name ++ "'");
                }
            }
            if (map.regions.len > 16) @compileError("RV64 PMP supports at most 16 entries");
        }
    }

    pub fn entryCount(comptime map: Map) usize {
        comptime validate(map);
        return map.regions.len;
    }
};

/// Encode PMP address register for NAPOT region covering `size` bytes at `base`.
pub fn encodeNapot(base: usize, size: usize) !usize {
    if (base % granule != 0) return error.UnalignedBase;
    if (size < granule or !std.math.isPowerOfTwo(size)) return error.InvalidNapotSize;
    return (base >> 2) | ((size >> 3) - 1);
}

/// Split entry index into (pmpaddrN, pmpcfgG, slot-in-group).
pub fn entryRegisters(entry: u8) struct { addr_reg: u8, cfg_reg: u8, slot: u8 } {
    const cfg_reg: u8 = if (entry < 8) 0 else if (entry < 16) 2 else unreachable;
    const slot: u8 = entry % 8;
    return .{ .addr_reg = entry, .cfg_reg = cfg_reg, .slot = slot };
}

test "napot encoding" {
    const addr = try encodeNapot(0x8000_0000, 0x1000_0000);
    try std.testing.expect(addr > 0);
}

test "comptime map accepts valid layout" {
    const good = Map{
        .regions = &.{
            .{ .name = "a", .base = 0x8000_0000, .size = 0x1000_0000, .perm = .rwx },
            .{ .name = "b", .base = 0x9000_0000, .size = 0x1000_0000, .perm = .rw },
        },
    };
    comptime Map.validate(good);
    try std.testing.expectEqual(@as(usize, 2), Map.entryCount(good));
}
