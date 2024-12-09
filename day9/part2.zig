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

    var file_last_index: usize = disk.items.len - 1;
    while (true) {
        while (file_last_index > 0 and disk.items[file_last_index] < 0) {
            file_last_index -= 1;
        }
        if (file_last_index == 0) {
            break;
        }

        var k: usize = file_last_index;
        while (k > 0 and disk.items[k] == disk.items[file_last_index]) {
            k -= 1;
        }
        if (k == 0) {
            break;
        }
        const file_first_index = k + 1;
        const file_len = file_last_index - file_first_index + 1;

        var free_first_index: usize = 0;
        while (true) {
            while (free_first_index < file_first_index and disk.items[free_first_index] >= 0) {
                free_first_index += 1;
            }
            if (free_first_index >= file_first_index) {
                break;
            }

            var free_last_index = free_first_index;
            while (free_last_index < file_first_index and disk.items[free_last_index] < 0) {
                free_last_index += 1;
            }
            free_last_index -= 1;

            if (free_last_index >= file_first_index) {
                break;
            }

            const free_len = free_last_index - free_first_index + 1;
            if (free_len >= file_len) {
                for (disk.items[free_first_index .. free_first_index + file_len], disk.items[file_first_index .. file_first_index + file_len]) |*free, *file| {
                    std.mem.swap(i32, free, file);
                }
                break;
            }

            free_first_index = free_last_index + 1;
        }

        file_last_index = file_first_index - 1;
    }

    var checksum: usize = 0;
    for (disk.items, 0..) |id, pos| {
        if (id >= 0) {
            checksum += @as(usize, @intCast(id)) * pos;
        }
    }

    std.debug.print("{}\n", .{checksum});
}
