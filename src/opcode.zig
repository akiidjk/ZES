const std = @import("std");

pub const AddressingMode = enum {
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

pub const Opcode = struct {
    opcode: u8,
    mnemonic: []const u8,
    size: u4, // 0 - 31
    cycles: u4, // 0 - 31
    mode: AddressingMode,
};

pub fn init_opcode() std.AutoHashMap(u16, Opcode) {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    // defer arena.deinit();
    const allocator = arena.allocator();

    var map: std.AutoHashMap(u16, Opcode) = .init(allocator);

    const opcodes = [_]Opcode{
        .{ .opcode = 0x00, .mnemonic = "BRK", .size = 1, .cycles = 7, .mode = .NoneAddressing },
        .{ .opcode = 0xea, .mnemonic = "NOP", .size = 1, .cycles = 2, .mode = .NoneAddressing },
        .{ .opcode = 0x1a, .mnemonic = "NOP", .size = 1, .cycles = 2, .mode = .NoneAddressing },

        // Arithmetic
        .{ .opcode = 0x69, .mnemonic = "ADC", .size = 2, .cycles = 2, .mode = .Immediate },
        .{ .opcode = 0x65, .mnemonic = "ADC", .size = 2, .cycles = 3, .mode = .ZeroPage },
        .{ .opcode = 0x75, .mnemonic = "ADC", .size = 2, .cycles = 4, .mode = .ZeroPage_X },
        .{ .opcode = 0x6d, .mnemonic = "ADC", .size = 3, .cycles = 4, .mode = .Absolute },
        .{ .opcode = 0x7d, .mnemonic = "ADC", .size = 3, .cycles = 4, .mode = .Absolute_X },
        .{ .opcode = 0x79, .mnemonic = "ADC", .size = 3, .cycles = 4, .mode = .Absolute_Y },
        .{ .opcode = 0x61, .mnemonic = "ADC", .size = 2, .cycles = 6, .mode = .Indirect_X },
        .{ .opcode = 0x71, .mnemonic = "ADC", .size = 2, .cycles = 5, .mode = .Indirect_Y },

        .{ .opcode = 0xe9, .mnemonic = "SBC", .size = 2, .cycles = 2, .mode = .Immediate },
        .{ .opcode = 0xe5, .mnemonic = "SBC", .size = 2, .cycles = 3, .mode = .ZeroPage },
        .{ .opcode = 0xf5, .mnemonic = "SBC", .size = 2, .cycles = 4, .mode = .ZeroPage_X },
        .{ .opcode = 0xed, .mnemonic = "SBC", .size = 3, .cycles = 4, .mode = .Absolute },
        .{ .opcode = 0xfd, .mnemonic = "SBC", .size = 3, .cycles = 4, .mode = .Absolute_X },
        .{ .opcode = 0xf9, .mnemonic = "SBC", .size = 3, .cycles = 4, .mode = .Absolute_Y },
        .{ .opcode = 0xe1, .mnemonic = "SBC", .size = 2, .cycles = 6, .mode = .Indirect_X },
        .{ .opcode = 0xf1, .mnemonic = "SBC", .size = 2, .cycles = 5, .mode = .Indirect_Y },

        .{ .opcode = 0x29, .mnemonic = "AND", .size = 2, .cycles = 2, .mode = .Immediate },
        .{ .opcode = 0x25, .mnemonic = "AND", .size = 2, .cycles = 3, .mode = .ZeroPage },
        .{ .opcode = 0x35, .mnemonic = "AND", .size = 2, .cycles = 4, .mode = .ZeroPage_X },
        .{ .opcode = 0x2d, .mnemonic = "AND", .size = 3, .cycles = 4, .mode = .Absolute },
        .{ .opcode = 0x3d, .mnemonic = "AND", .size = 3, .cycles = 4, .mode = .Absolute_X },
        .{ .opcode = 0x39, .mnemonic = "AND", .size = 3, .cycles = 4, .mode = .Absolute_Y },
        .{ .opcode = 0x21, .mnemonic = "AND", .size = 2, .cycles = 6, .mode = .Indirect_X },
        .{ .opcode = 0x31, .mnemonic = "AND", .size = 2, .cycles = 5, .mode = .Indirect_Y },

        .{ .opcode = 0x49, .mnemonic = "EOR", .size = 2, .cycles = 2, .mode = .Immediate },
        .{ .opcode = 0x45, .mnemonic = "EOR", .size = 2, .cycles = 3, .mode = .ZeroPage },
        .{ .opcode = 0x55, .mnemonic = "EOR", .size = 2, .cycles = 4, .mode = .ZeroPage_X },
        .{ .opcode = 0x4d, .mnemonic = "EOR", .size = 3, .cycles = 4, .mode = .Absolute },
        .{ .opcode = 0x5d, .mnemonic = "EOR", .size = 3, .cycles = 4, .mode = .Absolute_X },
        .{ .opcode = 0x59, .mnemonic = "EOR", .size = 3, .cycles = 4, .mode = .Absolute_Y },
        .{ .opcode = 0x41, .mnemonic = "EOR", .size = 2, .cycles = 6, .mode = .Indirect_X },
        .{ .opcode = 0x51, .mnemonic = "EOR", .size = 2, .cycles = 5, .mode = .Indirect_Y },

        .{ .opcode = 0x09, .mnemonic = "ORA", .size = 2, .cycles = 2, .mode = .Immediate },
        .{ .opcode = 0x05, .mnemonic = "ORA", .size = 2, .cycles = 3, .mode = .ZeroPage },
        .{ .opcode = 0x15, .mnemonic = "ORA", .size = 2, .cycles = 4, .mode = .ZeroPage_X },
        .{ .opcode = 0x0d, .mnemonic = "ORA", .size = 3, .cycles = 4, .mode = .Absolute },
        .{ .opcode = 0x1d, .mnemonic = "ORA", .size = 3, .cycles = 4, .mode = .Absolute_X },
        .{ .opcode = 0x19, .mnemonic = "ORA", .size = 3, .cycles = 4, .mode = .Absolute_Y },
        .{ .opcode = 0x01, .mnemonic = "ORA", .size = 2, .cycles = 6, .mode = .Indirect_X },
        .{ .opcode = 0x11, .mnemonic = "ORA", .size = 2, .cycles = 5, .mode = .Indirect_Y },

        // Shifts
        .{ .opcode = 0x0a, .mnemonic = "ASL", .size = 1, .cycles = 2, .mode = .NoneAddressing },
        .{ .opcode = 0x06, .mnemonic = "ASL", .size = 2, .cycles = 5, .mode = .ZeroPage },
        .{ .opcode = 0x16, .mnemonic = "ASL", .size = 2, .cycles = 6, .mode = .ZeroPage_X },
        .{ .opcode = 0x0e, .mnemonic = "ASL", .size = 3, .cycles = 6, .mode = .Absolute },
        .{ .opcode = 0x1e, .mnemonic = "ASL", .size = 3, .cycles = 7, .mode = .Absolute_X },

        .{ .opcode = 0x4a, .mnemonic = "LSR", .size = 1, .cycles = 2, .mode = .NoneAddressing },
        .{ .opcode = 0x46, .mnemonic = "LSR", .size = 2, .cycles = 5, .mode = .ZeroPage },
        .{ .opcode = 0x56, .mnemonic = "LSR", .size = 2, .cycles = 6, .mode = .ZeroPage_X },
        .{ .opcode = 0x4e, .mnemonic = "LSR", .size = 3, .cycles = 6, .mode = .Absolute },
        .{ .opcode = 0x5e, .mnemonic = "LSR", .size = 3, .cycles = 7, .mode = .Absolute_X },

        .{ .opcode = 0x2a, .mnemonic = "ROL", .size = 1, .cycles = 2, .mode = .NoneAddressing },
        .{ .opcode = 0x26, .mnemonic = "ROL", .size = 2, .cycles = 5, .mode = .ZeroPage },
        .{ .opcode = 0x36, .mnemonic = "ROL", .size = 2, .cycles = 6, .mode = .ZeroPage_X },
        .{ .opcode = 0x2e, .mnemonic = "ROL", .size = 3, .cycles = 6, .mode = .Absolute },
        .{ .opcode = 0x3e, .mnemonic = "ROL", .size = 3, .cycles = 7, .mode = .Absolute_X },

        .{ .opcode = 0x6a, .mnemonic = "ROR", .size = 1, .cycles = 2, .mode = .NoneAddressing },
        .{ .opcode = 0x66, .mnemonic = "ROR", .size = 2, .cycles = 5, .mode = .ZeroPage },
        .{ .opcode = 0x76, .mnemonic = "ROR", .size = 2, .cycles = 6, .mode = .ZeroPage_X },
        .{ .opcode = 0x6e, .mnemonic = "ROR", .size = 3, .cycles = 6, .mode = .Absolute },
        .{ .opcode = 0x7e, .mnemonic = "ROR", .size = 3, .cycles = 7, .mode = .Absolute_X },

        .{ .opcode = 0xe6, .mnemonic = "INC", .size = 2, .cycles = 5, .mode = .ZeroPage },
        .{ .opcode = 0xf6, .mnemonic = "INC", .size = 2, .cycles = 6, .mode = .ZeroPage_X },
        .{ .opcode = 0xee, .mnemonic = "INC", .size = 3, .cycles = 6, .mode = .Absolute },
        .{ .opcode = 0xfe, .mnemonic = "INC", .size = 3, .cycles = 7, .mode = .Absolute_X },

        .{ .opcode = 0xe8, .mnemonic = "INX", .size = 1, .cycles = 2, .mode = .NoneAddressing },
        .{ .opcode = 0xc8, .mnemonic = "INY", .size = 1, .cycles = 2, .mode = .NoneAddressing },

        .{ .opcode = 0xc6, .mnemonic = "DEC", .size = 2, .cycles = 5, .mode = .ZeroPage },
        .{ .opcode = 0xd6, .mnemonic = "DEC", .size = 2, .cycles = 6, .mode = .ZeroPage_X },
        .{ .opcode = 0xce, .mnemonic = "DEC", .size = 3, .cycles = 6, .mode = .Absolute },
        .{ .opcode = 0xde, .mnemonic = "DEC", .size = 3, .cycles = 7, .mode = .Absolute_X },

        .{ .opcode = 0xca, .mnemonic = "DEX", .size = 1, .cycles = 2, .mode = .NoneAddressing },
        .{ .opcode = 0x88, .mnemonic = "DEY", .size = 1, .cycles = 2, .mode = .NoneAddressing },

        .{ .opcode = 0xc9, .mnemonic = "CMP", .size = 2, .cycles = 2, .mode = .Immediate },
        .{ .opcode = 0xc5, .mnemonic = "CMP", .size = 2, .cycles = 3, .mode = .ZeroPage },
        .{ .opcode = 0xd5, .mnemonic = "CMP", .size = 2, .cycles = 4, .mode = .ZeroPage_X },
        .{ .opcode = 0xcd, .mnemonic = "CMP", .size = 3, .cycles = 4, .mode = .Absolute },
        .{ .opcode = 0xdd, .mnemonic = "CMP", .size = 3, .cycles = 4, .mode = .Absolute_X },
        .{ .opcode = 0xd9, .mnemonic = "CMP", .size = 3, .cycles = 4, .mode = .Absolute_Y },
        .{ .opcode = 0xc1, .mnemonic = "CMP", .size = 2, .cycles = 6, .mode = .Indirect_X },
        .{ .opcode = 0xd1, .mnemonic = "CMP", .size = 2, .cycles = 5, .mode = .Indirect_Y },

        .{ .opcode = 0xc0, .mnemonic = "CPY", .size = 2, .cycles = 2, .mode = .Immediate },
        .{ .opcode = 0xc4, .mnemonic = "CPY", .size = 2, .cycles = 3, .mode = .ZeroPage },
        .{ .opcode = 0xcc, .mnemonic = "CPY", .size = 3, .cycles = 4, .mode = .Absolute },

        .{ .opcode = 0xe0, .mnemonic = "CPX", .size = 2, .cycles = 2, .mode = .Immediate },
        .{ .opcode = 0xe4, .mnemonic = "CPX", .size = 2, .cycles = 3, .mode = .ZeroPage },
        .{ .opcode = 0xec, .mnemonic = "CPX", .size = 3, .cycles = 4, .mode = .Absolute },

        // Branching
        .{ .opcode = 0x4c, .mnemonic = "JMP", .size = 3, .cycles = 3, .mode = .NoneAddressing },
        .{ .opcode = 0x6c, .mnemonic = "JMP", .size = 3, .cycles = 5, .mode = .NoneAddressing },

        .{ .opcode = 0x20, .mnemonic = "JSR", .size = 3, .cycles = 6, .mode = .NoneAddressing },
        .{ .opcode = 0x60, .mnemonic = "RTS", .size = 1, .cycles = 6, .mode = .NoneAddressing },

        .{ .opcode = 0x40, .mnemonic = "RTI", .size = 1, .cycles = 6, .mode = .NoneAddressing },

        .{ .opcode = 0xd0, .mnemonic = "BNE", .size = 2, .cycles = 2, .mode = .NoneAddressing },
        .{ .opcode = 0x70, .mnemonic = "BVS", .size = 2, .cycles = 2, .mode = .NoneAddressing },
        .{ .opcode = 0x50, .mnemonic = "BVC", .size = 2, .cycles = 2, .mode = .NoneAddressing },
        .{ .opcode = 0x30, .mnemonic = "BMI", .size = 2, .cycles = 2, .mode = .NoneAddressing },
        .{ .opcode = 0xf0, .mnemonic = "BEQ", .size = 2, .cycles = 2, .mode = .NoneAddressing },
        .{ .opcode = 0xb0, .mnemonic = "BCS", .size = 2, .cycles = 2, .mode = .NoneAddressing },
        .{ .opcode = 0x90, .mnemonic = "BCC", .size = 2, .cycles = 2, .mode = .NoneAddressing },
        .{ .opcode = 0x10, .mnemonic = "BPL", .size = 2, .cycles = 2, .mode = .NoneAddressing },

        .{ .opcode = 0x24, .mnemonic = "BIT", .size = 2, .cycles = 3, .mode = .ZeroPage },
        .{ .opcode = 0x2c, .mnemonic = "BIT", .size = 3, .cycles = 4, .mode = .Absolute },

        // Stores, Loads
        .{ .opcode = 0xa9, .mnemonic = "LDA", .size = 2, .cycles = 2, .mode = .Immediate },
        .{ .opcode = 0xa5, .mnemonic = "LDA", .size = 2, .cycles = 3, .mode = .ZeroPage },
        .{ .opcode = 0xb5, .mnemonic = "LDA", .size = 2, .cycles = 4, .mode = .ZeroPage_X },
        .{ .opcode = 0xad, .mnemonic = "LDA", .size = 3, .cycles = 4, .mode = .Absolute },
        .{ .opcode = 0xbd, .mnemonic = "LDA", .size = 3, .cycles = 4, .mode = .Absolute_X },
        .{ .opcode = 0xb9, .mnemonic = "LDA", .size = 3, .cycles = 4, .mode = .Absolute_Y },
        .{ .opcode = 0xa1, .mnemonic = "LDA", .size = 2, .cycles = 6, .mode = .Indirect_X },
        .{ .opcode = 0xb1, .mnemonic = "LDA", .size = 2, .cycles = 5, .mode = .Indirect_Y },

        .{ .opcode = 0xa2, .mnemonic = "LDX", .size = 2, .cycles = 2, .mode = .Immediate },
        .{ .opcode = 0xa6, .mnemonic = "LDX", .size = 2, .cycles = 3, .mode = .ZeroPage },
        .{ .opcode = 0xb6, .mnemonic = "LDX", .size = 2, .cycles = 4, .mode = .ZeroPage_Y },
        .{ .opcode = 0xae, .mnemonic = "LDX", .size = 3, .cycles = 4, .mode = .Absolute },
        .{ .opcode = 0xbe, .mnemonic = "LDX", .size = 3, .cycles = 4, .mode = .Absolute_Y },

        .{ .opcode = 0xa0, .mnemonic = "LDY", .size = 2, .cycles = 2, .mode = .Immediate },
        .{ .opcode = 0xa4, .mnemonic = "LDY", .size = 2, .cycles = 3, .mode = .ZeroPage },
        .{ .opcode = 0xb4, .mnemonic = "LDY", .size = 2, .cycles = 4, .mode = .ZeroPage_X },
        .{ .opcode = 0xac, .mnemonic = "LDY", .size = 3, .cycles = 4, .mode = .Absolute },
        .{ .opcode = 0xbc, .mnemonic = "LDY", .size = 3, .cycles = 4, .mode = .Absolute_X },

        .{ .opcode = 0x85, .mnemonic = "STA", .size = 2, .cycles = 3, .mode = .ZeroPage },
        .{ .opcode = 0x95, .mnemonic = "STA", .size = 2, .cycles = 4, .mode = .ZeroPage_X },
        .{ .opcode = 0x8d, .mnemonic = "STA", .size = 3, .cycles = 4, .mode = .Absolute },
        .{ .opcode = 0x9d, .mnemonic = "STA", .size = 3, .cycles = 5, .mode = .Absolute_X },
        .{ .opcode = 0x99, .mnemonic = "STA", .size = 3, .cycles = 5, .mode = .Absolute_Y },
        .{ .opcode = 0x81, .mnemonic = "STA", .size = 2, .cycles = 6, .mode = .Indirect_X },
        .{ .opcode = 0x91, .mnemonic = "STA", .size = 2, .cycles = 6, .mode = .Indirect_Y },

        .{ .opcode = 0x86, .mnemonic = "STX", .size = 2, .cycles = 3, .mode = .ZeroPage },
        .{ .opcode = 0x96, .mnemonic = "STX", .size = 2, .cycles = 4, .mode = .ZeroPage_Y },
        .{ .opcode = 0x8e, .mnemonic = "STX", .size = 3, .cycles = 4, .mode = .Absolute },

        .{ .opcode = 0x84, .mnemonic = "STY", .size = 2, .cycles = 3, .mode = .ZeroPage },
        .{ .opcode = 0x94, .mnemonic = "STY", .size = 2, .cycles = 4, .mode = .ZeroPage_X },
        .{ .opcode = 0x8c, .mnemonic = "STY", .size = 3, .cycles = 4, .mode = .Absolute },

        // Flags clear
        .{ .opcode = 0xD8, .mnemonic = "CLD", .size = 1, .cycles = 2, .mode = .NoneAddressing },
        .{ .opcode = 0x58, .mnemonic = "CLI", .size = 1, .cycles = 2, .mode = .NoneAddressing },
        .{ .opcode = 0xb8, .mnemonic = "CLV", .size = 1, .cycles = 2, .mode = .NoneAddressing },
        .{ .opcode = 0x18, .mnemonic = "CLC", .size = 1, .cycles = 2, .mode = .NoneAddressing },
        .{ .opcode = 0x38, .mnemonic = "SEC", .size = 1, .cycles = 2, .mode = .NoneAddressing },
        .{ .opcode = 0x78, .mnemonic = "SEI", .size = 1, .cycles = 2, .mode = .NoneAddressing },
        .{ .opcode = 0xf8, .mnemonic = "SED", .size = 1, .cycles = 2, .mode = .NoneAddressing },

        .{ .opcode = 0xaa, .mnemonic = "TAX", .size = 1, .cycles = 2, .mode = .NoneAddressing },
        .{ .opcode = 0xa8, .mnemonic = "TAY", .size = 1, .cycles = 2, .mode = .NoneAddressing },
        .{ .opcode = 0xba, .mnemonic = "TSX", .size = 1, .cycles = 2, .mode = .NoneAddressing },
        .{ .opcode = 0x8a, .mnemonic = "TXA", .size = 1, .cycles = 2, .mode = .NoneAddressing },
        .{ .opcode = 0x9a, .mnemonic = "TXS", .size = 1, .cycles = 2, .mode = .NoneAddressing },
        .{ .opcode = 0x98, .mnemonic = "TYA", .size = 1, .cycles = 2, .mode = .NoneAddressing },

        // Stack
        .{ .opcode = 0x48, .mnemonic = "PHA", .size = 1, .cycles = 3, .mode = .NoneAddressing },
        .{ .opcode = 0x68, .mnemonic = "PLA", .size = 1, .cycles = 4, .mode = .NoneAddressing },
        .{ .opcode = 0x08, .mnemonic = "PHP", .size = 1, .cycles = 3, .mode = .NoneAddressing },
        .{ .opcode = 0x28, .mnemonic = "PLP", .size = 1, .cycles = 4, .mode = .NoneAddressing },
    };

    for (opcodes) |op| {
        map.put(op.opcode, op) catch unreachable;
    }

    return map;
}
