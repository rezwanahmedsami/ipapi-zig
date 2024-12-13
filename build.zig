const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Add the static library for the IPAPI
    const lib = b.addStaticLibrary(.{
        .name = "ipapi-zig",
        .root_source_file = b.path("src/ipapi.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Link to the libcurl library
    lib.linkSystemLibrary("curl");

    // Declare intent to install the static library
    b.installArtifact(lib);

    // Unit test for the library (ipapi.zig)
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/ipapi.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Link to curl for the test step as well
    lib_unit_tests.linkSystemLibrary("curl");

    // Add a run command to execute the tests
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    // Define the test step
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
