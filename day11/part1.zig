const std = @import("std");

fn removeLeadingZeros(input: []const u8) []const u8 {
    if (input.len <= 1) {
        return input;
    }

    var i: usize = 0;
    while (i < input.len - 1) {
        if (input[i] != '0') {
            break;
        }
        i += 1;
    }
    return input[i..];
}

pub fn main() !void {
    const input: [:0]const u8 = @embedFile("input.txt");

    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_state.allocator();

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    var stone_iter = std.mem.tokenizeScalar(u8, line_iter.next().?, ' ');
    var stones = std.ArrayList([]const u8).init(gpa);
    while (stone_iter.next()) |stone| {
        try stones.append(stone);
    }

    for (0..25) |_| {
        var i: usize = 0;
        while (i < stones.items.len) : (i += 1) {
            const stone = stones.items[i];
            if (std.mem.eql(u8, stone, "0")) {
                stones.items[i] = "1";
            } else if (stone.len % 2 == 0) {
                const left = stone[0 .. stone.len / 2];
                const right = removeLeadingZeros(stone[stone.len / 2 ..]);
                stones.items[i] = left;
                i += 1;
                try stones.insert(i, right);
            } else {
                const n = try std.fmt.parseInt(i64, stone, 10);
                stones.items[i] = try std.fmt.allocPrint(gpa, "{}", .{n * 2024});
            }
        }
    }

    std.debug.print("{}\n", .{stones.items.len});
}
