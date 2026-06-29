// SPDX-FileCopyrightText: 2026 Nath Favour
//
// SPDX-License-Identifier: AGPL-3.0-or-later

//! SM firmware measurement hash — regenerate with `zig build hash-sm`.

pub const hash: [64]u8 = .{0} ** 64;
pub const sm_size: usize = 0x0010_0000;
pub const valid: bool = false;
