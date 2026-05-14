const std = @import("std");
const logger = @import("logging").log;
const nesLog = @import("logging").nes;

const AddressingMode = enum {
    Immediate,
    ZeroPage,
    ZeroPage_X,
    ZeroPage_Y,
    Absolute,
    Absolute_X,
    Absolute_Y,
    Indirect_X,
    Indirect_Y,
    NoneAddressing,
};

pub const CPU = struct {
    PC: u16, // Memory space: 0x0100 .. 0x1FF
    SP: u8,
    A: u8,
    X: u8,
    Y: u8,
    P: u8,
    memory: []u8,

    pub fn init(allocator: std.mem.Allocator) !*CPU {
        const cpu = try allocator.create(CPU);
        const mem = try allocator.alloc(u8, 0xFFFF);
        cpu.* = .{ .PC = 0, .SP = 0, .A = 0, .X = 0, .Y = 0, .P = 0, .memory = mem };
        return cpu;
    }

    fn load(self: *CPU, program: []u8) void {
        @memcpy(self.memory[0x8000..(0x8000 + program.len)], program);
        self.PC = 0x8000;
        self.mem_write_u16(0xFFFC, 0x8000);
    }

    fn mem_read(self: *CPU, addr: u16) u8 {
        return self.memory[addr];
    }
    fn mem_write(self: *CPU, addr: u16, data: u8) void {
        self.memory[addr] = data;
    }

    fn mem_read_u16(self: *CPU, addr: u16) u16 {
        const lo: u16 = @intCast(self.mem_read(addr));
        const hi: u16 = @intCast(self.mem_read(addr + 1));
        return ((hi << 8) | lo);
    }
    fn mem_write_u16(self: *CPU, addr: u16, data: u16) void {
        const hi: u8 = @intCast(data >> 8);
        const lo: u8 = @intCast(data & 0xff);
        self.mem_write(addr, lo);
        self.mem_write(addr + 1, hi);
    }

    fn reset(self: *CPU) void {
        self.A = 0;
        self.X = 0;
        self.P = 0;

        self.PC = self.mem_read_u16(0xFFFC);
    }

    pub fn load_and_run(self: *CPU, program: []u8) void {
        self.reset();
        self.load(program);
        self.run();
    }

    fn get_op_address(self: *CPU, mode: AddressingMode) !u16 {
        switch (mode) {
            AddressingMode.Immediate => {
                return self.PC;
            },
            AddressingMode.ZeroPage => {
                return self.mem_read(self.PC);
            },
            AddressingMode.Absolute => {
                return self.mem_read_u16(self.PC);
            },
            AddressingMode.ZeroPage_X => {
                const pos = self.mem_read(self.PC);
                const addr, _ = @addWithOverflow(pos, self.X);
                return addr;
            },
            AddressingMode.ZeroPage_Y => {
                const pos = self.mem_read(self.PC);
                const addr, _ = @addWithOverflow(pos, self.Y);
                return addr;
            },
            AddressingMode.Absolute_X => {
                const pos = self.mem_read_u16(self.PC);
                const addr, _ = @addWithOverflow(pos, self.X);
                return addr;
            },
            AddressingMode.Absolute_Y => {
                const pos = self.mem_read_u16(self.PC);
                const addr, _ = @addWithOverflow(pos, self.Y);
                return addr;
            },
            AddressingMode.Indirect_X => {
                const base = self.mem_read(self.program_counter);

                const ptr: u8 = @addWithOverflow(base, self.X);
                const lo: u16 = self.mem_read(@intCast(ptr));
                const hi: u16 = self.mem_read(@intCast(@addWithOverflow(ptr, 1)));
                return hi << 8 | lo;
            },
            AddressingMode.Indirect_Y => {
                const base = self.mem_read(self.program_counter);

                const lo: u16 = self.mem_read(base);
                const hi: u16 = self.mem_read(@intCast(@addWithOverflow(base, 1)));
                const deref_base: u16 = hi << 16 | lo;
                const deref: u16 = @addWithOverflow(self.Y, deref_base);
                return deref;
            },
            AddressingMode.NoneAddressing => {
                return error{NoAddressingFound};
            },
            else => {
                return error{NoAddressingFound};
            },
        }
    }

    fn run(self: *CPU) void {
        while (true) {
            const opcode: usize = self.mem_read(self.PC); // Fetch
            self.PC += 1;

            std.debug.print("{x}\n", .{opcode});

            switch (opcode) { // Decode
                // Execute
                0x00 => {
                    return;
                },
                else => {
                    logger.warn("Instruction not recognize", .{});
                    return;
                },
            }
        }
    }

    // fn decode(self: CPU, instruction: u8) void {}
    // fn execute(self: CPU, instruction: u8) void {}
};
