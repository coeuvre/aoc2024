const std = @import("std");

const HashSetI32 = std.AutoHashMap(i32, void);

fn hasIntersection(a: *const HashSetI32, b: *const HashSetI32) bool {
    var a_key_iter = a.keyIterator();
    while (a_key_iter.next()) |a_key| {
        if (b.get(a_key)) |_| {
            return true;
        }
    }
    return false;
}

pub fn main() !void {
    const input: [:0]const u8 = @embedFile("input.txt");

    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_state.allocator();

    var ordering_rules = std.AutoHashMap(i32, HashSetI32).init(gpa);

    var line_iter = std.mem.splitScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        if (line.len == 0) {
            break;
        }
        var page_iter = std.mem.tokenizeScalar(u8, line, '|');
        const x = try std.fmt.parseInt(i32, page_iter.next().?, 10);
        const y = try std.fmt.parseInt(i32, page_iter.next().?, 10);

        const entry = try ordering_rules.getOrPut(x);
        if (!entry.found_existing) {
            entry.value_ptr.* = HashSetI32.init(gpa);
        }
        try entry.value_ptr.put(y, {});
    }

    var sum: i32 = 0;
    var arena_state = std.heap.ArenaAllocator.init(gpa);
    const arena = arena_state.allocator();
    while (line_iter.next()) |line| {
        if (line.len == 0) {
            break;
        }
        defer _ = arena_state.reset(.retain_capacity);

        var valid = true;
        var page_iter = std.mem.tokenizeScalar(u8, line, ',');
        var pages = std.ArrayList(i32).init(arena);
        while (page_iter.next()) |page_text| {
            const page = try std.fmt.parseInt(i32, page_text, 10);
            var inserted = false;

            if (ordering_rules.getPtr(page)) |not_allowed_pages| {
                for (pages.items, 0..) |already_printed_page, index| {
                    if (not_allowed_pages.get(already_printed_page)) |_| {
                        valid = false;
                        try pages.insert(index, page);
                        inserted = true;
                        break;
                    }
                }
            }

            if (!inserted) {
                try pages.append(page);
            }
        }

        if (!valid) {
            sum += pages.items[pages.items.len / 2];
        }
    }

    std.debug.print("{}\n", .{sum});
}
