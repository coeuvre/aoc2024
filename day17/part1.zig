const std = @import("std");

const Opcode = enum(u3) {
    adv, // A = A / 2^operand(combo)
    bxl, // B = B XOR operand(literal)
    bst, // B = operand(combo) % 8
    jnz, // IP = operand(literal) if A != 0
    bxc, // B = B XOR C
    out, // Output operand(combo) % 8
    bdv, // B = A / 2^operand(combo)
    cdv, // C = A / 2^operand(combo)
};

const Computer = struct {
    reg_a: u32,
    reg_b: u32,
    reg_c: u32,
    ip: u32,

    fn getComboValue(computer: Computer, operand: u3) u32 {
        switch (operand) {
            0, 1, 2, 3 => {
                return operand;
            },
            4 => {
                return computer.reg_a;
            },
            5 => {
                return computer.reg_b;
            },
            6 => {
                return computer.reg_c;
            },
            7 => unreachable,
        }
    }

    fn execute(self: *Computer, program: []const u3, output: *std.ArrayList(u8)) !void {
        while (self.ip < program.len - 1) {
            const opcode: Opcode = @enumFromInt(program[self.ip]);
            const operand = program[self.ip + 1];
            self.ip += 2;

            switch (opcode) {
                .adv => {
                    self.reg_a = self.reg_a / try std.math.powi(u32, 2, self.getComboValue(operand));
                },
                .bxl => {
                    self.reg_b = self.reg_b ^ operand;
                },
                .bst => {
                    self.reg_b = self.getComboValue(operand) % 8;
                },
                .jnz => {
                    if (self.reg_a != 0) {
                        self.ip = operand;
                    }
                },
                .bxc => {
                    self.reg_b = self.reg_b ^ self.reg_c;
                },
                .out => {
                    if (output.items.len > 0) {
                        try output.append(',');
                    }
                    try output.append('0' + @as(u8, @intCast(self.getComboValue(operand) % 8)));
                },
                .bdv => {
                    self.reg_b = self.reg_a / try std.math.powi(u32, 2, self.getComboValue(operand));
                },
                .cdv => {
                    self.reg_c = self.reg_a / try std.math.powi(u32, 2, self.getComboValue(operand));
                },
            }

            // std.debug.print("{s} {} => A={}, B={}, C={}, IP={}\n", .{ @tagName(opcode), operand, self.reg_a, self.reg_b, self.reg_c, self.ip });
        }
    }
};

fn getTextAfterColon(text: []const u8) []const u8 {
    const pattern = ": ";
    const index = std.mem.indexOf(u8, text, pattern).?;
    return text[index + pattern.len ..];
}

pub fn main() !void {
    const input: [:0]const u8 = @embedFile("input.txt");

    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_state.allocator();

    var line_iter = std.mem.splitScalar(u8, input, '\n');
    const register_a_text = line_iter.next().?;
    const register_b_text = line_iter.next().?;
    const register_c_text = line_iter.next().?;
    _ = line_iter.next().?;
    const program_text = line_iter.next().?;

    var computer = Computer{
        .reg_a = try std.fmt.parseInt(u32, getTextAfterColon(register_a_text), 10),
        .reg_b = try std.fmt.parseInt(u32, getTextAfterColon(register_b_text), 10),
        .reg_c = try std.fmt.parseInt(u32, getTextAfterColon(register_c_text), 10),
        .ip = 0,
    };

    var program = std.ArrayList(u3).init(gpa);
    var output = std.ArrayList(u8).init(gpa);
    var ins_iter = std.mem.tokenizeScalar(u8, getTextAfterColon(program_text), ',');
    while (ins_iter.next()) |ins| {
        try program.append(try std.fmt.parseInt(u3, ins, 10));
    }

    try computer.execute(program.items, &output);

    std.debug.print("{s}\n", .{output.items});
}
