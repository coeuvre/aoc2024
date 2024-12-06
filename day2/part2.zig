const std = @import("std");

const Allocator = std.mem.Allocator;

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

fn isSafeReport(report: []const i32) bool {
    var level0 = report[0];
    var level1 = report[1];
    const dir = getDir(level0, level1);
    if (dir == .invalid) {
        return false;
    }
    level0 = level1;

    for (report[2..]) |level| {
        level1 = level;

        if (getDir(level0, level1) != dir) {
            return false;
        }

        level0 = level1;
    }

    return true;
}

fn isSafe(arena: Allocator, line: []const u8) !bool {
    var report = std.ArrayList(i32).init(arena);

    var level_iter = std.mem.tokenizeScalar(u8, line, ' ');
    while (level_iter.next()) |level_text| {
        const level = try std.fmt.parseInt(i32, level_text, 10);
        try report.append(level);
    }

    var report_ignoring_one = try arena.alloc(i32, report.items.len - 1);
    for (0..report.items.len) |ignoring| {
        std.mem.copyForwards(i32, report_ignoring_one, report.items[0..ignoring]);
        std.mem.copyForwards(i32, report_ignoring_one[ignoring..], report.items[ignoring + 1 ..]);
        if (isSafeReport(report_ignoring_one)) {
            return true;
        }
    }

    return false;
}

pub fn main() !void {
    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_state.allocator();
    var arena_state = std.heap.ArenaAllocator.init(gpa);
    const arena = arena_state.allocator();

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    var num_safe: i32 = 0;
    while (line_iter.next()) |line| {
        defer _ = arena_state.reset(.retain_capacity);

        if (try isSafe(arena, line)) {
            num_safe += 1;
        }
    }

    std.debug.print("{}\n", .{num_safe});
}
