#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ZIG_OUT="${ROOT}/zig-out/bin"

if ! command -v qemu-system-riscv64 >/dev/null 2>&1; then
  echo "qemu-system-riscv64 not found; install QEMU or run: zig build" >&2
  exit 1
fi

SM="${ZIG_OUT}/keystone-sm"
KERNEL="${ZIG_OUT}/keystone-kernel-stub"

if [[ ! -f "$SM" || ! -f "$KERNEL" ]]; then
  echo "Build artifacts missing. Run: zig build" >&2
  exit 1
fi

exec qemu-system-riscv64 \
  -machine virt \
  -nographic \
  -bios none \
  -kernel "$SM" \
  -device loader,file="$KERNEL",addr=0x80200000
