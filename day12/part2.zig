const std = @import("std");

const Pos = struct {
    x: i32,
    y: i32,
};

const PosSet = std.AutoHashMap(Pos, void);

fn isType(map: []const []const u8, ty: u32, pos: Pos) bool {
    if (pos.y < 0 or pos.y >= map.len) {
        return false;
    }
    const row = map[@intCast(pos.y)];
    if (pos.x < 0 or pos.x >= row.len) {
        return false;
    }
    const cell = row[@intCast(pos.x)];
    return cell == ty;
}

fn isCorner(map: []const []const u8, ty: u32, hori: Pos, diag: Pos, vert: Pos) bool {
    var state: u3 = 0b000;
    if (isType(map, ty, hori)) {
        state |= 0b100;
    }
    if (isType(map, ty, diag)) {
        state |= 0b010;
    }
    if (isType(map, ty, vert)) {
        state |= 0b001;
    }

    return state == 0b000 or
        state == 0b101 or
        state == 0b010;
}

fn fill(map: []const []const u8, ty: u8, pos: Pos, area: *usize, side: *usize, visited: *PosSet) !void {
    if (pos.y < 0 or pos.y >= map.len) {
        return;
    }
    const row = map[@intCast(pos.y)];
    if (pos.x < 0 or pos.x >= row.len) {
        return;
    }
    const cell = row[@intCast(pos.x)];
    if (cell != ty) {
        return;
    }
    if ((try visited.getOrPut(pos)).found_existing) {
        return;
    }

    area.* += 1;

    if (isCorner(
        map,
        ty,
        .{ .x = pos.x - 1, .y = pos.y },
        .{ .x = pos.x - 1, .y = pos.y - 1 },
        .{ .x = pos.x, .y = pos.y - 1 },
    )) {
        side.* += 1;
    }

    if (isCorner(
        map,
        ty,
        .{ .x = pos.x + 1, .y = pos.y },
        .{ .x = pos.x + 1, .y = pos.y - 1 },
        .{ .x = pos.x, .y = pos.y - 1 },
    )) {
        side.* += 1;
    }

    if (isCorner(
        map,
        ty,
        .{ .x = pos.x + 1, .y = pos.y },
        .{ .x = pos.x + 1, .y = pos.y + 1 },
        .{ .x = pos.x, .y = pos.y + 1 },
    )) {
        side.* += 1;
    }

    if (isCorner(
        map,
        ty,
        .{ .x = pos.x - 1, .y = pos.y },
        .{ .x = pos.x - 1, .y = pos.y + 1 },
        .{ .x = pos.x, .y = pos.y + 1 },
    )) {
        side.* += 1;
    }

    try fill(map, ty, .{ .x = pos.x - 1, .y = pos.y }, area, side, visited);
    try fill(map, ty, .{ .x = pos.x + 1, .y = pos.y }, area, side, visited);
    try fill(map, ty, .{ .x = pos.x, .y = pos.y - 1 }, area, side, visited);
    try fill(map, ty, .{ .x = pos.x, .y = pos.y + 1 }, area, side, visited);
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

    var price: usize = 0;
    var visited = PosSet.init(gpa);

    for (map.items, 0..) |row, y| {
        for (row, 0..) |cell, x| {
            var area: usize = 0;
            var side: usize = 0;
            try fill(map.items, cell, .{ .x = @intCast(x), .y = @intCast(y) }, &area, &side, &visited);
            price += area * side;
        }
    }

    std.debug.print("{}\n", .{price});
}
