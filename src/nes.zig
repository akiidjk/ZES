const std = @import("std");

const NES = struct {
    memory: u8[2048],
    cpu: CPU,

    fn init() NES {
        const allocator = std.heap.page_allocator;
        return NES{ .memory = try allocator.alloc(u8, 2048), .cpu = CPU{ .PC = 0, .SP = 0, .A = 0, .X = 0, .Y = 0, .P = 0 } };
    }
};

const CPU = struct {
    PC: u16, // Memory space: 0x0100 .. 0x1FF
    SP: u8,
    A: u8,
    X: u8,
    Y: u8,
    P: u8,

    fn interpret(program: []u8) void {
        _ = program;
    }
};
