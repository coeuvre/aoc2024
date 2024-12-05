const std = @import("std");

const input: [:0]const u8 = @embedFile("input.txt");

pub fn main() !void {
    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_state.allocator();

    var left_list = std.ArrayList(i32).init(gpa);
    var right_list = std.ArrayList(i32).init(gpa);

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        var location_iter = std.mem.tokenizeScalar(u8, line, ' ');

        const left = location_iter.next().?;
        try left_list.append(try std.fmt.parseInt(i32, left, 10));

        const right = location_iter.next().?;
        try right_list.append(try std.fmt.parseInt(i32, right, 10));
    }

    std.mem.sort(i32, left_list.items, {}, std.sort.asc(i32));
    std.mem.sort(i32, right_list.items, {}, std.sort.asc(i32));

    var diff: i32 = 0;
    for (left_list.items, right_list.items) |left, right| {
        diff += @intCast(@abs(left - right));
    }

    std.debug.print("{}\n", .{diff});
}
