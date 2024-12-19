const std = @import("std");

const Vec2 = struct {
    x: i32,
    y: i32,

    fn add(lhs: Vec2, rhs: Vec2) Vec2 {
        return .{ .x = lhs.x + rhs.x, .y = lhs.y + rhs.y };
    }

    fn eql(lhs: Vec2, rhs: Vec2) bool {
        return lhs.x == rhs.x and lhs.y == rhs.y;
    }
};

const Node = struct {
    p: Vec2,
    dir: Vec2,
    dist: i32,

    fn lessThan(_: void, a: Node, b: Node) std.math.Order {
        return std.math.order(a.dist, b.dist);
    }
};

fn findSymbol(map: []const []const u8, symbol: u8) ?Vec2 {
    for (map, 0..) |row, y| {
        for (row, 0..) |cell, x| {
            if (cell == symbol) {
                return Vec2{ .x = @intCast(x), .y = @intCast(y) };
            }
        }
    }
    return null;
}

fn rotate(dir: Vec2, delta: f32) Vec2 {
    const fdx: f32 = @floatFromInt(dir.x);
    const fdy: f32 = @floatFromInt(dir.y);
    const rad = std.math.atan2(fdy, fdx);
    const new_rad = rad + delta;
    return .{
        .x = @intFromFloat(std.math.cos(new_rad)),
        .y = @intFromFloat(std.math.sin(new_rad)),
    };
}

fn isEmpty(map: []const []const u8, p: Vec2) bool {
    if (p.y < 0 or p.y >= map.len) {
        return false;
    }
    const row = map[@intCast(p.y)];
    if (p.x < 0 or p.x >= row.len) {
        return false;
    }
    const cell = row[@intCast(p.x)];
    return cell != '#';
}

const DistMap = std.AutoHashMap(Vec2, i32);
const NodePriorityQueue = std.PriorityQueue(Node, void, Node.lessThan);

fn updateNode(map: []const []const u8, p: Vec2, dir: Vec2, dist: i32, dist_map: *DistMap, pq: *NodePriorityQueue) !void {
    if (!isEmpty(map, p)) {
        return;
    }

    var min_dist: i32 = std.math.maxInt(i32);
    if (dist_map.get(p)) |d| {
        min_dist = d;
    }
    if (dist < min_dist) {
        const new_node: Node = .{ .p = p, .dir = dir, .dist = dist };
        try pq.add(new_node);
        try dist_map.put(new_node.p, new_node.dist);
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

    const start = findSymbol(map.items, 'S').?;
    const end = findSymbol(map.items, 'E').?;

    var dist_map = DistMap.init(gpa);
    var pq = NodePriorityQueue.init(gpa, {});
    try updateNode(map.items, start, .{ .x = 1, .y = 0 }, 0, &dist_map, &pq);

    // dijkstra
    while (pq.removeOrNull()) |node| {
        if (node.p.eql(end)) {
            break;
        }

        var dir = node.dir;
        try updateNode(map.items, node.p.add(dir), dir, node.dist + 1, &dist_map, &pq);

        dir = rotate(node.dir, std.math.pi / 2.0);
        try updateNode(map.items, node.p.add(dir), dir, node.dist + 1001, &dist_map, &pq);

        dir = rotate(node.dir, -std.math.pi / 2.0);
        try updateNode(map.items, node.p.add(dir), dir, node.dist + 1001, &dist_map, &pq);

        dir = rotate(node.dir, std.math.pi);
        try updateNode(map.items, node.p.add(dir), dir, node.dist + 2001, &dist_map, &pq);
    }

    std.debug.print("{}\n", .{dist_map.get(end).?});
}
