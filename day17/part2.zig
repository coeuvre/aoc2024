const std = @import("std");

// Program: 2,4,1,5,7,5,1,6,4,3,5,5,0,3,3,0
//
// 8^n => n + 1 digits
//
// A starts from 8^15
//
// delta   change of digits
//  8^0 =>   0
//  8^1 => [0,1]
//  8^2 => [0,2]
//  ...
//  8^n => [0,n]

// Mangually translate the bytecode into zig.
fn run(init_a: u64, output: *std.ArrayList(u8)) !void {
    var a = init_a;
    while (true) {
        var b = a & 0b111;
        b = b ^ 0b101;
        const c = a >> @intCast(b);
        b = b ^ 0b110;
        b = b ^ c;
        try output.append(@as(u8, @intCast(b & 0b111)));
        a = a >> 3;
        if (a == 0) {
            break;
        }
    }
}

fn print(n: u64, a: u64, output: []const u8) void {
    std.debug.print("n = {d:02}, {o} => ", .{ n, a });
    for (output, 0..) |o, i| {
        if (i > 0) {
            std.debug.print(",", .{});
        }
        std.debug.print("{}", .{o});
    }
    std.debug.print("\n", .{});
}

fn dfs(target: []const u8, output: *std.ArrayList(u8), a_init: u64, n: u64) !?u64 {
    var a = a_init;
    for (0..8) |_| {
        output.clearRetainingCapacity();

        try run(a, output);
        print(n, a, output.items);

        if (std.mem.eql(u8, target, output.items)) {
            return a;
        }

        if (target[n] == output.items[n]) {
            if (try dfs(target, output, a, n - 1)) |result| {
                return result;
            }
        }

        a += try std.math.powi(u64, 8, n);
    }
    return null;
}

pub fn main() !void {
    const target: []const u8 = &.{ 2, 4, 1, 5, 7, 5, 1, 6, 4, 3, 5, 5, 0, 3, 3, 0 };
    var output = std.ArrayList(u8).init(std.heap.page_allocator);
    const n: u64 = target.len - 1;
    const a = (try dfs(target, &output, try std.math.powi(u64, 8, n), n)).?;
    std.debug.print("{}\n", .{a});
}
