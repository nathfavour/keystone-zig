// SPDX-FileCopyrightText: 2026 2026 Nath Favour
//
// SPDX-License-Identifier: AGPL-3.0-or-later

//! Minimal enclave runtime — parity with Eyrie entry.

const keystone = @import("keystone");
const sbi = keystone.sbi;

export fn enclaveMain() void {
    _ = sbi.ecall(
        sbi.extension_id,
        @intFromEnum(sbi.Fid.exit_enclave),
        42,
        0, 0, 0, 0, 0,
    );
}
