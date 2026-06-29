//! Per-hart CPU state — parity with `cpu.c`.

const enclave = @import("enclave.zig");
const csr = @import("csr.zig");

pub const max_harts: usize = 8;

pub const CpuState = struct {
    is_enclave: bool = false,
    eid: u32 = enclave.invalid_id,
};

var cpus: [max_harts]CpuState = .{.{}} ** max_harts;

fn hartId() usize {
    const id = csr.read("mhartid");
    if (id >= max_harts) return 0;
    return id;
}

pub fn isEnclaveContext() bool {
    return cpus[hartId()].is_enclave;
}

pub fn getEnclaveId() u32 {
    return cpus[hartId()].eid;
}

pub fn enterEnclaveContext(eid: u32) void {
    cpus[hartId()].is_enclave = true;
    cpus[hartId()].eid = eid;
}

pub fn exitEnclaveContext() void {
    cpus[hartId()].is_enclave = false;
}
