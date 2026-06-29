# ADR 001: M-mode boot before S-mode page tables

**Status:** Accepted  
**Date:** 2026-06-29

## Context

clarigggz needs Keystone-style enclaves. Two starting points were considered:

1. **M-mode boot assembly first** — SM owns reset vector, configures PMP, then `mret` to kernel.
2. **S-mode page tables first** — kernel boots normally, SM added later as a module.

## Decision

Start with **M-mode boot** (`sm/boot.S` → `smEntry`).

## Rationale

1. **PMP is M-mode only.** The Security Monitor must run before any S-mode code executes, or the kernel could observe enclave memory during boot.
2. **Root of trust ordering.** SM locks its own region and the enclave pool as *deny-all* before handing control to the kernel — matching Keystone's trust model.
3. **Simpler bring-up.** Page tables (SV39) are kernel concern; SM operates on physical addresses with `satp=0` during early boot.
4. **QEMU virt alignment.** `-bios none -kernel keystone-sm` is a clean test harness without OpenSBI.

## Consequences

- clarigggz kernel is loaded as a **payload** at a fixed physical address (`0x8020_0000`), not as the reset vector.
- Kernel page table setup happens **after** SM delegation — kernel must not remap SM or enclave pool without SM cooperation.
- Phase 2 context switch must save/restore `satp` across enclave boundaries.

## Alternatives rejected

**S-mode page tables first:** Faster initial kernel hacking, but leaves a window where PMP is unset and enclave pool is world-accessible. Retrofitting M-mode root later requires boot chain surgery.

## Experiment next

Full **enclave context switch** in `sm/main.zig` (`contextSwitchToEnclave`): PMP permission swap + `mepc`/`satp` restore. Page table layout for enclave SV39 can be prototyped in parallel in `kernel/` without changing boot order.
