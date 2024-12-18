const std = @import("std");

const Vec2Set = std.AutoHashMap(Vec2, void);

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

var count: usize = 0;

fn move(gpa: std.mem.Allocator, map: [][]u8, positions: Vec2Set, dir: Vec2) !bool {
    if (positions.count() == 0) {
        return true;
    }

    var next_positions = Vec2Set.init(gpa);
    defer next_positions.deinit();

    {
        var pos_iter = positions.keyIterator();
        while (pos_iter.next()) |p| {
            const next_p = p.add(dir);
            if (positions.contains(next_p)) {
                continue;
            }

            switch (getObject(map, next_p)) {
                '#' => {
                    return false;
                },
                '[' => {
                    try next_positions.put(next_p, {});
                    try next_positions.put(.{ .x = next_p.x + 1, .y = next_p.y }, {});
                },
                ']' => {
                    try next_positions.put(.{ .x = next_p.x - 1, .y = next_p.y }, {});
                    try next_positions.put(next_p, {});
                },
                else => {},
            }
        }
    }

    if (try move(gpa, map, next_positions, dir)) {
        var tmp = std.AutoHashMap(Vec2, u8).init(gpa);
        defer tmp.deinit();

        var pos_iter = positions.keyIterator();
        while (pos_iter.next()) |p| {
            try tmp.put(p.*, getObject(map, p.*));
            setObject(map, p.*, '.');
        }

        pos_iter = positions.keyIterator();
        while (pos_iter.next()) |p| {
            const next_p = p.add(dir);
            setObject(map, next_p, tmp.get(p.*).?);
        }
        return true;
    }

    return false;
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

        const row = try gpa.alloc(u8, line.len * 2);
        var index: usize = 0;
        for (line) |ch| {
            switch (ch) {
                '#' => {
                    row[index] = '#';
                    row[index + 1] = '#';
                },
                'O' => {
                    row[index] = '[';
                    row[index + 1] = ']';
                },
                '.' => {
                    row[index] = '.';
                    row[index + 1] = '.';
                },
                '@' => {
                    row[index] = '@';
                    row[index + 1] = '.';
                },
                else => unreachable,
            }

            index += 2;
        }
        try map.append(row);
    }

    var p = findRobot(map.items);
    var set = Vec2Set.init(gpa);
    while (line_iter.next()) |line| {
        for (line) |dir_text| {
            set.clearRetainingCapacity();
            try set.put(p, {});
            const dir = parseDir(dir_text);
            if (try move(gpa, map.items, set, dir)) {
                p = p.add(dir);
            }
            // printMap(map.items);
        }
    }

    var sum: usize = 0;
    for (map.items, 0..) |row, y| {
        for (row, 0..) |cell, x| {
            if (cell == '[') {
                sum += 100 * y + x;
            }
        }
    }
    std.debug.print("{}\n", .{sum});
}
