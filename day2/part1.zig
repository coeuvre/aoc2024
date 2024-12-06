const std = @import("std");

const input: [:0]const u8 = @embedFile("input.txt");

const Dir = enum {
    invalid,
    incresing,
    decresing,
};

fn getDir(level0: i32, level1: i32) Dir {
    const diff = level1 - level0;
    const abs_diff = @abs(diff);
    if (abs_diff < 1 or abs_diff > 3 or diff == 0) {
        return .invalid;
    }

    return if (diff > 0) .incresing else .decresing;
}

fn isSafe(line: []const u8) !bool {
    var level_iter = std.mem.tokenizeScalar(u8, line, ' ');
    var level0 = try std.fmt.parseInt(i32, level_iter.next().?, 10);
    var level1 = try std.fmt.parseInt(i32, level_iter.next().?, 10);
    const dir = getDir(level0, level1);
    if (dir == .invalid) {
        return false;
    }
    level0 = level1;

    while (level_iter.next()) |level_text| {
        level1 = try std.fmt.parseInt(i32, level_text, 10);

        if (getDir(level0, level1) != dir) {
            return false;
        }

        level0 = level1;
    }

    return true;
}

pub fn main() !void {
    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    var num_safe: i32 = 0;
    while (line_iter.next()) |line| {
        if (try isSafe(line)) {
            num_safe += 1;
        }
    }

    std.debug.print("{}\n", .{num_safe});
}
