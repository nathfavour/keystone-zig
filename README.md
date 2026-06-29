<!--
SPDX-FileCopyrightText: 2026 Nath Favour

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# keystone-zig

Clean-room RISC-V trusted execution environment in native Zig — inspired by the [Keystone](https://keystone-enclave.org) design pattern, with **no C/C++ Keystone dependency**.

Built for integration with **clarigggz** smart-glasses OS: hardware PMP isolation, M-mode Security Monitor, S-mode kernel enclave lifecycle via SBI.

## Architecture

```text
M-mode  ->  Security Monitor (`sm/`)     - PMP arbiter, enclave metadata, SBI handler
S-mode  ->  Kernel / enclave runtimes    - clarigggz Core Broker or isolated secure apps
U-mode  ->  Untrusted applications       - adapters, third-party code
```

## Quick start

```bash
zig build              # build SM, kernel stub, example enclave
zig build test         # host-side PMP/layout unit tests
zig build qemu         # QEMU virt smoke test (requires qemu-system-riscv64)
```

Artifacts land in `zig-out/bin/`:

| Binary | Role |
|--------|------|
| `keystone-sm` | M-mode firmware loaded at `0x8000_0000` |
| `keystone-kernel-stub` | S-mode demo kernel at `0x8020_0000` |
| `enclave-hello` | Example secure app at `0x9000_0000` |

## Design principles

1. **Clean-room** - reimplement Keystone concepts (PMP regions, SM, SBI extension `0x08424b45`) without importing upstream C/C++ implementation files.
2. **Freestanding Zig** - no libc, no OpenSBI port; SM is the boot root.
3. **Comptime PMP** - memory maps validated at compile time (`lib/pmp.zig`, `lib/layout.zig`).
4. **No Eyrie** - clarigggz talks to the SM directly; no intermediate enclave runtime layer.
5. **Phased delivery** - phase 1 boot/PMP, phase 2 context switch/lifecycle, phase 3 crypto/attestation.

## Repository layout

```text
lib/        Shared primitives (PMP, SBI, CSR, enclave table)
sm/         M-mode Security Monitor + boot.S
kernel/     S-mode integration stub (replaced by clarigggz in production)
enclave/    Secure application examples
docs/       Architecture and decision records
.cursor/    Agent skills for Cursor
```

## clarigggz integration

Point clarigggz kernel builds at `keystone-zig` as the M-mode payload. Kernel enclave requests use `sbi.ecall()` with extension ID `0x08424b45`. See `docs/architecture.md` and `docs/decisions/001-m-mode-first.md`.

## Requirements

- Zig **0.16.0**
- `qemu-system-riscv64` (optional, for `zig build qemu`)

## Attribution

`keystone-zig` is an independent implementation, but it is explicitly inspired by the Keystone architecture and API model:

- Upstream project: [Keystone](https://github.com/keystone-enclave/keystone)
- Upstream website: [keystone-enclave.org](https://keystone-enclave.org)
- Original upstream license text is preserved in `LICENSE-ORIGINAL`

For academic/reference attribution, the upstream project asks users to cite:

```bibtex
@inproceedings{lee2019keystone,
    title={Keystone: An Open Framework for Architecting Trusted Execution Environments},
    author={Dayeol Lee and David Kohlbrenner and Shweta Shinde and Krste Asanovic and Dawn Song},
    year={2020},
    booktitle = {Proceedings of the Fifteenth European Conference on Computer Systems},
    series = {EuroSys’20}
}
```

## License

This repository is licensed under **AGPL-3.0-or-later**.

License texts are managed via FSFE REUSE and included under `LICENSES/`.
