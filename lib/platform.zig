// SPDX-FileCopyrightText: 2026 Nath Favour
//
// SPDX-License-Identifier: AGPL-3.0-or-later

//! Platform hooks — parity with `platform-hook.h` and `platform/generic/platform.c`.

const sbi = @import("sbi.zig");
const enclave = @import("enclave.zig");

pub fn initGlobalOnce() sbi.Error {
    return .success;
}

pub fn initGlobal() sbi.Error {
    return .success;
}

pub fn initEnclave(_: *enclave.Enclave) void {}

pub fn destroyEnclave(_: *enclave.Enclave) void {}

pub fn createEnclave(_: *enclave.Enclave) sbi.Error {
    return .success;
}

pub fn switchToEnclave(_: *enclave.Enclave) void {}

pub fn switchFromEnclave(_: *enclave.Enclave) void {}
