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

fn visit(map: []const u8, dim: i32, pq: *NodePriorityQueue, dist_map: *DistMap, node: Node) !void {
    if (node.pos.y < 0 or node.pos.y >= dim or
        node.pos.x < 0 or node.pos.x >= dim)
    {
        return;
    }
    const cell = map[@intCast(node.pos.y * dim + node.pos.x)];
    if (cell == '#') {
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

fn hasExit(arena: std.mem.Allocator, dim: i32, pos_list: []const Vec2) !bool {
    const map = try arena.alloc(u8, @intCast(dim * dim));
    for (pos_list) |p| {
        map[@intCast(p.y * dim + p.x)] = '#';
    }

    const start = Vec2{ .x = 0, .y = 0 };
    const end = Vec2{ .x = dim - 1, .y = dim - 1 };

    var dist_map = DistMap.init(arena);
    var pq = NodePriorityQueue.init(arena, {});
    try pq.add(Node{ .pos = start, .dist = 0 });
    try dist_map.put(start, 0);

    while (pq.removeOrNull()) |node| {
        if (node.pos.eql(end)) {
            break;
        }

        const dirs: []const Vec2 = &.{
            .{ .x = -1, .y = 0 },
            .{ .x = 1, .y = 0 },
            .{ .x = 0, .y = -1 },
            .{ .x = 0, .y = 1 },
        };
        for (dirs) |dir| {
            try visit(map, dim, &pq, &dist_map, .{ .pos = node.pos.add(dir), .dist = node.dist + 1 });
        }
    }

    return dist_map.get(end) != null;
}

const Context = struct {
    arena: std.mem.Allocator,
    dim: i32,
    pos_list: []const Vec2,
};

fn predicate(context: Context, index: usize) bool {
    return hasExit(context.arena, context.dim, context.pos_list[0..(index + 1)]) catch unreachable;
}

pub fn main() !void {
    const input: [:0]const u8 = @embedFile("input.txt");

    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_state.allocator();
    var arena_state = std.heap.ArenaAllocator.init(gpa);
    const arena = arena_state.allocator();

    const dim: i32 = 71;

    var pos_list = std.ArrayList(Vec2).init(gpa);
    var index_list = std.ArrayList(usize).init(gpa);
    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        var num_iter = std.mem.tokenizeScalar(u8, line, ',');
        const p = Vec2{
            .x = try std.fmt.parseInt(i32, num_iter.next().?, 10),
            .y = try std.fmt.parseInt(i32, num_iter.next().?, 10),
        };
        try pos_list.append(p);
        try index_list.append(index_list.items.len);
    }

    const context = Context{
        .arena = arena,
        .dim = dim,
        .pos_list = pos_list.items,
    };
    const i = std.sort.partitionPoint(usize, index_list.items, context, predicate);
    const p = pos_list.items[i];
    std.debug.print("{},{}\n", .{ p.x, p.y });
}
