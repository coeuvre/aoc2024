const std = @import("std");

const Footprint = struct {
    x: i32,
    y: i32,
    dx: i32,
    dy: i32,
};

const Track = std.AutoHashMap(Footprint, void);

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
    if (cell.* == '#' or cell.* == 'O') {
        const prev_cell = &map[@intCast(y.*)][@intCast(x.*)];
        if (prev_cell.* != '^') {
            prev_cell.* = '+';
        }
        turnRight(dx, dy);
    } else {
        if (cell.* == '.') {
            if (dx.* != 0) {
                cell.* = '-';
            } else {
                cell.* = '|';
            }
        } else if (cell.* != '^') {
            cell.* = '+';
        }
        x.* = x1;
        y.* = y1;
    }
    return true;
}

fn record(track: *Track, x: i32, y: i32, dx: i32, dy: i32) !void {
    try track.put(Footprint{ .x = x, .y = y, .dx = dx, .dy = dy }, {});
}

fn visited(track: *const Track, x: i32, y: i32, dx: i32, dy: i32) bool {
    return track.get(Footprint{ .x = x, .y = y, .dx = dx, .dy = dy }) != null;
}

fn hasLoop(arena: std.mem.Allocator, map: [][]u8) !bool {
    var x: i32 = 0;
    var y: i32 = 0;
    find_start: for (map, 0..) |row, row_index| {
        for (row, 0..) |cell, cell_index| {
            if (cell == '^') {
                x = @intCast(cell_index);
                y = @intCast(row_index);
                break :find_start;
            }
        }
    }
    var dx: i32 = 0;
    var dy: i32 = -1;

    var track = Track.init(arena);
    try record(&track, x, y, dx, dy);

    while (step(map, &x, &y, &dx, &dy)) {
        if (visited(&track, x, y, dx, dy)) {
            return true;
        }
        try record(&track, x, y, dx, dy);
    }
    return false;
}

fn printMap(map: [][]const u8) void {
    for (map) |row| {
        for (row) |cell| {
            std.debug.print("{c}", .{cell});
        }
        std.debug.print("\n", .{});
    }
}

fn dupeMap(arena: std.mem.Allocator, map: [][]const u8) ![][]u8 {
    const new_map = try arena.alloc([]u8, map.len);
    for (0..map.len) |row| {
        new_map[row] = try arena.alloc(u8, map[row].len);
        std.mem.copyForwards(u8, new_map[row], map[row]);
    }
    return new_map;
}

pub fn main() !void {
    const input: [:0]const u8 = @embedFile("input.txt");

    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_state.allocator();

    var map = std.ArrayList([]const u8).init(gpa);
    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        try map.append(line);
    }

    var arena_state = std.heap.ArenaAllocator.init(gpa);
    const arena = arena_state.allocator();

    var count: u32 = 0;
    for (map.items, 0..) |row, y| {
        for (row, 0..) |cell, x| {
            if (cell != '^' and cell != '#') {
                defer _ = arena_state.reset(.retain_capacity);
                const new_map = try dupeMap(arena, map.items);
                new_map[y][x] = 'O';
                if (try hasLoop(arena, new_map)) {
                    count += 1;
                    // printMap(new_map);
                    // std.debug.print("\n", .{});
                }
            }
        }
    }

    std.debug.print("{}\n", .{count});
}
