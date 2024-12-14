const std = @import("std");

const CacheKey = struct {
    stone: usize,
    time: usize,
};

const Cache = std.AutoHashMap(CacheKey, usize);

fn blink(cache: *Cache, stone: usize, time: usize) !usize {
    if (time == 0) {
        return 1;
    }

    const key = CacheKey{ .stone = stone, .time = time };
    if (cache.get(key)) |value| {
        return value;
    }

    const value = blk: {
        if (stone == 0) {
            break :blk try blink(cache, 1, time - 1);
        }

        var buf: [32]u8 = undefined;
        const stone_text = std.fmt.bufPrint(&buf, "{}", .{stone}) catch unreachable;
        if (stone_text.len % 2 == 0) {
            const left = std.fmt.parseInt(usize, stone_text[0 .. stone_text.len / 2], 10) catch unreachable;
            const right = std.fmt.parseInt(usize, stone_text[stone_text.len / 2 ..], 10) catch unreachable;
            break :blk try blink(cache, left, time - 1) + try blink(cache, right, time - 1);
        }

        break :blk try blink(cache, stone * 2024, time - 1);
    };

    try cache.put(key, value);
    return value;
}

pub fn main() !void {
    const input: [:0]const u8 = @embedFile("input.txt");

    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_state.allocator();

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    var stone_iter = std.mem.tokenizeScalar(u8, line_iter.next().?, ' ');
    var count: usize = 0;
    const time = 75;
    var cache = Cache.init(gpa);
    while (stone_iter.next()) |stone_text| {
        const stone = try std.fmt.parseInt(usize, stone_text, 10);
        count += try blink(&cache, stone, time);
    }

    std.debug.print("{}\n", .{count});
}
