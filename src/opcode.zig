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
    mnemonic: []u8,
    size: u4, // 0 - 31
    cycles: u4, // 0 - 31
    mode: AddressingMode,

    pub fn init_opcode() void {
        const arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        var map: std.AutoHashMap(u16, Opcode) = .init(allocator);


        try map.put(key: u16, value: Opcode);
    }
};
