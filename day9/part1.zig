const std = @import("std");

pub fn main() !void {
    const input: [:0]const u8 = @embedFile("input.txt");

    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_state.allocator();

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');

    var disk = std.ArrayList(i32).init(gpa);
    {
        var file_id: i32 = 0;
        var digit_is_file = true;
        for (line_iter.next().?) |ch| {
            if (ch == '\n') {
                break;
            }

            const digit = ch - '0';
            if (digit_is_file) {
                try disk.appendNTimes(file_id, digit);
                file_id += 1;
            } else {
                try disk.appendNTimes(-1, digit);
            }
            digit_is_file = !digit_is_file;
        }
    }

    var i: usize = 0;
    var j: usize = disk.items.len - 1;
    while (i < j) {
        while (i < disk.items.len and disk.items[i] >= 0) {
            i += 1;
        }

        while (j > i and disk.items[j] < 0) {
            j -= 1;
        }

        if (i < j) {
            std.mem.swap(i32, &disk.items[i], &disk.items[j]);
            i -= 1;
            j -= 1;
        }
    }

    var checksum: usize = 0;
    for (disk.items, 0..) |id, pos| {
        if (id < 0) {
            break;
        }

        checksum += @as(usize, @intCast(id)) * pos;
    }

    std.debug.print("{}\n", .{checksum});
}
