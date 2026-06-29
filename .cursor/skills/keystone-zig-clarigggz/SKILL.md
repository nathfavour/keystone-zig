---
name: keystone-zig-clarigggz
description: >-
  Integrates keystone-zig TEE with clarigggz OS smart-glasses microkernel.
  Use when connecting clarigggz kernel to SM, spawning secure enclaves for
  camera/crypto/wallet, or planning adapter isolation.
---

# clarigggz Integration

## Why Keystone-zig for smart glasses

Malicious adapters must not scrape raw camera frames or wallet seeds. PMP + M-mode SM provides hardware barriers even if the S-mode kernel is compromised.

## Mapping

| clarigggz | keystone-zig |
|-----------|--------------|
| Core Broker (S-mode) | Replaces `kernel/main.zig` |
| Capability lists | Complement PMP — caps gate *what* runs, PMP gates *memory* |
| Adapters (U-mode) | Untrusted; secure work in enclaves |
| Camera / wallet tasks | Dedicated S-mode enclaves in pool `0x9000_0000` |

## Boot chain

1. Flash/load `keystone-sm` at M-mode reset
2. SM applies PMP, `mret` to clarigggz kernel at `0x8020_0000`
3. Kernel imports `keystone` Zig module for SBI calls

## Build integration (planned)

```zig
// clarigggzOS/build.zig
const keystone = @import("keystone-zig/lib/root.zig");
kernel_exe.root_module.addImport("keystone", keystone_module);
```

SM built separately; clarigggz kernel is SM payload.

## Secure enclave candidates

| Enclave | Protects |
|---------|----------|
| `camera-vault` | Raw ISP buffers before user-space compositor |
| `wallet-core` | Seed derivation, signing |
| `biometric` | Tactile ID templates |

## No Eyrie

clarigggz microkernel interfaces directly with SM. Enclave code is freestanding Zig linked into EPM — same style as `enclave/hello/main.zig`.

## Next steps

1. Wire clarigggz `core/` syscall path to `sbi.ecall` for enclave spawn
2. Complete phase 2 context switch in SM
3. Add camera-vault enclave under `enclave/camera-vault/`

## Related repos

- `clarigggzOS/` — hexagonal microkernel target
- `keystone-zig/` — this repo
