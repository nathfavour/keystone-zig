# Architecture

## Threat model (clarigggz)

Smart glasses run untrusted third-party adapters (camera pipelines, wallets). A compromised adapter or kernel driver must not read raw sensor buffers or wallet seed material. Keystone-zig provides **hardware-enforced memory isolation** via RISC-V PMP, managed by an M-mode Security Monitor the host cannot modify.

## Privilege rings

| Mode | Component | Trust |
|------|-----------|-------|
| **M** | Security Monitor | Root of trust — configures PMP, handles enclave SBI |
| **S** | clarigggz kernel + secure enclave runtimes | Semi-trusted — can request enclaves, cannot bypass PMP |
| **U** | Adapters, apps | Untrusted |

## Boot flow

```
_start (boot.S)
  → smEntry (sm/main.zig)
      → install mtvec trap handler
      → apply comptime PMP boot map (uart, sm, kernel, enclave pool)
      → delegate interrupts to S-mode
      → mret into kernel at 0x8020_0000
```

## Enclave lifecycle

1. **Host (S-mode)** fills `sbi.CreateArgs` with physical EPM/UTM regions.
2. **ecall** → SM validates alignment, allocates slot, records regions.
3. **run_enclave** → SM swaps PMP (phase 2), delivers `RuntimeParams` in registers on first entry.
4. **exit_enclave / stop_enclave** → SM restores host PMP view, returns to kernel.

## Memory map (QEMU virt)

| Region | Base | Size | PMP entry | Notes |
|--------|------|------|-----------|-------|
| UART | `0x1000_0000` | 4 KiB | 0 | Debug console |
| SM | `0x8000_0000` | 1 MiB | 1 | M-mode firmware |
| Kernel | `0x8020_0000` | 16 MiB | 2 | clarigggz / stub |
| Enclave pool | `0x9000_0000` | 256 MiB | 3 | Locked until enclave created |

## SBI surface

Compatible with Keystone SM spec v1.0-rev1 subset:

- `create_enclave` (2001), `destroy_enclave` (2002)
- `run_enclave` (2003), `resume_enclave` (2005)
- `stop_enclave` (3004), `exit_enclave` (3006)

Attestation (`3002`) and sealing (`3003`) are planned for phase 3.

## clarigggz integration path

```
clarigggz Core Broker (S-mode)
    │ sbi.ecall(0x08424b45, CREATE, ...)
    ▼
keystone-zig SM (M-mode)
    │ PMP carve-out
    ▼
secure enclave (S-mode in bubble) — camera crypto, wallet, etc.
```

Replace `kernel/main.zig` with clarigggz entry; keep `keystone` Zig module as shared contract.

## What we deliberately omit

- OpenSBI / BBL port
- Eyrie runtime
- Linux kernel driver (clarigggz is freestanding microkernel)
- C++ SDK / `.ke` package format (may add Zig packager later)
