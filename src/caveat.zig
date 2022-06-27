const std = @import("std");

pub fn parse(allocator: std.mem.Allocator, stream_source: *std.io.StreamSource) !std.BufMap {
    var map = std.BufMap.init(allocator);
    errdefer map.deinit();

    const reader = stream_source.reader();
    const end_pos = try stream_source.getEndPos();
    while ((try stream_source.getPos()) < end_pos) {
        var key = try reader.readUntilDelimiterAlloc(allocator, '=', std.math.maxInt(usize));
        errdefer allocator.free(key);
        var value = (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', std.math.maxInt(usize))) orelse return error.EndOfStream;
        errdefer allocator.free(value);

        try map.putMove(key, value);
    }

    return map;
}

fn parseTest(allocator: std.mem.Allocator, stream_source: *std.io.StreamSource, expected: std.BufMap) !void {
    try stream_source.seekTo(0);

    var parsed = try parse(allocator, stream_source);
    defer parsed.deinit();

    try std.testing.expectEqual(expected.count(), parsed.count());
    var expected_it = expected.iterator();
    while (expected_it.next()) |expected_entry| {
        const actual_value = parsed.get(expected_entry.key_ptr.*) orelse {
            std.debug.print("Missing key: {s}\n", .{std.fmt.fmtSliceEscapeLower(expected_entry.key_ptr.*)});
            return error.MissingKey;
        };
        try std.testing.expectEqualStrings(expected_entry.value_ptr.*, actual_value);
    }
}

test {
    const data =
        \\foo=bar
        \\baz=dup
        \\a=b
        \\b=c
        \\c=d
        \\d=e
        \\baz=qux
    ;
    var stream_source = std.io.StreamSource{ .const_buffer = std.io.fixedBufferStream(data) };
    var expected = expected: {
        var map = std.BufMap.init(std.testing.allocator);
        errdefer map.deinit();
        try map.put("foo", "bar");
        try map.put("a", "b");
        try map.put("b", "c");
        try map.put("c", "d");
        try map.put("d", "e");
        try map.put("baz", "qux");
        break :expected map;
    };
    defer expected.deinit();

    if (@import("test_options").check_allocation_failures) {
        try std.testing.checkAllAllocationFailures(std.testing.allocator, parseTest, .{ &stream_source, expected });
    } else {
        try parseTest(std.testing.allocator, &stream_source, expected);
    }
}
