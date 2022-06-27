const std = @import("std");

pub fn parse(allocator: std.mem.Allocator, stream_source: *std.io.StreamSource) !std.BufMap {
    var map = std.BufMap.init(allocator);
    errdefer map.deinit();

    const reader = stream_source.reader();
    const end_pos = try stream_source.getEndPos();
    while ((try stream_source.getPos()) < end_pos) {
        var key = try reader.readUntilDelimiterAlloc(allocator, '=', std.math.maxInt(usize));
        var value = (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', std.math.maxInt(usize))) orelse return error.EndOfStream;

        try map.putMove(key, value);
    }

    return map;
}

test {
    const data =
        \\foo=bar
        \\baz=qux
    ;
    var stream_source = std.io.StreamSource{ .const_buffer = std.io.fixedBufferStream(data) };
    var parsed = try parse(std.testing.allocator, &stream_source);
    defer parsed.deinit();

    try std.testing.expectEqual(@as(usize, 2), parsed.count());
    try std.testing.expectEqualStrings("bar", parsed.get("foo").?);
    try std.testing.expectEqualStrings("qux", parsed.get("baz").?);
}
