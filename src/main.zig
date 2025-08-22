const std = @import("std");
const Io = std.Io;
const process = std.process;

const subcommands = @import("subcommands.zig");

pub fn main() !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    const gpa = debug_allocator.allocator();

    var arena_allocator = std.heap.ArenaAllocator.init(gpa);
    defer arena_allocator.deinit();
    const arena = arena_allocator.allocator();

    const args = try process.argsAlloc(arena);

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    if (args.len <= 1) {
        try print_usage(stdout, args[0]);
        die("Not enough arguments. Expecting subcommand.", .{});
    }

    if (std.mem.eql(u8, args[1], "init")) {
        try subcommands.run_init(stdout);
    } else if (std.mem.eql(u8, args[1], "new")) {
        try subcommands.run_new(stdout);
    } else if (std.mem.eql(u8, args[1], "record")) {
        try subcommands.run_record(stdout);
    } else if (std.mem.eql(u8, args[1], "status")) {
        try subcommands.run_status(stdout);
    } else if (std.mem.eql(u8, args[1], "tree")) {
        try subcommands.run_tree(stdout);
    } else if (std.mem.eql(u8, args[1], "log")) {
        try subcommands.run_log(stdout);
    } else if (std.mem.eql(u8, args[1], "commit")) {
        try subcommands.run_commit(stdout);
    } else if (std.mem.eql(u8, args[1], "checkout")) {
        try subcommands.run_checkout(stdout);
    } else if (std.mem.eql(u8, args[1], "branch")) {
        try subcommands.run_branch(stdout);
    } else if (std.mem.eql(u8, args[1], "merge")) {
        try subcommands.run_merge(stdout);
    } else if (std.mem.eql(u8, args[1], "weave")) {
        try subcommands.run_weave(stdout);
    } else {
        die("Unrecognized subcommand \"{s}\".", .{args[1]});
    }
}

fn print_usage(out: *Io.Writer, progname: []const u8) !void {
    try out.print("Usage: {s} <subcommand>\n", .{progname});
    try out.flush();
}

fn die(comptime fmt: []const u8, args: anytype) noreturn {
    std.log.err(fmt, args);
    process.exit(1);
}
