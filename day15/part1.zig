const std = @import("std");

const Vec2 = struct {
    x: i32,
    y: i32,

    pub fn add(a: Vec2, b: Vec2) Vec2 {
        return .{ .x = a.x + b.x, .y = a.y + b.y };
    }

    pub fn eql(a: Vec2, b: Vec2) bool {
        return a.x == b.x and a.y == b.y;
    }
};

fn findRobot(map: []const []const u8) Vec2 {
    for (map, 0..) |row, y| {
        for (row, 0..) |cell, x| {
            if (cell == '@') {
                return Vec2{ .x = @intCast(x), .y = @intCast(y) };
            }
        }
    }

    unreachable;
}

fn parseDir(c: u8) Vec2 {
    switch (c) {
        '<' => return Vec2{ .x = -1, .y = 0 },
        '>' => return Vec2{ .x = 1, .y = 0 },
        '^' => return Vec2{ .x = 0, .y = -1 },
        'v' => return Vec2{ .x = 0, .y = 1 },
        else => unreachable,
    }
}

fn getObject(map: []const []const u8, p: Vec2) u8 {
    if (p.y < 0 or p.y >= map.len) {
        return '#';
    }
    const row = map[@intCast(p.y)];
    if (p.x < 0 or p.x >= row.len) {
        return '#';
    }
    const cell = row[@intCast(p.x)];
    return cell;
}

fn setObject(map: [][]u8, p: Vec2, o: u8) void {
    map[@intCast(p.y)][@intCast(p.x)] = o;
}

fn findEmpty(map: [][]u8, p: Vec2, dir: Vec2) ?Vec2 {
    var pp = p;
    while (true) : (pp = pp.add(dir)) {
        const o = getObject(map, pp);
        if (o == '#') {
            return null;
        } else if (o == '.') {
            return pp;
        }
    }
}

fn move(map: [][]u8, p: *Vec2, dir: Vec2) void {
    const next_p = p.add(dir);
    if (findEmpty(map, next_p, dir)) |empty_p| {
        if (!empty_p.eql(next_p)) {
            setObject(map, empty_p, 'O');
        }
        setObject(map, p.*, '.');
        setObject(map, next_p, '@');
        p.* = next_p;
    }
}

fn printMap(map: []const []const u8) void {
    for (map) |row| {
        for (row) |cell| {
            std.debug.print("{c}", .{cell});
        }
        std.debug.print("\n", .{});
    }
}

pub fn main() !void {
    const input: [:0]const u8 = @embedFile("input.txt");

    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_state.allocator();

    var map = std.ArrayList([]u8).init(gpa);
    var line_iter = std.mem.splitScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        if (line.len == 0) {
            break;
        }
        try map.append(try gpa.dupe(u8, line));
    }

    var p = findRobot(map.items);

    while (line_iter.next()) |line| {
        for (line) |dir| {
            move(map.items, &p, parseDir(dir));
            // printMap(map.items);
        }
    }

    var sum: usize = 0;
    for (map.items, 0..) |row, y| {
        for (row, 0..) |cell, x| {
            if (cell == 'O') {
                sum += 100 * y + x;
            }
        }
    }
    std.debug.print("{}\n", .{sum});
}
