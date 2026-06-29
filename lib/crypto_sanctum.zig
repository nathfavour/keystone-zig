// SPDX-FileCopyrightText: 2026 Nath Favour
//
// SPDX-License-Identifier: AGPL-3.0-or-later

//! Sanctum RoT symbol linkage — used when `bootloader_provided_keys` is enabled.

const sbi = @import("sbi.zig");
const crypto = @import("crypto.zig");

pub extern var sanctum_sm_hash: [sbi.MDSIZE]u8;
pub extern var sanctum_sm_signature: [sbi.SIGNATURE_SIZE]u8;
pub extern var sanctum_sm_public_key: [sbi.PUBLIC_KEY_SIZE]u8;
pub extern var sanctum_sm_secret_key: [64]u8;
pub extern var sanctum_dev_public_key: [sbi.PUBLIC_KEY_SIZE]u8;

pub fn smCopyKey() void {
    @memcpy(&crypto.sm_hash, &sanctum_sm_hash);
    @memcpy(&crypto.sm_signature, &sanctum_sm_signature);
    @memcpy(&crypto.sm_public_key, &sanctum_sm_public_key);
    @memcpy(&crypto.sm_private_key, &sanctum_sm_secret_key);
    @memcpy(&crypto.dev_public_key, &sanctum_dev_public_key);
}
