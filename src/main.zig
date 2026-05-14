const std = @import("std");
const zes = @import("zes");
const nes = @import("nes");
const Io = std.Io;
const logging = @import("logging");
const logger = @import("logging").log;
const nesLog = @import("logging").nes;

pub const std_options: std.Options = .{ .logFn = logging.formatFn, .log_level = logging.default_level, .log_scope_levels = &[_]std.log.ScopeLevel{
    .{ .scope = .nes, .level = .debug },
    .{ .scope = .log, .level = .debug },
} };

fn getRom(allocator: std.mem.Allocator, romPath: [:0]const u8, io: Io) ![]u8 {
    var romFile = try Io.Dir.openFile(Io.Dir.cwd(), io, romPath, .{ .mode = .read_only });
    const romBuffer = try allocator.alloc(u8, try romFile.length(io)); // alloc max size of rom
    const romContent = try Io.Dir.readFile(Io.Dir.cwd(), io, romPath, romBuffer);
    return romContent;
}

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();

    // Accessing command line arguments:
    const args = try init.minimal.args.toSlice(arena);
    if (args.len < 2) {
        logger.err("No args found, usage: ./{s} <rom_path>", .{args[0]});
        return;
    }
    const romPath = args[1];
    var cpu = try nes.CPU.init(arena);
    const rom = getRom(arena, romPath, init.io) catch |err| switch (err) {
        error.FileNotFound, error.AccessDenied => {
            logger.err("unable to open file: {}\n", .{err});
            return;
        },
        else => |e| return e, // don't continue; rather, bomb out
    };

    cpu.load_and_run(rom);
}
