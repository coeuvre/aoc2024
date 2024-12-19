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

const NodePos = struct {
    p: Vec2,
    dir: Vec2,
};

const Node = struct {
    p: NodePos,
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

const DistMap = std.AutoHashMap(NodePos, i32);
const PrevMap = std.AutoHashMap(NodePos, std.ArrayList(NodePos));
const NodePriorityQueue = std.PriorityQueue(Node, void, Node.lessThan);
const Vec2Set = std.AutoHashMap(Vec2, void);

fn updateNode(map: []const []const u8, prev_p: ?NodePos, p: NodePos, dist: i32, dist_map: *DistMap, pq: *NodePriorityQueue, prev_map: *PrevMap) !void {
    if (!isEmpty(map, p.p)) {
        return;
    }

    var min_dist: i32 = std.math.maxInt(i32);
    if (dist_map.get(p)) |d| {
        min_dist = d;
    }
    if (dist < min_dist) {
        const new_node: Node = .{ .p = p, .dist = dist };
        try pq.add(new_node);
        try dist_map.put(p, new_node.dist);

        var prev = try prev_map.getOrPut(p);
        if (!prev.found_existing) {
            prev.value_ptr.* = std.ArrayList(NodePos).init(prev_map.allocator);
        }
        prev.value_ptr.clearRetainingCapacity();
        if (prev_p) |pp| {
            try prev.value_ptr.append(pp);
        }
    } else if (dist == min_dist) {
        if (prev_p) |pp| {
            try prev_map.getPtr(p).?.append(pp);
        }
    }
}

fn count(prev_map: PrevMap, p: NodePos, set: *Vec2Set) !void {
    try set.put(p.p, {});
    for (prev_map.get(p).?.items) |pp| {
        try count(prev_map, pp, set);
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
    var prev_map = PrevMap.init(gpa);
    var pq = NodePriorityQueue.init(gpa, {});
    try updateNode(map.items, null, .{ .p = start, .dir = .{ .x = 1, .y = 0 } }, 0, &dist_map, &pq, &prev_map);

    // dijkstra
    var end_dir = Vec2{ .x = 0, .y = 0 };
    while (pq.removeOrNull()) |node| {
        if (node.p.p.eql(end)) {
            end_dir = node.p.dir;
            break;
        }

        try updateNode(map.items, node.p, .{ .p = node.p.p.add(node.p.dir), .dir = node.p.dir }, node.dist + 1, &dist_map, &pq, &prev_map);
        try updateNode(map.items, node.p, .{ .p = node.p.p, .dir = rotate(node.p.dir, std.math.pi / 2.0) }, node.dist + 1000, &dist_map, &pq, &prev_map);
        try updateNode(map.items, node.p, .{ .p = node.p.p, .dir = rotate(node.p.dir, -std.math.pi / 2.0) }, node.dist + 1000, &dist_map, &pq, &prev_map);
        try updateNode(map.items, node.p, .{ .p = node.p.p, .dir = rotate(node.p.dir, std.math.pi) }, node.dist + 1000, &dist_map, &pq, &prev_map);
    }

    var set = Vec2Set.init(gpa);
    try count(prev_map, .{ .p = end, .dir = end_dir }, &set);

    // for (map.items, 0..) |row, y| {
    //     for (row, 0..) |cell, x| {
    //         const p = Vec2{ .x = @intCast(x), .y = @intCast(y) };
    //         if (set.contains(p)) {
    //             std.debug.print("O", .{});
    //         } else {
    //             std.debug.print("{c}", .{cell});
    //         }
    //     }
    //     std.debug.print("\n", .{});
    // }
    std.debug.print("{}\n", .{set.count()});
}
