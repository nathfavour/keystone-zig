// SPDX-FileCopyrightText: 2026 2026 Nath Favour
//
// SPDX-License-Identifier: AGPL-3.0-or-later

//! Keystone SBI extension — parity with `sm_call.h` and spec v1.0-rev1.

pub const extension_id: u32 = 0x08424b45;

pub const Fid = enum(u32) {
    create_enclave = 2001,
    destroy_enclave = 2002,
    run_enclave = 2003,
    resume_enclave = 2005,
    random = 3001,
    attest_enclave = 3002,
    get_sealing_key = 3003,
    stop_enclave = 3004,
    exit_enclave = 3006,
    call_plugin = 4000,
};

pub const fid_range_deprecated: u32 = 1999;
pub const fid_range_host: u32 = 2999;
pub const fid_range_enclave: u32 = 3999;

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
    illegal_pte = 100_015,
    not_fresh = 100_016,
    not_implemented = 100_100,

    pub fn toSbiRet(self: Error) SbiRet {
        return .{ .error_code = @intFromEnum(self), .value = 0 };
    }
};

pub const SbiRet = struct {
    error_code: i32,
    value: usize,
};

pub const PRegion = extern struct {
    paddr: usize,
    size: usize,
};

/// Mirrors `struct keystone_sbi_create_t` from `sdk/include/shared/sm_call.h`.
pub const CreateArgs = extern struct {
    epm_region: PRegion,
    utm_region: PRegion,
    runtime_paddr: usize,
    user_paddr: usize,
    free_paddr: usize,
    free_requested: usize,
};

/// Mirrors `struct runtime_params_t`.
pub const RuntimeParams = struct {
    dram_base: usize,
    dram_size: usize,
    runtime_base: usize,
    user_base: usize,
    free_base: usize,
    untrusted_base: usize,
    untrusted_size: usize,
    free_requested: usize,
};

pub const ATTEST_DATA_MAXLEN: usize = 1024;
pub const MDSIZE: usize = 64;
pub const SIGNATURE_SIZE: usize = 64;
pub const PUBLIC_KEY_SIZE: usize = 32;
pub const SEALING_KEY_SIZE: usize = 128;

pub const EnclaveReport = extern struct {
    hash: [MDSIZE]u8,
    data_len: u64,
    data: [ATTEST_DATA_MAXLEN]u8,
    signature: [SIGNATURE_SIZE]u8,
};

pub const SmReport = extern struct {
    hash: [MDSIZE]u8,
    public_key: [PUBLIC_KEY_SIZE]u8,
    signature: [SIGNATURE_SIZE]u8,
};

pub const Report = extern struct {
    enclave: EnclaveReport,
    sm: SmReport,
    dev_public_key: [PUBLIC_KEY_SIZE]u8,
};

pub const SealingKey = extern struct {
    key: [SEALING_KEY_SIZE]u8,
    signature: [SIGNATURE_SIZE]u8,
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
    );
    return .{ .error_code = @intCast(err), .value = val };
}
