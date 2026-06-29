//! Machine trap register frame — layout matches Keystone `sbi_trap_regs` / `struct ctx`.
//!
//! Indexed 0..31 for `swap_prev_state` parity with `thread.c`.

pub const TrapRegs = extern struct {
    zero: usize,
    ra: usize,
    sp: usize,
    gp: usize,
    tp: usize,
    t0: usize,
    t1: usize,
    t2: usize,
    s0: usize,
    s1: usize,
    a0: usize,
    a1: usize,
    a2: usize,
    a3: usize,
    a4: usize,
    a5: usize,
    a6: usize,
    a7: usize,
    s2: usize,
    s3: usize,
    s4: usize,
    s5: usize,
    s6: usize,
    s7: usize,
    s8: usize,
    s9: usize,
    s10: usize,
    s11: usize,
    t3: usize,
    t4: usize,
    t5: usize,
    t6: usize,
    mepc: usize,
    mstatus: usize,

  pub fn asWords(self: *TrapRegs) []usize {
        return @as([*]usize, @ptrCast(self))[0..32];
    }
};

pub const frame_size: usize = @sizeOf(TrapRegs);

// MSTATUS bits used by thread.c
pub const MSTATUS_SIE: usize = 1 << 1;
pub const MSTATUS_SPIE: usize = 1 << 5;
pub const MSTATUS_SPP: usize = 1 << 8;
pub const MSTATUS_MPP_SHIFT: usize = 11;
pub const MSTATUS_FS: usize = 1 << 13;
pub const MSTATUS_SUM: usize = 1 << 18;
pub const MSTATUS_MXR: usize = 1 << 19;
pub const mstatus_swap_mask: usize = MSTATUS_SIE | MSTATUS_SPIE | MSTATUS_SPP | (3 << MSTATUS_MPP_SHIFT) | MSTATUS_FS | MSTATUS_SUM | MSTATUS_MXR;

// MIP bits for interrupt forwarding host<->enclave
pub const MIP_SSIP: usize = 1 << 1;
pub const MIP_STIP: usize = 1 << 5;
pub const MIP_SEIP: usize = 1 << 9;
pub const MIP_MTIP: usize = 1 << 7;
pub const MIP_MSIP: usize = 1 << 3;
pub const MIP_MEIP: usize = 1 << 11;

pub const STOP_TIMER_INTERRUPT: u64 = 0;
pub const STOP_EDGE_CALL_HOST: u64 = 1;
pub const STOP_EXIT_ENCLAVE: u64 = 2;

pub const SATP_MODE_SV39: usize = 8;
pub const RISCV_PGSHIFT: usize = 12;
