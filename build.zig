const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();

    // Create the command line option (with a default of true)
    const check_allocation_failures = b.option(bool, "check-allocation-failures", "Run tests with checkAllAllocationFailures (default: true)") orelse true;

    // Create the option using the value gotten from the command line
    const test_options = b.addOptions();
    test_options.addOption(bool, "check_allocation_failures", check_allocation_failures);

    addMainStep(b, "1", test_options, mode);
    addMainStep(b, "2", test_options, mode);
    addMainStep(b, "3", test_options, mode);
    addMainStep(b, "4", test_options, mode);

    addFuzzStep(b, "fuzz", "src/fuzz.zig");
}

fn addMainStep(b: *std.build.Builder, comptime num: []const u8, options: *std.build.OptionsStep, mode: std.builtin.Mode) void {
    const main_tests = b.addTest("src/test" ++ num ++ ".zig");
    main_tests.setBuildMode(mode);

    // Add the options as "test_options" to the main_tests step
    // Our option can then be accessed via `@import("test_options").check_allocation_failures`
    main_tests.addOptions("test_options", options);

    const test_step = b.step("test" ++ num, "Run test#" ++ num);
    test_step.dependOn(&main_tests.step);
}

fn addFuzzStep(b: *std.build.Builder, comptime name: []const u8, comptime src: []const u8) void {
    // The library
    const fuzz_lib = b.addStaticLibrary(name ++ "-lib", src);
    fuzz_lib.setBuildMode(.Debug);
    fuzz_lib.want_lto = true;
    fuzz_lib.bundle_compiler_rt = true;

    // Setup the output name
    const fuzz_executable_name = name;
    const fuzz_exe_path = std.fs.path.join(b.allocator, &.{ b.cache_root, fuzz_executable_name }) catch unreachable;

    // We want `afl-clang-lto -o path/to/output path/to/library`
    const fuzz_compile = b.addSystemCommand(&.{ "afl-clang-lto", "-o", fuzz_exe_path });
    // Add the path to the library file to afl-clang-lto's args
    fuzz_compile.addArtifactArg(fuzz_lib);

    // Install the cached output to the install 'bin' path
    const fuzz_install = b.addInstallBinFile(.{ .path = fuzz_exe_path }, fuzz_executable_name);

    // Add a top-level step that compiles and installs the fuzz executable
    const fuzz_compile_run = b.step(name, "Build executable for fuzz testing using afl-clang-lto");
    fuzz_compile_run.dependOn(&fuzz_compile.step);
    fuzz_compile_run.dependOn(&fuzz_install.step);

    // Compile a companion exe for debugging crashes
    const fuzz_debug_exe = b.addExecutable(name ++ "-debug", src);
    fuzz_debug_exe.setBuildMode(.Debug);

    // Only install fuzz-debug when the fuzz step is run
    const install_fuzz_debug_exe = b.addInstallArtifact(fuzz_debug_exe);
    fuzz_compile_run.dependOn(&install_fuzz_debug_exe.step);
}
