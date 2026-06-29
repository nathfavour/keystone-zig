---
# SPDX-FileCopyrightText: 2026 2026 Nath Favour
#
# SPDX-License-Identifier: AGPL-3.0-or-later

name: keystone-zig-sbi
description: >-
  Implements Keystone SBI extension calls in keystone-zig. Use when adding SBI
  functions, ecall wrappers, error codes, or clarigggz kernel enclave API.
---

# Keystone SBI Extension

## Identity

- Extension EID: `0x08424b45` (`lib/sbi.zig`)
- SBI v0.2 calling convention: ext in `a7`, fid in `a6`, args in `a0`–`a5`
- Return: error in `a0`, value in `a1`

## Calling from S-mode (kernel / clarigggz)

```zig
const ret = keystone.sbi.ecall(
    keystone.sbi.extension_id,
    @intFromEnum(keystone.sbi.Fid.create_enclave),
    @intFromPtr(&args), 0, 0, 0, 0, 0,
);
if (ret.error_code != 0) { /* handle */ }
const eid = ret.value;
```

## Create args struct

```zig
const args = keystone.sbi.CreateArgs{
    .epm_paddr = 0x9000_0000,
    .epm_size = 0x0040_0000,
    .utm_paddr = 0x9400_0000,
    .utm_size = 0x0010_0000,
};
```

Validated by `enclave.validateCreateArgs` — page-aligned sizes, granule-aligned bases.

## Error codes

Use `keystone.sbi.Error` enum (range 100000–100100). Convert with `.toSbiRet()`.

## FID ranges (spec)

| Range | Caller |
|-------|--------|
| 2000–2999 | Host (kernel) |
| 3000–3999 | Enclave |
| 4000–4999 | Experimental plugins |

## Adding a new function

1. Add FID to `lib/sbi.zig` `Fid` enum
2. Add error variants if needed
3. Dispatch in `sm/main.zig` `handleSbiEcall`
4. Document in `docs/architecture.md`

## clarigggz wrapper pattern

Expose thin kernel API:

```zig
pub fn spawnSecureEnclave(epm: PhysRange, utm: PhysRange) !EnclaveId {
    // pack CreateArgs, ecall, return eid
}
```

Keep SBI details inside `keystone` module — adapters never call SM directly.

## Reference

Upstream spec (read-only): `../keystone/sm/spec/v1.0.md`
