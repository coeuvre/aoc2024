const std = @import("std");

fn skipUntil(buf: []const u8, cursor: *u32, target: u8) bool {
    while (cursor.* < buf.len) {
        if (buf[cursor.*] == target) {
            return true;
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

fn parseMul(buf: []const u8, cursor: *u32, left: *u32, right: *u32) bool {
    while (cursor.* < buf.len) {
        if (!skipUntil(buf, cursor, 'm')) {
            return false;
        }

        if (!expectSeq(buf, cursor, "mul(")) {
            continue;
        }

        if (!expectNum(buf, cursor, left)) {
            continue;
        }

        if (!expectSeq(buf, cursor, ",")) {
            continue;
        }

        if (!expectNum(buf, cursor, right)) {
            continue;
        }

        if (!expectSeq(buf, cursor, ")")) {
            continue;
        }

        return true;
    }

    return false;
}

pub fn main() !void {
    const input: [:0]const u8 = @embedFile("input.txt");

    var cursor: u32 = 0;
    var left: u32 = undefined;
    var right: u32 = undefined;
    var sum: u32 = 0;
    while (parseMul(input, &cursor, &left, &right)) {
        sum += left * right;
    }

    std.debug.print("{}\n", .{sum});
}
