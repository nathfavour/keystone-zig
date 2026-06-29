//! Keystone SBI extension — clean-room constants matching spec v1.0-rev1.
//!
//! Extension EID: 0x08424b45 (experimental + BKE)
//! We implement the subset needed for clarigggz enclave lifecycle first.

pub const extension_id: u32 = 0x08424b45;

pub const Fid = enum(u32) {
    // Host context (2000–2999)
    create_enclave = 2001,
    destroy_enclave = 2002,
    run_enclave = 2003,
    resume_enclave = 2005,
    // Enclave context (3000–3999)
    random = 3001,
    attest_enclave = 3002,
    get_sealing_key = 3003,
    stop_enclave = 3004,
    exit_enclave = 3006,
    // Experimental
    call_plugin = 4000,
};

pub const Error = enum(i32) {
    success = 0,
    unknown = 100_000,
    invalid_id = 100_001,
    interrupted = 100_002,
    pmp_failure = 100_003,
    not_runnable = 100_004,
    not_destroyable = 100_005,
    region_overlaps = 100_006,
    not_accessible = 100_007,
    illegal_argument = 100_008,
    not_running = 100_009,
    not_resumable = 100_010,
    edge_call_host = 100_011,
    not_initialized = 100_012,
    no_free_resource = 100_013,
    sbi_prohibited = 100_014,
    not_implemented = 100_100,

    pub fn toSbiRet(self: Error) SbiRet {
        return .{ .error_code = @intFromEnum(self), .value = 0 };
    }
};

pub const SbiRet = struct {
    error_code: i32,
    value: usize,
};

/// Arguments passed from host when creating an enclave (mirrors Keystone driver struct).
pub const CreateArgs = extern struct {
    epm_paddr: usize,
    epm_size: usize,
    utm_paddr: usize,
    utm_size: usize,
};

/// First-run parameters delivered to enclave via registers (Keystone convention).
pub const RuntimeParams = struct {
    dram_base: usize,
    dram_size: usize,
    runtime_base: usize,
    user_base: usize,
    free_base: usize,
    untrusted_base: usize,
    untrusted_size: usize,
};

pub inline fn ecall(
    ext: u32,
    fid: u32,
    arg0: usize,
    arg1: usize,
    arg2: usize,
    arg3: usize,
    arg4: usize,
    arg5: usize,
) SbiRet {
    var err: isize = undefined;
    var val: usize = undefined;
    asm volatile ("ecall"
        : [err] "={a0}" (err),
          [val] "={a1}" (val),
        : [ext] "{a7}" (ext),
          [fid] "{a6}" (fid),
          [a0] "{a0}" (arg0),
          [a1] "{a1}" (arg1),
          [a2] "{a2}" (arg2),
          [a3] "{a3}" (arg3),
          [a4] "{a4}" (arg4),
          [a5] "{a5}" (arg5),
        : "memory");
    return .{ .error_code = @intCast(err), .value = val };
}
