const std = @import("std");

const Vec2 = struct {
    x: f64,
    y: f64,
};

fn parseNumber(text: []const u8, prefix: u8) !i64 {
    const i = std.mem.indexOfScalar(u8, text, prefix).?;
    return try std.fmt.parseInt(i64, text[i + 2 ..], 10);
}

fn parseVec2(text: []const u8) !Vec2 {
    var iter = std.mem.tokenizeScalar(u8, text, ',');
    return Vec2{
        .x = @floatFromInt(try parseNumber(iter.next().?, 'X')),
        .y = @floatFromInt(try parseNumber(iter.next().?, 'Y')),
    };
}

pub fn main() !void {
    const input: [:0]const u8 = @embedFile("input.txt");

    var total: i64 = 0;
    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |button_a_text| {
        const button_b_text = line_iter.next().?;
        const prize_text = line_iter.next().?;

        const a = try parseVec2(button_a_text);
        const b = try parseVec2(button_b_text);
        const p = try parseVec2(prize_text);

        const c = (a.x * b.y - b.x * a.y);
        const x = (b.y * p.x - b.x * p.y) / c;
        const y = (a.x * p.y - a.y * p.x) / c;
        if (@round(x) == x and @round(y) == y) {
            const token = @as(i64, @intFromFloat(x)) * 3 + @as(i64, @intFromFloat(y)) * 1;
            total += token;
        }
    }

    std.debug.print("{}\n", .{total});
}
