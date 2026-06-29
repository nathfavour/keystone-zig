//! Enclave metadata managed by the Security Monitor in M-mode.

const sbi = @import("sbi.zig");
const pmp = @import("pmp.zig");

pub const max_enclaves = @import("config").max_enclaves;
pub const invalid_id: u32 = 0xFFFF_FFFF;

pub const State = enum(i8) {
    invalid = -1,
    destroying = 0,
    allocated = 1,
    fresh = 2,
    stopped = 3,
    running = 4,
};

pub const RegionType = enum(u8) {
    invalid,
    epm, // enclave private memory
    utm, // untrusted shared memory
    other,
};

pub const Region = struct {
    pmp_entry: u8 = 0xFF,
    region_type: RegionType = .invalid,
    base: usize = 0,
    size: usize = 0,
};

pub const Enclave = struct {
    id: u32 = invalid_id,
    state: State = .invalid,
    regions: [2]Region = .{.{}, .{}},
    params: sbi.RuntimeParams = .{
        .dram_base = 0,
        .dram_size = 0,
        .runtime_base = 0,
        .user_base = 0,
        .free_base = 0,
        .untrusted_base = 0,
        .untrusted_size = 0,
    },
    // Measurement hash placeholder — attestation wired in phase 2
    measurement: [64]u8 = .{0} ** 64,

    pub fn isActive(self: *const Enclave) bool {
        return self.state != .invalid and self.state != .destroying;
    }
};

pub const Table = struct {
    slots: [max_enclaves]Enclave,

    pub fn init() Table {
        var table: Table = undefined;
        for (&table.slots) |*slot| slot.* = .{};
        return table;
    }

    pub fn allocate(self: *Table) ?u32 {
        for (&self.slots, 0..) |*slot, i| {
            if (slot.state == .invalid) {
                slot.* = .{};
                slot.id = @intCast(i);
                slot.state = .allocated;
                return slot.id;
            }
        }
        return null;
    }

    pub fn get(self: *Table, eid: u32) ?*Enclave {
        if (eid >= max_enclaves) return null;
        const slot = &self.slots[eid];
        if (!slot.isActive()) return null;
        return slot;
    }

    pub fn destroy(self: *Table, eid: u32) sbi.Error {
        const slot = self.get(eid) orelse return .invalid_id;
        slot.state = .destroying;
        slot.* = .{};
        return .success;
    }
};

/// Validate create args against PMP constraints.
pub fn validateCreateArgs(args: sbi.CreateArgs) sbi.Error {
    if (args.epm_size == 0 or args.epm_size % pmp.page_size != 0) return .illegal_argument;
    if (args.epm_paddr % pmp.granule != 0) return .illegal_argument;
    if (args.utm_size > 0) {
        if (args.utm_size % pmp.page_size != 0) return .illegal_argument;
        if (args.utm_paddr % pmp.granule != 0) return .illegal_argument;
    }
    return .success;
}
