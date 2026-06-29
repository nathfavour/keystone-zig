---
# SPDX-FileCopyrightText: 2026 2026 Nath Favour
#
# SPDX-License-Identifier: AGPL-3.0-or-later

name: keystone-zig-architecture
description: >-
  Guides clean-room Keystone TEE implementation in native Zig for clarigggz.
  Use when working on keystone-zig architecture, clarigggz integration, threat
  model, boot chain, or deciding what to port from upstream Keystone.
---

# keystone-zig Architecture

## Core mandate

Implement Keystone **design patterns** in Zig. Never import upstream C/C++ Keystone (OpenSBI port, Eyrie, C++ SDK).

## Three rings

| Mode | Owner | Responsibility |
|------|-------|----------------|
| M | `sm/` | PMP arbiter, enclave table, SBI trap handler |
| S | clarigggz kernel + enclaves | Request enclaves via `ecall` |
| U | Adapters | Untrusted; no direct SM access |

## Integration with clarigggz

- clarigggz Core Broker replaces `kernel/main.zig` as S-mode payload.
- Secure tasks (camera crypto, wallet) run as S-mode enclaves in PMP bubbles.
- No Eyrie — kernel calls SM directly via extension `0x08424b45`.

## Phased roadmap

1. Boot + static PMP + SBI stubs *(current)*
2. Full context switch (satp, PMP swap, trap frame)
3. Attestation + sealing
4. clarigggz adapter enclaves

## Key files

- `docs/architecture.md` — full system map
- `docs/decisions/001-m-mode-first.md` — why M-mode boots first
- `AGENTS.md` — agent hard rules

## Anti-patterns

- Dropping OpenSBI/Keystone submodules into this repo
- Letting S-mode code write PMP CSRs
- Adding libc or C++ dependencies

## Additional resources

- Upstream spec reference (read-only): sibling `keystone/sm/spec/v1.0.md`
- clarigggz OS: `clarigggzOS/` hexagonal microkernel
