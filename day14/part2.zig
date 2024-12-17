const std = @import("std");

const Vec2 = struct {
    x: i32,
    y: i32,
};

const Robot = struct {
    p: Vec2,
    v: Vec2,
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

fn continuousX(map: []const i32, size: Vec2, x: *usize, y: usize) u32 {
    var count: u32 = 0;
    while (x.* < size.x) {
        if (map[y * @as(usize, @intCast(size.x)) + x.*] == 0) {
            break;
        }
        x.* += 1;
        count += 1;
    }
    return count;
}

pub fn main() !void {
    const input: [:0]const u8 = @embedFile("input.txt");

    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_state.allocator();

    const size = Vec2{ .x = 101, .y = 103 };
    const map = try gpa.alloc(i32, size.y * size.x);

    var robots = std.ArrayList(Robot).init(gpa);
    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        var iter = std.mem.tokenizeScalar(u8, line, ' ');
        const p = try parseVec2(iter.next().?[2..]);
        const v = try parseVec2(iter.next().?[2..]);
        try robots.append(.{ .p = p, .v = v });
    }

    var time: usize = 1;
    while (true) : (time += 1) {
        @memset(map, 0);

        for (robots.items) |*robot| {
            step(&robot.p, robot.v, size);
            map[@intCast(robot.p.y * size.x + robot.p.x)] += 1;
        }

        var found = false;
        loop: for (0..size.y) |y| {
            var x: usize = 0;
            while (x < size.x) : (x += 1) {
                if (continuousX(map, size, &x, y) > 10) {
                    found = true;
                    break :loop;
                }
            }
        }

        if (found) {
            std.debug.print("Time: {}\n", .{time});
            for (0..size.y) |y| {
                for (0..size.x) |x| {
                    if (map[@intCast(y * size.x + x)] != 0) {
                        std.debug.print("*", .{});
                    } else {
                        std.debug.print(".", .{});
                    }
                }
                std.debug.print("\n", .{});
            }
            break;
        }
    }
}
