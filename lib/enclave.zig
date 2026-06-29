//! Enclave metadata — parity with `enclave.h`.

const sbi = @import("sbi.zig");
const pmp_runtime = @import("pmp_runtime.zig");
const thread = @import("thread.zig");

pub const max_enclaves = @import("config").max_enclaves;
pub const max_encl_threads = 1;
pub const enclave_regions_max = 2;
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
    epm,
    utm,
    other,
};

pub const Region = struct {
    pmp_rid: pmp_runtime.RegionId = pmp_runtime.invalid_region,
    region_type: RegionType = .invalid,
};

pub const Enclave = struct {
    eid: u32 = invalid_id,
    encl_satp: usize = 0,
    state: State = .invalid,
    regions: [enclave_regions_max]Region = undefined,
    hash: [sbi.MDSIZE]u8 = .{0} ** sbi.MDSIZE,
    sign: [sbi.SIGNATURE_SIZE]u8 = .{0} ** sbi.SIGNATURE_SIZE,
    params: sbi.RuntimeParams = .{
        .dram_base = 0,
        .dram_size = 0,
        .runtime_base = 0,
        .user_base = 0,
        .free_base = 0,
        .untrusted_base = 0,
        .untrusted_size = 0,
        .free_requested = 0,
    },
    n_thread: u32 = 0,
    threads: [max_encl_threads]thread.ThreadState = undefined,

    pub fn exists(self: *const Enclave) bool {
        return self.state != .invalid;
    }
};

var enclaves: [max_enclaves]Enclave = undefined;

fn zeroEnclave(e: *Enclave) void {
    e.* = .{
        .regions = undefined,
        .threads = undefined,
    };
    for (&e.regions) |*r| r.* = .{};
    for (&e.threads) |*t| t.* = .{};
}
var encl_lock: bool = false; // spinlock stub — single hart

fn lock() void {
    encl_lock = true;
}
fn unlock() void {
    encl_lock = false;
}

pub fn initMetadata() void {
    for (&enclaves) |*e| {
        zeroEnclave(e);
        e.state = .invalid;
    }
}

pub fn get(eid: u32) ?*Enclave {
    if (eid >= max_enclaves) return null;
    if (enclaves[eid].state == .invalid) return null;
    return &enclaves[eid];
}

pub fn getMut(eid: u32) ?*Enclave {
    return get(eid);
}

pub fn allocEid(out: *u32) sbi.Error {
    lock();
    defer unlock();
    for (&enclaves, 0..) |*e, i| {
        if (e.state == .invalid) {
            zeroEnclave(e);
            e.state = .allocated;
            e.eid = @intCast(i);
            out.* = @intCast(i);
            return .success;
        }
    }
    return .no_free_resource;
}

pub fn freeEid(eid: u32) void {
    lock();
    enclaves[eid].state = .invalid;
    unlock();
}

pub fn table() *[max_enclaves]Enclave {
    return &enclaves;
}

pub fn isCreateArgsValid(args: sbi.CreateArgs) bool {
    if (args.epm_region.size == 0) return false;
    const epm_start = args.epm_region.paddr;
    const epm_end = epm_start + args.epm_region.size;
    if (epm_start >= epm_end) return false;
    const utm_start = args.utm_region.paddr;
    const utm_end = utm_start + args.utm_region.size;
    if (utm_start >= utm_end and args.utm_region.size > 0) return false;
    if (args.runtime_paddr < epm_start or args.runtime_paddr >= epm_end) return false;
    if (args.user_paddr < epm_start or args.user_paddr >= epm_end) return false;
    if (args.free_paddr < epm_start or args.free_paddr > epm_end) return false;
    if (args.runtime_paddr > args.user_paddr) return false;
    if (args.user_paddr > args.free_paddr) return false;
    return true;
}

pub fn getRegionIndex(eid: u32, rtype: RegionType) i32 {
    const e = get(eid) orelse return -1;
    for (e.regions, 0..) |r, i| {
        if (r.region_type == rtype) return @intCast(i);
    }
    return -1;
}
