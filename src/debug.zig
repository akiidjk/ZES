const std = @import("std");
const nes = @import("nes.zig");
const builtin = @import("builtin");

// Source - https://stackoverflow.com/q/79880678
// Posted by freziyt223, modified by community. See post 'Timeline' for change history
// Retrieved 2026-03-22, License - CC BY-SA 4.0
pub fn Print(comptime fmt: []const u8, args: anytype) !void {
    const allocator = std.heap.smp_allocator;
    const count = std.fmt.count(fmt, args);
    const buf = try allocator.alloc(u8, count);
    defer allocator.free(buf);
    var stdout_writer = std.fs.File.stdout().writer(buf);
    const stdout = &stdout_writer.interface;
    try stdout.print(fmt, args);
    try stdout.flush();
}

// ------------ Debug shit ------------
pub fn printMemory(memory: []u8) !void {
    if (builtin.mode != .Debug) {
        return;
    }

    var i: usize = 0;
    var j: usize = 0;
    while (i < memory.len / 8) : (i += 1) {
        try Print("0x{x:0>4} ", .{i * 8});
        j = 0;
        while (j < 8) : (j += 2) { // print row
            try Print("\x1b[97m{x:0>2}\x1b[0m \x1b[90m{x:0>2}\x1b[0m ", .{ memory[i * 8 + j], memory[i * 8 + (j + 1)] });
        }
        try Print("\n", .{});
    }
}
