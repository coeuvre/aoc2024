const std = @import("std");

const Pos = struct {
    x: i32,
    y: i32,
};

fn maybeSetAntinode(antinodes: [][]bool, x: i32, y: i32) bool {
    if (y < 0 or y >= antinodes.len) {
        return false;
    }

    const row = antinodes[@intCast(y)];
    if (x < 0 or x >= row.len) {
        return false;
    }

    const cell = &row[@intCast(x)];
    if (cell.*) {
        return false;
    }

    cell.* = true;
    return true;
}

fn countAntinodes(antinodes: [][]bool, antennas: []Pos) i32 {
    var count: i32 = 0;
    for (0..antennas.len) |i| {
        for (i + 1..antennas.len) |j| {
            const p0 = antennas[i];
            const p1 = antennas[j];
            const dx = p1.x - p0.x;
            const dy = p1.y - p0.y;

            if (maybeSetAntinode(antinodes, p0.x - dx, p0.y - dy)) {
                count += 1;
            }
            if (maybeSetAntinode(antinodes, p1.x + dx, p1.y + dy)) {
                count += 1;
            }
        }
    }
    return count;
}

pub fn main() !void {
    const input: [:0]const u8 = @embedFile("input.txt");

    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_state.allocator();

    var map = std.ArrayList([]const u8).init(gpa);
    var antinodes = std.ArrayList([]bool).init(gpa);
    var antennas = std.AutoHashMap(u8, std.ArrayList(Pos)).init(gpa);

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        try map.append(line);
        try antinodes.append(try gpa.alloc(bool, line.len));
    }

    for (map.items, 0..) |row, y| {
        for (row, 0..) |cell, x| {
            if (cell != '.') {
                const entry = try antennas.getOrPut(cell);
                if (!entry.found_existing) {
                    entry.value_ptr.* = std.ArrayList(Pos).init(gpa);
                }
                try entry.value_ptr.append(Pos{ .x = @intCast(x), .y = @intCast(y) });
            }
        }
    }

    var count: i32 = 0;
    var key_iter = antennas.keyIterator();
    while (key_iter.next()) |key| {
        count += countAntinodes(antinodes.items, antennas.getPtr(key.*).?.items);
    }

    for (map.items, 0..) |row, y| {
        for (row, 0..) |cell, x| {
            if (cell != '.') {
                std.debug.print("{c}", .{cell});
            } else if (antinodes.items[y][x]) {
                std.debug.print("#", .{});
            } else {
                std.debug.print(".", .{});
            }
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("{}\n", .{count});
}
