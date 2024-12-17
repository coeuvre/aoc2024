const std = @import("std");

const Vec2 = struct {
    x: i32,
    y: i32,
};

fn parseVec2(text: []const u8) !Vec2 {
    var iter = std.mem.tokenizeScalar(u8, text, ',');
    return Vec2{
        .x = try std.fmt.parseInt(i32, iter.next().?, 10),
        .y = try std.fmt.parseInt(i32, iter.next().?, 10),
    };
}

fn step(p: *Vec2, v: Vec2, size: Vec2) void {
    p.x = @mod(p.x + v.x, size.x);
    p.y = @mod(p.y + v.y, size.y);
}

pub fn main() !void {
    const input: [:0]const u8 = @embedFile("input.txt");

    const size = Vec2{ .x = 101, .y = 103 };
    const time = 100;
    var scores: [4]i32 = .{ 0, 0, 0, 0 };

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        var iter = std.mem.tokenizeScalar(u8, line, ' ');
        var p = try parseVec2(iter.next().?[2..]);
        const v = try parseVec2(iter.next().?[2..]);
        for (0..time) |_| {
            step(&p, v, size);
        }
        if (p.x == size.x / 2 or p.y == size.y / 2) {
            continue;
        }
        const qx: usize = if (p.x < size.x / 2) 0 else 1;
        const qy: usize = if (p.y < size.y / 2) 0 else 1;
        scores[qy * 2 + qx] += 1;
    }

    std.debug.print("{}\n", .{scores[0] * scores[1] * scores[2] * scores[3]});
}
