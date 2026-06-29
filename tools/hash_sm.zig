// SPDX-FileCopyrightText: 2026 Nath Favour
//
// SPDX-License-Identifier: AGPL-3.0-or-later

//! Host tool — generate `lib/sm_firmware_hash.zig` (parity with `sm/tools/hash_generator.c`).

const std = @import("std");
const sha3 = @import("sha3_host").sha3;

const default_sm_size: usize = 0x0010_0000;

pub fn main(init: std.process.Init) !void {
    const alloc = init.gpa;
    const io = init.io;
    const args = try init.minimal.args.toSlice(alloc);

    if (args.len < 2 or args.len > 3) {
        std.debug.print("Usage: {s} <firmware.bin> [sm_size_hex]\n", .{args[0]});
        return error.Usage;
    }

    const fw_path = args[1];
    const sm_size: usize = if (args.len == 3) try std.fmt.parseInt(usize, args[2], 16) else default_sm_size;

    const fw_bytes = try std.Io.Dir.cwd().readFileAlloc(io, fw_path, alloc, .limited(64 * 1024 * 1024));
    defer alloc.free(fw_bytes);

    var buf = try alloc.alloc(u8, sm_size);
    defer alloc.free(buf);
    @memset(buf, 0);
    const copy_len = @min(fw_bytes.len, sm_size);
    @memcpy(buf[0..copy_len], fw_bytes[0..copy_len]);

    var ctx: sha3.Sha3Ctx = undefined;
    sha3.init(&ctx, 64);
    sha3.update(&ctx, buf);
    var hash: [64]u8 = undefined;
    sha3.final(&ctx, &hash);

    const out_path = "lib/sm_firmware_hash.zig";
    var file = try std.Io.Dir.cwd().createFile(io, out_path, .{ .read = true });
    defer file.close(io);
    var write_buf: [4096]u8 = undefined;
    var writer = file.writer(io, &write_buf);
    defer writer.end() catch {};

    try writer.interface.writeAll(
        \\// SPDX-FileCopyrightText: 2026 Nath Favour
        \\
        \\// SPDX-License-Identifier: AGPL-3.0-or-later
        \\
        \\//! SM firmware measurement hash — regenerate with `zig build hash-sm`.
        \\
        \\pub const hash: [64]u8 = .{
        \\
    );

    var line_buf: [256]u8 = undefined;
    for (hash, 0..) |byte, i| {
        if (i % 8 == 0) try writer.interface.writeAll("    ");
        const line = try std.fmt.bufPrint(&line_buf, "0x{x:0>2}, ", .{byte});
        try writer.interface.writeAll(line);
        if (i % 8 == 7) try writer.interface.writeAll("\n");
    }
    if (hash.len % 8 != 0) try writer.interface.writeAll("\n");

    try writer.interface.writeAll("};\n");
    var size_buf: [64]u8 = undefined;
    const size_line = try std.fmt.bufPrint(&size_buf, "pub const sm_size: usize = 0x{x:0>8};\n", .{sm_size});
    try writer.interface.writeAll(size_line);
    try writer.interface.writeAll("pub const valid: bool = true;\n");

    std.debug.print("Wrote {s} ({d} bytes padded to 0x{x})\n", .{ out_path, fw_bytes.len, sm_size });
}
