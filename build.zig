// SPDX-FileCopyrightText: 2026 Nath Favour
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{
        .default_target = .{
            .cpu_arch = .riscv64,
            .os_tag = .freestanding,
            .cpu_model = .{ .explicit = &std.Target.riscv.cpu.generic_rv64 },
            .cpu_features_add = std.Target.riscv.featureSet(&.{ .m, .a, .c, .f, .d }),
        },
    });
    const optimize = b.standardOptimizeOption(.{});

    const hw = b.option([]const u8, "hardware", "Platform profile (qemu_virt | generic)") orelse "qemu_virt";

    const options = b.addOptions();
    options.addOption([]const u8, "hardware", hw);
    options.addOption(usize, "max_enclaves", 8);
    options.addOption(bool, "standalone_sm", true);

    const keystone_module = b.addModule("keystone", .{
        .root_source_file = b.path("lib/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    keystone_module.addOptions("config", options);

    // --- M-mode Security Monitor ---
    const sm_exe = b.addExecutable(.{
        .name = "keystone-sm",
        .root_module = b.createModule(.{
            .root_source_file = b.path("sm/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    sm_exe.root_module.addImport("keystone", keystone_module);
    sm_exe.root_module.addAssemblyFile(b.path("sm/boot.S"));
    sm_exe.root_module.addAssemblyFile(b.path("sm/trap.S"));
    sm_exe.root_module.addAssemblyFile(b.path("sm/drop.S"));
    sm_exe.root_module.addAssemblyFile(b.path("lib/mprv.S"));
    sm_exe.setLinkerScript(b.path("sm/linker.ld"));
    sm_exe.root_module.code_model = .medany;
    sm_exe.entry = .disabled;

    const install_sm = b.addInstallArtifact(sm_exe, .{});
    b.getInstallStep().dependOn(&install_sm.step);

    // --- S-mode kernel stub (clarigggz integration point) ---
    const kernel_exe = b.addExecutable(.{
        .name = "keystone-kernel-stub",
        .root_module = b.createModule(.{
            .root_source_file = b.path("kernel/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    kernel_exe.root_module.addImport("keystone", keystone_module);
    kernel_exe.root_module.addAssemblyFile(b.path("kernel/boot.S"));
    kernel_exe.root_module.addAssemblyFile(b.path("lib/mprv.S"));
    kernel_exe.setLinkerScript(b.path("kernel/linker.ld"));
    kernel_exe.root_module.code_model = .medany;
    kernel_exe.entry = .{ .symbol_name = "_start" };

    const install_kernel = b.addInstallArtifact(kernel_exe, .{});
    b.getInstallStep().dependOn(&install_kernel.step);

    const kernel_bin = b.addObjCopy(kernel_exe.getEmittedBin(), .{ .format = .bin });
    const install_kernel_bin = b.addInstallBinFile(kernel_bin.getOutput(), "keystone-kernel-stub.bin");
    b.getInstallStep().dependOn(&install_kernel_bin.step);

    // --- Example enclave application ---
    const enclave_exe = b.addExecutable(.{
        .name = "enclave-hello",
        .root_module = b.createModule(.{
            .root_source_file = b.path("enclave/hello/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    enclave_exe.root_module.addImport("keystone", keystone_module);
    enclave_exe.root_module.addAssemblyFile(b.path("enclave/boot.S"));
    enclave_exe.root_module.addAssemblyFile(b.path("lib/mprv.S"));
    enclave_exe.setLinkerScript(b.path("enclave/linker.ld"));
    enclave_exe.root_module.code_model = .medany;
    enclave_exe.entry = .{ .symbol_name = "_start" };

    const install_enclave = b.addInstallArtifact(enclave_exe, .{});
    b.getInstallStep().dependOn(&install_enclave.step);

    const enclave_bin = b.addObjCopy(enclave_exe.getEmittedBin(), .{ .format = .bin });
    const install_enclave_bin = b.addInstallBinFile(enclave_bin.getOutput(), "enclave-hello.bin");
    b.getInstallStep().dependOn(&install_enclave_bin.step);

    // --- Host-side unit tests (PMP math, layout validation) ---
    const lib_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("lib/root.zig"),
            .target = b.graph.host,
            .optimize = optimize,
        }),
    });
    lib_tests.root_module.addOptions("config", options);

    const run_lib_tests = b.addRunArtifact(lib_tests);
    const test_step = b.step("test", "Run host-side keystone-zig unit tests");
    test_step.dependOn(&run_lib_tests.step);

    // --- QEMU smoke target ---
    const qemu_script = b.addSystemCommand(&.{b.pathFromRoot("scripts/qemu.sh")});
    qemu_script.step.dependOn(&install_sm.step);
    qemu_script.step.dependOn(&install_kernel.step);
    qemu_script.step.dependOn(&install_enclave.step);
    const qemu_step = b.step("qemu", "Run SM + kernel stub in QEMU virt");
    qemu_step.dependOn(&qemu_script.step);
}
