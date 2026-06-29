/*
 * SPDX-FileCopyrightText: 2026 2026 Nath Favour
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

.section .text
.align 4
.globl mTrapHandler
.globl trapVectorEnclave

# TrapRegs layout: 32 x 8-byte GPR slots, then mepc, mstatus
.equ TRAP_SIZE, 272
.equ OFF_MEPC, 256
.equ OFF_MSTATUS, 264

.macro SAVE_GPR idx, reg
    sd \reg, \idx*8(sp)
.endm

.macro LOAD_GPR idx, reg
    ld \reg, \idx*8(sp)
.endm

.macro SAVE_FRAME
    addi sp, sp, -TRAP_SIZE
    SAVE_GPR 0, zero
    SAVE_GPR 1, ra
    SAVE_GPR 2, sp
    addi t6, sp, TRAP_SIZE
    sd t6, 2*8(sp)
    SAVE_GPR 3, gp
    SAVE_GPR 4, tp
    SAVE_GPR 5, t0
    SAVE_GPR 6, t1
    SAVE_GPR 7, t2
    SAVE_GPR 8, s0
    SAVE_GPR 9, s1
    SAVE_GPR 10, a0
    SAVE_GPR 11, a1
    SAVE_GPR 12, a2
    SAVE_GPR 13, a3
    SAVE_GPR 14, a4
    SAVE_GPR 15, a5
    SAVE_GPR 16, a6
    SAVE_GPR 17, a7
    SAVE_GPR 18, s2
    SAVE_GPR 19, s3
    SAVE_GPR 20, s4
    SAVE_GPR 21, s5
    SAVE_GPR 22, s6
    SAVE_GPR 23, s7
    SAVE_GPR 24, s8
    SAVE_GPR 25, s9
    SAVE_GPR 26, s10
    SAVE_GPR 27, s11
    SAVE_GPR 28, t3
    SAVE_GPR 29, t4
    SAVE_GPR 30, t5
    SAVE_GPR 31, t6
    csrr t0, mepc
    sd t0, OFF_MEPC(sp)
    csrr t0, mstatus
    sd t0, OFF_MSTATUS(sp)
.endm

.macro RESTORE_FRAME
    ld t0, OFF_MEPC(sp)
    csrw mepc, t0
    ld t0, OFF_MSTATUS(sp)
    csrw mstatus, t0
    LOAD_GPR 1, ra
    LOAD_GPR 3, gp
    LOAD_GPR 4, tp
    LOAD_GPR 5, t0
    LOAD_GPR 6, t1
    LOAD_GPR 7, t2
    LOAD_GPR 8, s0
    LOAD_GPR 9, s1
    LOAD_GPR 10, a0
    LOAD_GPR 11, a1
    LOAD_GPR 12, a2
    LOAD_GPR 13, a3
    LOAD_GPR 14, a4
    LOAD_GPR 15, a5
    LOAD_GPR 16, a6
    LOAD_GPR 17, a7
    LOAD_GPR 18, s2
    LOAD_GPR 19, s3
    LOAD_GPR 20, s4
    LOAD_GPR 21, s5
    LOAD_GPR 22, s6
    LOAD_GPR 23, s7
    LOAD_GPR 24, s8
    LOAD_GPR 25, s9
    LOAD_GPR 26, s10
    LOAD_GPR 27, s11
    LOAD_GPR 28, t3
    LOAD_GPR 29, t4
    LOAD_GPR 30, t5
    LOAD_GPR 31, t6
    ld      t0, 2*8(sp)
    addi    sp, sp, TRAP_SIZE
    mv      sp, t0
.endm

mTrapHandler:
trapVectorEnclave:
    # Swap to SM trap stack; mscratch holds guest sp after exchange.
    csrrw   sp, mscratch, sp
    SAVE_FRAME
    csrr    t0, mscratch
    sd      t0, 2*8(sp)
    mv      a0, sp
    call    handleMachineTrap
    la      t1, sm_stack_top
    csrw    mscratch, t1
    RESTORE_FRAME
    mret
