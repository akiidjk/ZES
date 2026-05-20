const std = @import("std");
const zes = @import("zes");
const cpu = @import("cpu");
const Io = std.Io;
const logging = @import("logging");
const logger = @import("logging").log;
const nesLog = @import("logging").cpu;
const sdl = @import("sdl.zig");
const posix = std.posix;

pub const std_options: std.Options = .{ .logFn = logging.formatFn, .log_level = logging.default_level, .log_scope_levels = &[_]std.log.ScopeLevel{
    .{ .scope = .cpu, .level = .debug },
    .{ .scope = .log, .level = .debug },
} };

fn handleCtrlC(signum: std.os.linux.SIG) callconv(.c) void {
    std.process.exit(0);
    std.debug.print("\n[!] Caught Ctrl+C (signal {}), Shutting down...\n", .{signum});
}

fn setupSigint() void {
    var sa = posix.Sigaction{
        .handler = .{ .handler = handleCtrlC },
        .mask = posix.sigemptyset(),
        .flags = 0,
    };
    _ = posix.sigaction(posix.SIG.INT, &sa, null);
}

fn getRom(allocator: std.mem.Allocator, romPath: [:0]const u8, io: Io) ![]u8 {
    var romFile = try Io.Dir.openFile(Io.Dir.cwd(), io, romPath, .{ .mode = .read_only });
    const romBuffer = try allocator.alloc(u8, try romFile.length(io)); // alloc max size of rom
    const romContent = try Io.Dir.readFile(Io.Dir.cwd(), io, romPath, romBuffer);
    return romContent;
}

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();

    const win, const renderer = sdl.initSDL();
    defer sdl.closeSDL(win, renderer);

    setupSigint();

    // Accessing command line arguments:
    const args = try init.minimal.args.toSlice(arena);
    if (args.len < 2) {
        logger.err("No args found, usage: ./{s} <rom_path>", .{args[0]});
        return;
    }
    const romPath = args[1];
    var cpuInstance = try cpu.CPU.init(arena);
    const rom = getRom(arena, romPath, init.io) catch |err| switch (err) {
        error.FileNotFound, error.AccessDenied => {
            logger.err("unable to open file: {}\n", .{err});
            return;
        },
        else => |e| return e, // don't continue; rather, bomb out
    };

    cpuInstance.load_and_run(rom);
}
