---
# SPDX-FileCopyrightText: 2026 2026 Nath Favour
#
# SPDX-License-Identifier: AGPL-3.0-or-later

name: keystone-zig-pmp
description: >-
  Configures RISC-V Physical Memory Protection in keystone-zig using comptime
  validation. Use when adding memory regions, PMP entries, NAPOT encoding, or
  debugging isolation failures.
---

# PMP (Physical Memory Protection)

## Rules

1. Only M-mode (`sm/main.zig`) writes PMP CSRs at runtime.
2. All static regions declared in `lib/layout.zig` as `pmp.Map`.
3. Every map must pass `comptime pmp.Map.validate(map)` — catches overlaps at build time.

## Adding a region

```zig
// lib/layout.zig
.{ .name = "mmio", .base = 0x..., .size = 0x1000, .perm = .rw, .mode = .napot },
```

Constraints:
- `base` and `size` aligned to 4 bytes (PMP granule)
- NAPOT `size` must be power of two ≥ 4
- Max 16 entries on RV64

## Permissions

| Flag | Meaning |
|------|---------|
| `.none` | Deny all — used for enclave pool until carved |
| `.rw` | MMIO, shared untrusted memory |
| `.rwx` | Code regions (SM, kernel, enclave EPM) |

Locked bit (`L=1`) set in `Region.cfgByte()` — SM entries cannot be changed from S-mode.

## NAPOT encoding

```zig
const addr = try pmp.encodeNapot(base, size);
// (base >> 2) | ((size >> 3) - 1)
```

## Runtime writes

Use `writePmpEntry(entry, pmpaddr, cfg_byte)` in `sm/main.zig`. RV64: entries 0–7 → `pmpcfg0`, 8–15 → `pmpcfg2`.

Always `csr.sfence_vma()` after PMP changes.

## Host-side tests

```bash
zig build test   # runs pmp.zig unit tests on host
```

## Common failures

| Symptom | Fix |
|---------|-----|
| Kernel can't access UART | Entry 0 must grant `.rw` to `0x1000_0000` |
| Enclave pool visible to host | Entry 3 must be `.none` until create |
| Overlap compile error | Adjust bases in `layout.zig` |
