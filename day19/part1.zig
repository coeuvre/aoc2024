const std = @import("std");

const Cache = std.StringHashMap(i64);

fn solve(cache: *Cache, patterns: []const []const u8, design: []const u8) !i64 {
    if (design.len == 0) {
        return 1;
    }

    if (cache.get(design)) |count| {
        return count;
    }

    var count: i64 = 0;
    for (patterns) |pattern| {
        if (std.mem.startsWith(u8, design, pattern)) {
            count += try solve(cache, patterns, design[pattern.len..]);
        }
    }
    try cache.put(design, count);
    return count;
}

pub fn main() !void {
    const input: [:0]const u8 = @embedFile("input.txt");

    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_state.allocator();

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');

    var patterns = std.ArrayList([]const u8).init(gpa);
    var pattern_iter = std.mem.tokenizeSequence(u8, line_iter.next().?, ", ");
    while (pattern_iter.next()) |pattern| {
        try patterns.append(pattern);
    }

    var total: i64 = 0;
    var cache = Cache.init(gpa);
    while (line_iter.next()) |line| {
        if (try solve(&cache, patterns.items, line) > 0) {
            total += 1;
        }
    }

    std.debug.print("{}\n", .{total});
}
