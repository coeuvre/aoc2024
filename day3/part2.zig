const std = @import("std");

fn skipUntilAny(buf: []const u8, cursor: *u32, target: []const u8) bool {
    while (cursor.* < buf.len) {
        const ch = buf[cursor.*];
        for (target) |t| {
            if (t == ch) {
                return true;
            }
        }
        cursor.* += 1;
    }
    return false;
}

fn expectSeq(buf: []const u8, cursor: *u32, target: []const u8) bool {
    for (target) |ch| {
        if (cursor.* >= buf.len) {
            return false;
        }
        if (buf[cursor.*] != ch) {
            return false;
        }
        cursor.* += 1;
    }
    return true;
}

fn expectNum(buf: []const u8, cursor: *u32, num: *u32) bool {
    var n: u32 = 0;
    var has_num = false;
    while (cursor.* < buf.len) {
        const ch = buf[cursor.*];
        if (ch >= '0' and ch <= '9') {
            n = n * 10 + ch - '0';
            has_num = true;
            cursor.* += 1;
        } else {
            break;
        }
    }
    num.* = n;
    return has_num;
}

fn expectMul(buf: []const u8, cursor: *u32, left: *u32, right: *u32) bool {
    if (!expectSeq(buf, cursor, "mul(")) {
        return false;
    }

    if (!expectNum(buf, cursor, left)) {
        return false;
    }

    if (!expectSeq(buf, cursor, ",")) {
        return false;
    }

    if (!expectNum(buf, cursor, right)) {
        return false;
    }

    if (!expectSeq(buf, cursor, ")")) {
        return false;
    }

    return true;
}

fn parseMulOrDont(buf: []const u8, cursor: *u32, is_mul: *bool, left: *u32, right: *u32) bool {
    while (cursor.* < buf.len) {
        if (!skipUntilAny(buf, cursor, "md")) {
            return false;
        }

        if (buf[cursor.*] == 'm') {
            if (!expectMul(buf, cursor, left, right)) {
                continue;
            }
            is_mul.* = true;
            return true;
        } else {
            if (!expectSeq(buf, cursor, "don't()")) {
                continue;
            }
            is_mul.* = false;
            return true;
        }
    }

    return false;
}

fn parseDo(buf: []const u8, cursor: *u32) bool {
    while (cursor.* < buf.len) {
        if (!skipUntilAny(buf, cursor, "d")) {
            return false;
        }

        if (!expectSeq(buf, cursor, "do()")) {
            continue;
        }

        return true;
    }

    return false;
}

pub fn main() !void {
    const input: [:0]const u8 = @embedFile("input.txt");

    var enabled = true;
    var cursor: u32 = 0;
    var sum: u32 = 0;
    parse_loop: while (true) {
        if (enabled) {
            while (true) {
                var is_mul: bool = undefined;
                var left: u32 = undefined;
                var right: u32 = undefined;
                if (!parseMulOrDont(input, &cursor, &is_mul, &left, &right)) {
                    break :parse_loop;
                }
                if (is_mul) {
                    sum += left * right;
                } else {
                    enabled = false;
                    break;
                }
            }
        } else {
            if (!parseDo(input, &cursor)) {
                break;
            }
            enabled = true;
        }
    }

    std.debug.assert(cursor == input.len);
    std.debug.print("{}\n", .{sum});
}
