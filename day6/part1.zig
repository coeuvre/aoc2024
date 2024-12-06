const std = @import("std");

fn turnRight(dx: *i32, dy: *i32) void {
    const fdx: f32 = @floatFromInt(dx.*);
    const fdy: f32 = @floatFromInt(dy.*);
    const rad = std.math.atan2(fdy, fdx);
    const new_rad = rad + std.math.pi / 2.0;
    dx.* = @intFromFloat(std.math.cos(new_rad));
    dy.* = @intFromFloat(std.math.sin(new_rad));
}

fn step(map: [][]u8, x: *i32, y: *i32, dx: *i32, dy: *i32) bool {
    const x1 = x.* + dx.*;
    const y1 = y.* + dy.*;

    if (y1 < 0 or y1 >= map.len) {
        return false;
    }

    const row = map[@intCast(y1)];
    if (x1 < 0 or x1 >= row.len) {
        return false;
    }

    const cell = &row[@intCast(x1)];
    if (cell.* == '#') {
        turnRight(dx, dy);
    } else {
        cell.* = 'X';
        x.* = x1;
        y.* = y1;
    }
    return true;
}

pub fn main() !void {
    const input: [:0]const u8 = @embedFile("input.txt");

    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_state.allocator();

    var map = std.ArrayList([]u8).init(gpa);

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    var y: i32 = 0;
    var x: i32 = 0;
    var dx: i32 = 0;
    var dy: i32 = -1;
    var line_index: i32 = 0;
    while (line_iter.next()) |readonly_line| : (line_index += 1) {
        const line = try gpa.dupe(u8, readonly_line);
        try map.append(line);

        for (line, 0..) |cell, cell_index| {
            if (cell == '^') {
                x = @intCast(cell_index);
                y = @intCast(line_index);
                line[cell_index] = 'X';
            }
        }
    }

    while (step(map.items, &x, &y, &dx, &dy)) {}

    var count: u32 = 0;
    for (map.items) |row| {
        for (row) |cell| {
            if (cell == 'X') {
                count += 1;
            }
            std.debug.print("{c}", .{cell});
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("{}\n", .{count});
}
