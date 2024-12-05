const std = @import("std");

const input: [:0]const u8 = @embedFile("input.txt");

pub fn main() !void {
    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_state.allocator();

    var left_list = std.ArrayList(i32).init(gpa);
    var right_map = std.AutoHashMap(i32, i32).init(gpa);

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        var location_iter = std.mem.tokenizeScalar(u8, line, ' ');

        const left = location_iter.next().?;
        try left_list.append(try std.fmt.parseInt(i32, left, 10));

        const right = location_iter.next().?;
        const entry = try right_map.getOrPut(try std.fmt.parseInt(i32, right, 10));
        if (!entry.found_existing) {
            entry.value_ptr.* = 0;
        }
        entry.value_ptr.* += 1;
    }

    var score: i32 = 0;
    for (left_list.items) |left| {
        const times = right_map.get(left) orelse 0;
        score += left * times;
    }

    std.debug.print("{}\n", .{score});
}
