<!--
SPDX-FileCopyrightText: 2026 2026 Nath Favour

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Agent instructions — keystone-zig

## What this repo is

Native Zig reimplementation of the **Keystone TEE design pattern** for RISC-V. Do **not** import or link the upstream C/C++ Keystone monorepo.

## Hard rules

1. **Freestanding only** — `riscv64-freestanding`, no libc, no OpenSBI tree.
2. **M-mode SM owns PMP** — only `sm/` writes `pmpcfg*` / `pmpaddr*` at runtime.
3. **Comptime map validation** — new memory regions go in `lib/layout.zig`; call `pmp.Map.validate` at comptime.
4. **SBI extension ID** — `0x08424b45`; host FIDs 2001–2999, enclave FIDs 3001–3999 (`lib/sbi.zig`).
5. **No Eyrie** — enclave apps are plain Zig; clarigggz kernel issues SBI calls directly.
6. **GPR vs CSR** — trap handlers read args via `gpr.read("a0")`, not `csr.read("a0")`.

## Build commands

```bash
zig build
zig build test
zig build -Dhardware=qemu_virt
zig build qemu
```

## Where to edit

| Task | Location |
|------|----------|
| Boot / trap / SBI dispatch | `sm/main.zig`, `sm/boot.S` |
| PMP encoding & validation | `lib/pmp.zig` |
| Platform memory map | `lib/layout.zig` |
| Enclave metadata | `lib/enclave.zig` |
| clarigggz kernel hook | replace `kernel/main.zig` or import `keystone` module |

## Phase roadmap

- **Phase 1 (current):** M-mode boot, static PMP, create/destroy/run SBI stubs
- **Phase 2:** Full host↔enclave context switch (satp, PMP swap, register save)
- **Phase 3:** Attestation (SHA3 + Ed25519), sealing keys
- **Phase 4:** clarigggz adapter integration (camera/crypto enclaves)

## Skills

Project skills live in `.cursor/skills/`. Read the relevant skill before touching that layer.

## Decision records

Rationales for major choices: `docs/decisions/`. Add a new ADR when changing boot order, PMP layout, or SBI surface.
