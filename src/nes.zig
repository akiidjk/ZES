const std = @import("std");
const logger = @import("logging").log;
const nesLog = @import("logging").nes;
const opcodeMod = @import("opcode.zig");

const Flag = enum(u3) {
    Carry = 0,
    Zero = 1,
    Interrupt = 2,
    Decimal = 3,
    Break = 4,
    Unused = 5,
    Overflow = 6,
    Negative = 7,
};

const AddressResult = struct {
    addr: u16,
    page_crossed: bool,
};

pub const CPU = struct {
    PC: u16, // Memory space: 0x0100 .. 0x1FF
    SP: u8,
    A: u8,
    X: u8,
    Y: u8,
    P: u8,
    memory: []u8,
    cycles: u16,

    pub fn init(allocator: std.mem.Allocator) !*CPU {
        const cpu = try allocator.create(CPU);
        const mem = try allocator.alloc(u8, 0xFFFF);
        cpu.* = .{ .PC = 0, .SP = 0, .A = 0, .X = 0, .Y = 0, .P = 0, .memory = mem, .cycles = 0 };
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

    fn update_zero_and_negative_flags(self: *CPU, result: u8) void {
        self.set_flag(.Zero, @intFromBool(result == 0));
        self.set_flag(.Negative, @intFromBool((result & 0b1000_0000) != 0));
    }

    fn reset(self: *CPU) void {
        self.A = 0;
        self.X = 0;
        self.PC += 0;
        self.P = 0;

        self.PC = self.mem_read_u16(0xFFFC);
    }

    pub fn load_and_run(self: *CPU, program: []u8) void {
        self.reset();
        self.load(program);
        self.run();
    }

    fn get_op_address(self: *CPU, mode: opcodeMod.AddressingMode) AddressResult {
        switch (mode) {
            opcodeMod.AddressingMode.Immediate => {
                self.PC += 1;
                return .{ .addr = self.PC, .page_crossed = false };
            },
            opcodeMod.AddressingMode.ZeroPage => {
                self.PC += 1;
                return .{ .addr = self.mem_read(self.PC), .page_crossed = false };
            },
            opcodeMod.AddressingMode.Absolute => {
                self.PC += 2;
                return .{ .addr = self.mem_read_u16(self.PC), .page_crossed = false };
            },
            opcodeMod.AddressingMode.ZeroPage_X => {
                const pos = self.mem_read(self.PC);
                const addr, _ = @addWithOverflow(pos, self.X);
                self.PC += 1;
                return .{ .addr = addr, .page_crossed = false };
            },
            opcodeMod.AddressingMode.ZeroPage_Y => {
                const pos = self.mem_read(self.PC);
                const addr, _ = @addWithOverflow(pos, self.Y);
                self.PC += 1;
                return .{ .addr = addr, .page_crossed = false };
            },
            opcodeMod.AddressingMode.Absolute_X => {
                const base = self.mem_read_u16(self.PC);
                const addr, _ = @addWithOverflow(base, @as(u16, self.X));
                self.PC += 2;
                return .{
                    .addr = addr,
                    .page_crossed = (base & 0xFF00) != (addr & 0xFF00),
                };
            },
            opcodeMod.AddressingMode.Absolute_Y => {
                const base = self.mem_read_u16(self.PC);
                const addr, _ = @addWithOverflow(base, @as(u16, self.Y));
                self.PC += 2;
                return .{
                    .addr = addr,
                    .page_crossed = (base & 0xFF00) != (addr & 0xFF00),
                };
            },
            opcodeMod.AddressingMode.Indirect_X => {
                const zp = self.mem_read(self.PC);
                const lo: u16 = self.mem_read(zp);
                const hi: u16 = self.mem_read(@intCast(@addWithOverflow(zp, 1)[0]));
                const base: u16 = (hi << 8) | lo;
                const addr, _ = @addWithOverflow(base, @as(u16, self.Y));
                self.PC += 1;
                return .{
                    .addr = addr,
                    .page_crossed = (base & 0xFF00) != (addr & 0xFF00),
                };
            },
            opcodeMod.AddressingMode.Indirect_Y => {
                const zp = self.mem_read(self.PC);
                const ptr: u8 = @addWithOverflow(zp, self.X)[0];
                const lo: u16 = self.mem_read(ptr);
                const hi: u16 = self.mem_read(@addWithOverflow(ptr, 1)[0]);
                self.PC += 1;
                return .{ .addr = (hi << 8) | lo, .page_crossed = false };
            },
            opcodeMod.AddressingMode.NoneAddressing => {
                return .{ .addr = self.mem_read(self.PC), .page_crossed = false };
            },
        }
    }

    fn set_flag(self: *CPU, flag: Flag, value: u1) void {
        self.P |= (@as(u8, value) << @intFromEnum(flag));
    }

    fn clear_flag(self: *CPU, flag: Flag) void {
        self.P &= ~(1 << @intFromEnum(flag));
    }

    fn get_flag(self: *CPU, flag: Flag) bool {
        return (self.P & @as(u8, (@as(u8, 1) << @intFromEnum(flag)))) != 0;
    }

    fn adc(self: *CPU, mode: opcodeMod.AddressingMode) void {
        const result = self.get_op_address(mode);
        self.cycles += @intFromBool(result.page_crossed);
        const value = self.mem_read(result.addr);

        const a = self.A;
        const c: u8 = @intFromBool(self.get_flag(.Carry));

        const res1, const carry1: u1 = @addWithOverflow(a, value);
        const res2, const carry2: u1 = @addWithOverflow(res1, c);

        self.A = res2;
        self.set_flag(.Carry, carry1 | carry2);

        const overflow = ((~(a ^ value) & (a ^ self.A)) & 0x80) != 0;
        self.set_flag(.Overflow, @intFromBool(overflow));

        self.update_zero_and_negative_flags(value);
    }

    fn lsr(self: *CPU, mode: opcodeMod.AddressingMode) void {
        var value: u8 = 0;
        if (mode == opcodeMod.AddressingMode.NoneAddressing) {
            value = self.A >> 1;
            self.A = value;
        } else {
            const result = self.get_op_address(mode);
            value = self.mem_read(result.addr) >> 1;
            self.mem_write(result.addr, value);
        }
        self.set_flag(.Carry, @intFromBool((value & 1) != 0));
        self.update_zero_and_negative_flags(value);
    }

    fn run(self: *CPU) void {
        const opcodes = opcodeMod.init_opcode();
        while (true) {
            const code: u16 = self.mem_read(self.PC); // Fetch
            const opcode = opcodes.get(code);
            self.PC += 1;
            const program_counter_state = self.PC;
            std.debug.print("{x}\n", .{code});

            switch (code) { // Decode
                // Execute
                // ADC
                0x69,
                0x65,
                0x75,
                0x6d,
                0x7D,
                0x79,
                0x61,
                0x71,
                => {
                    self.adc(opcode.?.mode);
                },
                // LSR
                0x4a, 0x46, 0x56, 0x4e, 0x5e => {
                    self.lsr(opcode.?.mode);
                },
                // NOP
                0xea => {
                    //do nothing
                },
                0x00 => {
                    return;
                },
                else => {
                    logger.warn("Instruction not recognize", .{});
                    return;
                },
            }

            if (program_counter_state == self.PC) {
                self.PC += (opcode.?.size - 1);
            }
            self.cycles += opcode.?.cycles;
        }
    }

    // fn decode(self: CPU, instruction: u8) void {}
    // fn execute(self: CPU, instruction: u8) void {}
};
