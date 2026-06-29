<!--
SPDX-FileCopyrightText: 2026 2026 Nath Favour

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# keystone-zig — Parity Tracker

Clean-room Zig port of the [Keystone](https://keystone-enclave.org) Security Monitor (SM) design.  
**Reference tree:** `../keystone/sm/` (C + OpenSBI). **Do not import that code.**

Legend: `[x]` done · `[~]` partial/stub · `[ ]` not started

**Overall parity:** ~55% SM core · ~0% SDK/runtime/driver (intentionally omitted for clarigggz)

---

## Phase summary

| Phase | Scope | Status |
|-------|--------|--------|
| 1 | Repo, build, comptime PMP, agent skills | `[x]` |
| 2 | Context switch, dynamic PMP, enclave lifecycle, trap frame | `[~]` |
| 3 | Crypto, attestation, sealing, measured boot | `[~]` |
| 4 | clarigggz integration, plugins, multi-hart | `[ ]` |

---

## Security Monitor (`sm/`)

| Item | Upstream | keystone-zig | Status |
|------|----------|--------------|--------|
| M-mode boot (`boot.S`) | OpenSBI + `sm_init` | `sm/boot.S` → `smEntry` | `[x]` |
| Trap frame save/restore | OpenSBI `sbi_trap_regs` | `sm/trap.S` + `lib/trap_regs.zig` | `[x]` |
| Host trap vector | `_trap_handler` | `mTrapHandler` | `[x]` |
| Enclave trap vector | `trap_vector_enclave` | shared `mTrapHandler` (simplified) | `[~]` |
| `sm_init` / cold boot | `sm.c` | `smEntry` + `pmp_runtime.smInitRegions` | `[~]` |
| SMM region (TOP) | `smm_init` | `smInitRegions` | `[x]` |
| OSM region (BOTTOM) | `osm_init` | `smInitRegions` | `[x]` |
| `osm_pmp_set` | `sm.c` | `pmp_runtime.osmPmpSet` | `[x]` |
| OpenSBI ecall registration | `sbi_ecall_register_extension` | direct `mtvec` handler | `[x]` (different integration) |
| Multi-hart `sm_init_done` barrier | `sm.c` | single-hart only | `[ ]` |
| `sm_copy_key` / RoT keys | platform | `crypto.initKeys` / `provisionKeysColdBoot` + `crypto_sanctum` | `[x]` |
| `platform_init_global_once` | `platform-hook.h` | `platform.initGlobalOnce` | `[x]` |
| `platform_init_global` | per-platform | `platform.initGlobal` stub | `[~]` |
| S-mode kernel handoff (`mret`) | OpenSBI | `drop_to_supervisor` + PMP fix | `[x]` |
| Enclave trap handler | `sbi_trap_handler_keystone_enclave` | via unified handler | `[~]` |

---

## PMP (`lib/pmp_runtime.zig` ← `pmp.c`)

| Item | Status | Notes |
|------|--------|-------|
| Region bitmap allocator | `[x]` | |
| NAPOT region init | `[x]` | |
| TOR region init | `[ ]` | upstream `tor_region_init` |
| `pmp_region_init_atomic` spinlock | `[~]` | single-hart, no lock |
| `pmp_set_keystone` / `pmp_unset` | `[x]` | |
| `pmp_set_global` / IPI sync | `[~]` | no `ipi.c` / `handle_pmp_ipi` |
| `pmp_detect_region_overlap_atomic` | `[x]` | in `detectOverlap` |
| `PMP_SET` mtvec hack for cfg writes | `[ ]` | direct csr write |
| Priority TOP/BOTTOM/ANY | `[x]` | |
| Locked (`L`) bit on entries | `[ ]` | comptime map only |
| Page granularity checks | `[x]` | |
| Safe math overflow (`safe_math_util`) | `[ ]` | |

---

## Enclave core (`lib/enclave.zig`, `lib/enclave_ops.zig` ← `enclave.c`)

| Item | Status | Notes |
|------|--------|-------|
| `enclave_init_metadata` | `[x]` | `initMetadata` |
| `keystone_sbi_create_t` layout | `[x]` | `sbi.CreateArgs` |
| `runtime_params_t` layout | `[x]` | `sbi.RuntimeParams` |
| `is_create_args_valid` | `[x]` | |
| `copy_enclave_create_args` | `[x]` | `copyCreateArgs` + `mprv` |
| `create_enclave` | `[x]` | PMP alloc, hash, FRESH state |
| `destroy_enclave` | `[x]` | memset EPM, free PMP |
| `run_enclave` | `[x]` | FRESH → RUNNING, context switch |
| `resume_enclave` | `[x]` | |
| `exit_enclave` | `[x]` | |
| `stop_enclave` | `[x]` | TIMER / EDGE_CALL_HOST |
| `attest_enclave` | `[~]` | report path wired; test dev RoT keys |
| `get_sealing_key` | `[x]` | HKDF from `sm_private_key` + Ed25519 sign |
| `context_switch_to_enclave` | `[x]` | PMP swap, params, satp |
| `context_switch_to_host` | `[x]` | PMP restore, mip forward |
| `clean_enclave_memory` (UTM zero) | `[x]` | |
| `validate_and_hash_enclave` | `[~]` | stub SHA3 page walk |
| Enclave spinlock | `[~]` | bool stub |
| `ENCLAVE_REGIONS_MAX` / OTHER | `[x]` | EPM + UTM |
| `encl_satp` SV39 identity map | `[x]` | |
| `platform_create_enclave` | `[ ]` | |
| `platform_destroy_enclave` | `[ ]` | |
| `platform_switch_to/from_enclave` | `[ ]` | waymasks etc. |
| Multithreaded enclave (`MAX_ENCL_THREADS`) | `[~]` | struct only, max 1 |

---

## Thread / context (`lib/thread.zig` ← `thread.c`)

| Item | Status |
|------|--------|
| `struct thread_state` / `struct csrs` | `[x]` |
| `swap_prev_state` | `[x]` |
| `swap_prev_mepc` | `[x]` |
| `swap_prev_mstatus` | `[x]` |
| `swap_prev_smode_csrs` | `[x]` |
| `clean_state` / `clean_smode_csrs` | `[x]` |
| `switch_vector_enclave` | `[x]` |
| `switch_vector_host` | `[x]` |

---

## CPU (`lib/cpu.zig` ← `cpu.c`)

| Item | Status |
|------|--------|
| Per-hart `is_enclave` / `eid` | `[x]` |
| `cpu_is_enclave_context` | `[x]` |
| `cpu_get_enclave_id` | `[x]` |
| `cpu_enter/exit_enclave_context` | `[x]` |
| `MAX_HARTS` SMP | `[~]` struct only |

---

## MPRV copies (`lib/mprv.zig` ← `mprv.S` / `mprv.h`)

| Item | Status |
|------|--------|
| `copy_to_sm` | `[x]` | `mprv.S` fault-safe copy path |
| `copy_from_sm` | `[x]` | `mprv.S` fault-safe copy path |
| `copy_block_*` asm paths | `[x]` |
| PMP fault → `REGION_OVERLAPS` | `[x]` |

---

## SBI (`lib/sbi.zig`, `sm/main.zig` ← `sm-sbi.c`, `sm-sbi-opensbi.c`)

| FID | Name | Status |
|-----|------|--------|
| 2001 | `create_enclave` | `[x]` |
| 2002 | `destroy_enclave` | `[x]` |
| 2003 | `run_enclave` | `[x]` |
| 2005 | `resume_enclave` | `[x]` |
| 3001 | `random` | `[~]` stub |
| 3002 | `attest_enclave` | `[~]` |
| 3003 | `get_sealing_key` | `[~]` |
| 3004 | `stop_enclave` | `[x]` |
| 3006 | `exit_enclave` | `[x]` |
| 4000 | `call_plugin` | `[ ]` |
| — | FID range host/enclave prohibit | `[x]` |
| — | Error codes 100000–100100 | `[x]` |
| — | `sbi_trap_exit` integration | `[x]` | via trap frame mret |

---

## Crypto / attestation (`lib/crypto.zig` ← `crypto.c`, `attest.c`, `ed25519/`, `sha3/`)

| Component | Status |
|-----------|--------|
| SHA3-512 (`lib/sha3.zig`) | `[x]` |
| HMAC-SHA3-512 (`lib/hmac_sha3.zig`) | `[x]` |
| HKDF-SHA3-512 (`lib/hkdf.zig`) | `[x]` |
| Ed25519 sign (`lib/ed25519.zig`) | `[x]` |
| Enclave EPM hash (`validateAndHashEnclave`) | `[x]` |
| Attestation report + sealing key | `[x]` test dev RoT keys |

| Item | Status |
|------|--------|
| SHA3-512 measure enclave | `[x]` |
| `validate_and_hash_epm` page walk | `[x]` |
| Ed25519 sign / verify | `[~]` sign only |
| `sm_sign` | `[x]` |
| `sm_derive_sealing_key` (HKDF) | `[x]` |
| `dev_public_key` / secure boot | `[x]` `provisionKeysColdBoot` + upstream test dev keys |
| `sm_firmware_hash` tooling (`zig build hash-sm`) | `[x]` |
| Report struct layout | `[x]` |

---

## Platform (`plat/` upstream)

| Platform | Status |
|----------|--------|
| generic / QEMU virt | `[~]` `layout.qemu_virt` + `platform.zig` |
| SiFive FU540 / waymasks | `[ ]` |
| HiFive unmatched | `[ ]` |
| Microchip MPFS | `[ ]` |
| FPGA Ariane | `[ ]` |
| `platform_random` | `[x]` MSWS PRNG (generic parity) |

---

## Plugins (`sm/src/plugins/`)

| Plugin | Status |
|--------|--------|
| `multimem` | `[ ]` |
| `call_plugin` dispatch | `[ ]` |

---

## IPI / SMP (`ipi.c`)

| Item | Status |
|------|--------|
| PMP IPI mailbox | `[ ]` |
| `send_and_sync_pmp_ipi` | `[ ]` |
| `handle_pmp_ipi` | `[ ]` |

---

## SDK / host (`keystone/sdk/`) — clarigggz replaces

| Component | Port? | Status |
|-----------|-------|--------|
| C++ host `Enclave.cpp` | Zig host API | `[ ]` |
| ELF loader / `.ke` package | Zig packager | `[ ]` |
| Eyrie runtime | direct enclave Zig | `[~]` `enclave/hello` |
| App SDK (`eapp`) | `[ ]` |
| Verifier / JSON reports | `[ ]` |

---

## Linux driver (`linux-keystone-driver/`)

| Item | Status | Notes |
|------|--------|-------|
| ioctl create/run/destroy | `[ ]` | clarigggz uses direct SBI |
| `keystone_sbi_create_t` uapi | `[x]` | mirrored in `sbi.CreateArgs` |

---

## Build / test / QEMU

| Item | Status |
|------|--------|
| `zig build` SM + kernel + enclave | `[x]` |
| `zig build test` host PMP tests | `[x]` |
| `zig build qemu` smoke | `[x]` SM→kernel→create→run→exit→destroy OK |
| `objcopy` flat binaries | `[x]` |
| CMocka SM unit tests port | `[ ]` |
| RV32 support | `[ ]` |

---

## Agent skills (`.cursor/skills/`)

| Skill | Status |
|-------|--------|
| `keystone-zig-architecture` | `[x]` |
| `keystone-zig-sm` | `[x]` |
| `keystone-zig-pmp` | `[x]` |
| `keystone-zig-sbi` | `[x]` |
| `keystone-zig-clarigggz` | `[x]` |

---

## Known gaps / next actions (priority)

1. **[P0]** ~~Fix QEMU S-mode entry~~ — fixed: `PMP_A_NAPOT` encoding, explicit OSM in `drop.S`, `-m 512M`, `.bin` loaders.
2. **[P0]** Enclave run/exit return to kernel (context switch / trap stack).
3. **[P1]** ~~Platform RoT keys (`sm_copy_key` / sanctum keys)~~ — `provisionKeysColdBoot`, `crypto_sanctum`, test dev keys.
4. **[P1]** ~~Platform key provisioning and measured boot~~ — `zig build hash-sm`, optional `-Dverify_sm_hash=true`.
5. **[P1]** TOR PMP regions + locked bit parity.
6. **[P2]** `trap_vector_enclave` separate path + enclave interrupt delegation.
7. **[P2]** IPI / multi-hart PMP sync.
8. **[P2]** `call_plugin` / multimem.
9. **[P3]** clarigggz `build.zig` import of `keystone` module.
10. **[P3]** Platform ports (K1 / SpacemiT).

---

## File mapping (quick reference)

| Upstream | keystone-zig |
|----------|--------------|
| `sm/src/enclave.c` | `lib/enclave_ops.zig` |
| `sm/src/pmp.c` | `lib/pmp_runtime.zig` |
| `sm/src/thread.c` | `lib/thread.zig` |
| `sm/src/cpu.c` | `lib/cpu.zig` |
| `sm/src/mprv.S` | `lib/mprv.zig` |
| `sm/src/attest.c` | `lib/crypto.zig` |
| `sm/src/sm-sbi.c` | `sm/main.zig` |
| `sm/src/sm.c` | `sm/main.zig` + `pmp_runtime.zig` |
| `sm/src/trap.S` | `sm/trap.S` |
| `sdk/include/shared/sm_call.h` | `lib/sbi.zig` |

---

*Last updated: phase 2 implementation pass — 2026-06-29*
