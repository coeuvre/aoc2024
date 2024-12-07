const std = @import("std");

const Op = enum {
    add,
    mul,
    con,
};

fn countDigit(value: i64) i64 {
    if (value == 0) {
        return 1;
    }

    var digit: i64 = 0;
    var v = value;
    while (v != 0) {
        v = @divTrunc(v, 10);
        digit += 1;
    }
    return digit;
}

fn tryOp(test_value: i64, numbers: []const i64, value: i64, i: usize, op: Op) bool {
    var new_value = value;
    switch (op) {
        .add => {
            new_value = value + numbers[i];
        },
        .mul => {
            new_value = value * numbers[i];
        },
        .con => {
            const rhs = numbers[i];
            const digit = countDigit(rhs);
            new_value = value * (std.math.powi(i64, 10, digit) catch unreachable) + rhs;
        },
    }

    if (i == numbers.len - 1) {
        return test_value == new_value;
    }

    return tryPos(test_value, numbers, new_value, i + 1);
}

fn tryPos(test_value: i64, numbers: []const i64, value: i64, i: usize) bool {
    inline for (std.meta.fields(Op)) |op| {
        if (tryOp(test_value, numbers, value, i, @field(Op, op.name))) {
            return true;
        }
    }
    return false;
}

fn solve(test_value: i64, numbers: []const i64) bool {
    if (numbers.len == 1) {
        return test_value == numbers[0];
    }

    return tryPos(test_value, numbers, numbers[0], 1);
}

pub fn main() !void {
    const input: [:0]const u8 = @embedFile("input.txt");

    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_state.allocator();

    var arena_state = std.heap.ArenaAllocator.init(gpa);
    const arena = arena_state.allocator();

    var sum: i64 = 0;
    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        defer _ = arena_state.reset(.retain_capacity);

        var equation_iter = std.mem.tokenizeScalar(u8, line, ':');
        const test_value = try std.fmt.parseInt(i64, equation_iter.next().?, 10);

        var numbers = std.ArrayList(i64).init(arena);
        var number_iter = std.mem.tokenizeScalar(u8, equation_iter.next().?, ' ');
        while (number_iter.next()) |number| {
            try numbers.append(try std.fmt.parseInt(i64, number, 10));
        }

        if (solve(test_value, numbers.items)) {
            sum += test_value;
        }
    }

    std.debug.print("{}\n", .{sum});
}
