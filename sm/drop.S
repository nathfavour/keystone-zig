/*
 * SPDX-FileCopyrightText: 2026 2026 Nath Favour
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

.section .text
.global drop_to_supervisor

# void drop_to_supervisor(uintptr_t entry, uintptr_t sp)
# a0 = entry (mepc), a1 = kernel sp
drop_to_supervisor:
    csrw    mepc, a0
    mv      sp, a1
    csrw    satp, zero
    # Open S-mode view of all RAM (explicit NAPOT RWX) for standalone QEMU.
    li      t0, -1
    csrw    pmpaddr0, t0
    li      t0, 0x1f
    csrw    pmpcfg0, t0
    sfence.vma
    li      t0, ~0x1888
    csrrc   t1, mstatus, t0
    li      t2, 0x800
    or      t1, t1, t2
    csrw    mstatus, t1
    mret
