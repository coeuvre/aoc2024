const std = @import("std");

const Vec2 = struct {
    x: i32,
    y: i32,

    fn add(lhs: Vec2, rhs: Vec2) Vec2 {
        return .{
            .x = lhs.x + rhs.x,
            .y = lhs.y + rhs.y,
        };
    }

    fn eql(lhs: Vec2, rhs: Vec2) bool {
        return lhs.x == rhs.x and lhs.y == rhs.y;
    }
};

const Node = struct {
    pos: Vec2,
    dist: i32,

    fn lessThan(_: void, a: Node, b: Node) std.math.Order {
        return std.math.order(a.dist, b.dist);
    }
};

const NodePriorityQueue = std.PriorityQueue(Node, void, Node.lessThan);
const DistMap = std.AutoHashMap(Vec2, i32);

fn findObject(map: []const []const u8, target: u8) ?Vec2 {
    for (map, 0..) |row, y| {
        for (row, 0..) |cell, x| {
            if (cell == target) {
                return Vec2{ .x = @intCast(x), .y = @intCast(y) };
            }
        }
    }
    return null;
}

fn visit(map: []const []const u8, pq: *NodePriorityQueue, dist_map: *DistMap, node: Node) !void {
    if (getObject(map, node.pos) == '#') {
        return;
    }

    var min_dist: i32 = std.math.maxInt(i32);
    if (dist_map.get(node.pos)) |dist| {
        min_dist = dist;
    }
    if (node.dist < min_dist) {
        try pq.add(node);
        try dist_map.put(node.pos, node.dist);
    }
}

fn getObject(map: []const []const u8, pos: Vec2) u8 {
    if (pos.y < 0 or pos.y >= map.len) {
        return '#';
    }
    const row = map[@intCast(pos.y)];
    if (pos.x < 0 or pos.x >= row.len) {
        return '#';
    }
    return row[@intCast(pos.x)];
}

const dirs: []const Vec2 = &.{
    .{ .x = -1, .y = 0 },
    .{ .x = 1, .y = 0 },
    .{ .x = 0, .y = -1 },
    .{ .x = 0, .y = 1 },
};

const cheat_count: i32 = 20;
fn cheat(map: []const []const u8, dist_map: DistMap, start: Vec2, total: *i32) !void {
    const dist_to_start = dist_map.get(start).?;

    var dy = -cheat_count;
    while (dy <= cheat_count) : (dy += 1) {
        var dx = -cheat_count;
        while (dx <= cheat_count) : (dx += 1) {
            const adx: i32 = @intCast(@abs(dx));
            const ady: i32 = @intCast(@abs(dy));
            if (adx + ady > cheat_count) {
                continue;
            }

            const end = .{ .x = start.x + dx, .y = start.y + dy };
            if (getObject(map, end) == '#') {
                continue;
            }

            const dist = dist_map.get(end).?;
            const dist_if_cheat = dist_to_start + adx + ady;
            if (dist - dist_if_cheat >= 100) {
                total.* += 1;
            }
        }
    }
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

    const start = findObject(map.items, 'S').?;

    var dist_map = DistMap.init(gpa);
    var pq = NodePriorityQueue.init(gpa, {});
    try pq.add(Node{ .pos = start, .dist = 0 });
    try dist_map.put(start, 0);

    while (pq.removeOrNull()) |node| {
        for (dirs) |dir| {
            try visit(map.items, &pq, &dist_map, .{ .pos = node.pos.add(dir), .dist = node.dist + 1 });
        }
    }

    var total: i32 = 0;
    for (map.items, 0..) |row, y| {
        for (row, 0..) |cell, x| {
            if (cell != '#') {
                const pos = Vec2{ .x = @intCast(x), .y = @intCast(y) };
                try cheat(map.items, dist_map, pos, &total);
            }
        }
    }

    std.debug.print("{}\n", .{total});
}
