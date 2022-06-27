const std = @import("std");
const parse = @import("test4.zig").parse;

pub export fn main() void {
    zigMain() catch unreachable;
}

pub fn zigMain() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == false);
    const allocator = gpa.allocator();

    const stdin = std.io.getStdIn();
    const data = try stdin.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(data);
    var stream_source = std.io.StreamSource{ .buffer = std.io.fixedBufferStream(data) };

    // Call checkAllAllocationFailures, but ignore error.NondeterministicMemoryUsage
    // (normally you wouldn't ignore NondeterministicMemoryUsage, but it's necessary in our
    // case because we use `std.BufMap.putMove` which has an OutOfMemory recovery strategy)
    std.testing.checkAllAllocationFailures(allocator, parseTest, .{&stream_source}) catch |err| switch (err) {
        error.NondeterministicMemoryUsage => {},
        else => |e| return e,
    };
}

fn parseTest(allocator: std.mem.Allocator, stream_source: *std.io.StreamSource) !void {
    try stream_source.seekTo(0);

    if (parse(allocator, stream_source)) |*parsed| {
        parsed.deinit();
    } else |err| {
        switch (err) {
            // We only want to return the error if it's OutOfMemory
            error.OutOfMemory => return error.OutOfMemory,
            // Any other error is fine since not all inputs will be valid
            else => {},
        }
    }
}
