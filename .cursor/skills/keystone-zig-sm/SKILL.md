---
# SPDX-FileCopyrightText: 2026 2026 Nath Favour
#
# SPDX-License-Identifier: AGPL-3.0-or-later

name: keystone-zig-sm
description: >-
  Develops the M-mode Security Monitor in keystone-zig. Use when editing sm/,
  trap handlers, SBI dispatch, enclave create/destroy/run, or M-mode boot.
---

# Security Monitor Development

## Boot sequence

```
sm/boot.S:_start → smEntry → PMP map → delegate → mret → kernel
```

## Trap handling

- `mtvec` points to `mTrapHandler`
- S-mode `ecall` (mcause=11) → `handleSbiEcall`
- Read syscall args with **`gpr.read("aN")`**, never `csr.read` for a0–a7
- Return via `gpr.write("a0"/"a1")` + advance `mepc` by 4

## SBI dispatch table

| FID | Handler | Context |
|-----|---------|---------|
| 2001 | `smCreateEnclave` | Host |
| 2002 | `smDestroyEnclave` | Host |
| 2003 | `smRunEnclave` | Host |
| 2005 | `smResumeEnclave` | Host |
| 3004 | `smStopEnclave` | Enclave |
| 3006 | `smExitEnclave` | Enclave |

Add new FIDs in `lib/sbi.zig` first, then implement in `sm/main.zig`.

## Enclave state machine

`invalid → allocated → fresh → running → stopped → destroying`

Managed in `lib/enclave.zig` (`enclave.Table`).

## Phase 2: context switch checklist

- [ ] Save host `satp`, `mepc`, `mstatus`, GPRs on enclave entry
- [ ] Deny host PMP entries for EPM; grant enclave entries
- [ ] First run: pass `RuntimeParams` in a1–a7 per Keystone convention
- [ ] On exit: reverse PMP, restore host context

## Testing

```bash
zig build
zig build qemu   # UART trace: SM boot → kernel stub → create enclave
```

## Files

- `sm/main.zig` — logic
- `sm/boot.S` — reset vector, stack
- `sm/linker.ld` — SM at `0x8000_0000`
