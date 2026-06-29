.section .text
.global drop_to_supervisor
# void drop_to_supervisor(uintptr_t entry, uintptr_t sp)
# a0 = entry (mepc), a1 = kernel sp
drop_to_supervisor:
    csrw    mepc, a0
    mv      sp, a1
    csrw    satp, zero
    li      t0, (1 << 11)
    csrw    mstatus, t0
    li      t2, 0x10000000
    li      t3, 'D'
    sb      t3, 0(t2)
    mret
