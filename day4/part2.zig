const std = @import("std");

const target = "MAS";

fn searchWithDir(map: [][]const u8, x: i32, y: i32, dx: i32, dy: i32) bool {
    var px = x;
    var py = y;
    for (target) |ch| {
        if (py < 0 or py >= map.len) {
            return false;
        }
        const row = map[@intCast(py)];
        if (px < 0 or px >= row.len) {
            return false;
        }
        const cell = row[@intCast(px)];
        if (cell != ch) {
            return false;
        }

        px += dx;
        py += dy;
    }

    return true;
}

fn mark(mask: [][]bool, x: i32, y: i32, dx: i32, dy: i32) void {
    var px = x;
    var py = y;
    for (target) |_| {
        mask[@intCast(py)][@intCast(px)] = true;
        px += dx;
        py += dy;
    }
}

fn search(map: [][]const u8, mask: [][]bool, x: i32, y: i32) bool {
    if (map[@intCast(y)][@intCast(x)] != 'A') {
        return false;
    }

    const found = (searchWithDir(map, x - 1, y - 1, 1, 1) or searchWithDir(map, x + 1, y + 1, -1, -1)) and
        (searchWithDir(map, x - 1, y + 1, 1, -1) or searchWithDir(map, x + 1, y - 1, -1, 1));

    if (found) {
        mark(mask, x - 1, y - 1, 1, 1);
        mark(mask, x - 1, y + 1, 1, -1);
    }
    return found;
}

pub fn main() !void {
    const input: [:0]const u8 = @embedFile("input.txt");
    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_state.allocator();

    var map = std.ArrayList([]const u8).init(gpa);
    var mask = std.ArrayList([]bool).init(gpa);
    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        try map.append(line);
        const mask_line = try gpa.alloc(bool, line.len);
        @memset(mask_line, false);
        try mask.append(mask_line);
    }

    var count: u32 = 0;
    for (0..map.items.len) |y| {
        for (0..map.items[y].len) |x| {
            if (search(map.items, mask.items, @intCast(x), @intCast(y))) {
                count += 1;
            }
        }
    }

    for (map.items, mask.items) |row, row_mask| {
        for (row, row_mask) |cell, cell_mask| {
            if (cell_mask) {
                std.debug.print("{c}", .{cell});
            } else {
                std.debug.print(".", .{});
            }
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("{}\n", .{count});
}
