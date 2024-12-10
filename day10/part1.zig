const std = @import("std");

const Pos = struct {
    x: i32,
    y: i32,
};

const HashSetPos = std.AutoHashMap(Pos, void);

fn visit(map: []const []const u8, score: *i32, visited: *HashSetPos, pos: Pos, value: u8) !void {
    const entry = try visited.getOrPut(pos);
    if (entry.found_existing) {
        return;
    }

    if (value == '9') {
        score.* += 1;
        return;
    }

    const dirs: []const Pos = &.{
        .{ .x = -1, .y = 0 },
        .{ .x = 1, .y = 0 },
        .{ .x = 0, .y = -1 },
        .{ .x = 0, .y = 1 },
    };
    for (dirs) |dir| {
        const next_pos = Pos{ .x = pos.x + dir.x, .y = pos.y + dir.y };
        if (next_pos.y < 0 or next_pos.y >= map.len) {
            continue;
        }

        const row = map[@intCast(next_pos.y)];

        if (next_pos.x < 0 or next_pos.x >= row.len) {
            continue;
        }

        const cell = row[@intCast(next_pos.x)];
        if (cell == value + 1) {
            try visit(map, score, visited, next_pos, cell);
        }
    }
}

pub fn main() !void {
    const input: [:0]const u8 = @embedFile("input.txt");

    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_state.allocator();

    var visited = HashSetPos.init(gpa);
    var map = std.ArrayList([]const u8).init(gpa);
    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        try map.append(line);
    }

    var sum: i32 = 0;
    for (map.items, 0..) |row, y| {
        for (row, 0..) |cell, x| {
            if (cell == '0') {
                var score: i32 = 0;
                visited.clearRetainingCapacity();
                try visit(map.items, &score, &visited, Pos{ .x = @intCast(x), .y = @intCast(y) }, cell);
                sum += score;
            }
        }
    }

    std.debug.print("{}\n", .{sum});
}
