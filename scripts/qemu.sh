#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2026 2026 Nath Favour
#
# SPDX-License-Identifier: AGPL-3.0-or-later

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ZIG_OUT="${ROOT}/zig-out/bin"

SM="${ZIG_OUT}/keystone-sm"
KERNEL="${ZIG_OUT}/keystone-kernel-stub"
ENCLAVE="${ZIG_OUT}/enclave-hello"

KERNEL_BIN="${ZIG_OUT}/keystone-kernel-stub.bin"
ENCLAVE_BIN="${ZIG_OUT}/enclave-hello.bin"

exec qemu-system-riscv64 \
  -machine virt \
  -m 512M \
  -nographic \
  -bios none \
  -kernel "$SM" \
  -device loader,file="$KERNEL_BIN",addr=0x80200000 \
  -device loader,file="$ENCLAVE_BIN",addr=0x90000000
