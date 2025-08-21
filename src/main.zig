const std = @import("std");
const process = std.process;

const subcommands = @import("subcommands.zig");

pub fn main() !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    const gpa = debug_allocator.allocator();

    var arena_allocator = std.heap.ArenaAllocator.init(gpa);
    defer arena_allocator.deinit();
    const arena = arena_allocator.allocator();

    const args = try process.argsAlloc(arena);

    if (args.len <= 1) {
        print_usage(args[0]);
        die("Not enough arguments. Expecting subcommand.", .{});
    }

    if (std.mem.eql(u8, args[1], "init")) {
        try subcommands.run_init();
    } else if (std.mem.eql(u8, args[1], "new")) {
        try subcommands.run_new();
    } else if (std.mem.eql(u8, args[1], "record")) {
        try subcommands.run_record();
    } else if (std.mem.eql(u8, args[1], "status")) {
        try subcommands.run_status();
    } else if (std.mem.eql(u8, args[1], "tree")) {
        try subcommands.run_tree();
    } else if (std.mem.eql(u8, args[1], "log")) {
        try subcommands.run_log();
    } else if (std.mem.eql(u8, args[1], "commit")) {
        try subcommands.run_commit();
    } else if (std.mem.eql(u8, args[1], "checkout")) {
        try subcommands.run_checkout();
    } else if (std.mem.eql(u8, args[1], "branch")) {
        try subcommands.run_branch();
    } else if (std.mem.eql(u8, args[1], "weave")) {
        try subcommands.run_weave();
    } else {
        die("Unrecognized subcommand \"{s}\".", .{args[1]});
    }
}

fn print_usage(progname: []const u8) void {
    const out = std.io.getStdOut().writer();
    out.print("Usage: {s} <subcommand>\n", .{progname}) catch |e| {
        die("Failed to write to stdout: {any}", .{e});
    };
}

fn die(comptime fmt: []const u8, args: anytype) noreturn {
    std.log.err(fmt, args);
    process.exit(1);
}
