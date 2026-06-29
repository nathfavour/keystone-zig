#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ZIG_OUT="${ROOT}/zig-out/bin"

SM="${ZIG_OUT}/keystone-sm"
KERNEL="${ZIG_OUT}/keystone-kernel-stub"
ENCLAVE="${ZIG_OUT}/enclave-hello"

exec qemu-system-riscv64 \
  -machine virt \
  -nographic \
  -bios none \
  -kernel "$SM" \
  -device loader,file="$KERNEL",addr=0x0 \
  -device loader,file="$ENCLAVE",addr=0x0
