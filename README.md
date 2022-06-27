zig-checkAllAllocationFailures-example
======================================

Full example code to serve as a companion to [An Intro to Zig's checkAllAllocationFailures](https://www.ryanliptak.com/blog/zig-intro-to-check-all-allocation-failures/)

Clone this repository and run the following commands (requires latest [master version of Zig](https://ziglang.org/download/#release-master)):

- [`zig build test1`](src/test1.zig): Run the initial test code. This should pass.
- [`zig build test2`](src/test2.zig): Run the test code transformed to be compatible with `checkAllAllocationFailures`, but without actually using `checkAllAllocationFailures` yet. This should pass.
- [`zig build test3`](src/test3.zig): Run the test code with `checkAllAllocationFailures`. This should fail due to a leak during `fail index 1/5`.
- [`zig build test4`](src/test4.zig): Run the test code with `checkAllAllocationFailures` with the `errdefer` fixes in place. This should now pass.
- [`zig build test4 -Dcheck-allocation-failures=false`](src/test4.zig): Run `test4` but without `checkAllAllocationFailures`. This should pass.
- [`zig build caveat`](src/caveat.zig): Run a test case that will trigger `error.NondeterministicMemoryUsage` during `checkAllAllocationFailures`.
- [`zig build fuzz`](src/fuzz.zig): Build an executable that will work with `afl-fuzz`. Requires [AFL++](https://github.com/AFLplusplus/AFLplusplus) to be installed. See [Fuzzing Zig Code Using AFL++](https://www.ryanliptak.com/blog/fuzzing-zig-code/) for more info.
  + After building, use `afl-fuzz -i test/fuzz-inputs -o test/fuzz-outputs -- ./zig-out/bin/fuzz` to start fuzz testing. No crashes should be found.
