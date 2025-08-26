const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const die = @import("fatal.zig").die;
const repo = @import("lib/repo.zig");

pub fn run(alloc: Allocator, out: *Io.Writer, args: []const []const u8) !void {
    if (args.len <= 1) {
        try print_usage(out, args[0]);
        die("Not enough arguments. Expecting subcommand.", .{});
    }

    if (std.mem.eql(u8, args[1], "init")) {
        try runInit(alloc, out);
    } else if (std.mem.eql(u8, args[1], "new")) {
        try runNew(out);
    } else if (std.mem.eql(u8, args[1], "record")) {
        try runRecord(out);
    } else if (std.mem.eql(u8, args[1], "status")) {
        try runStatus(alloc, out);
    } else if (std.mem.eql(u8, args[1], "tree")) {
        try runTree(out);
    } else if (std.mem.eql(u8, args[1], "log")) {
        try runLog(alloc, out);
    } else if (std.mem.eql(u8, args[1], "commit")) {
        try runCommit(alloc, out, args[0], args[2..]);
    } else if (std.mem.eql(u8, args[1], "checkout")) {
        try runCheckout(out);
    } else if (std.mem.eql(u8, args[1], "branch")) {
        try runBranch(out);
    } else if (std.mem.eql(u8, args[1], "merge")) {
        try runMerge(out);
    } else if (std.mem.eql(u8, args[1], "weave")) {
        try runWeave(out);
    } else {
        die("Unrecognized subcommand \"{s}\".", .{args[1]});
    }
}

pub fn runInit(alloc: Allocator, out: *Io.Writer) !void {
    _ = out;
    try repo.reinit(alloc,);
}

pub fn runNew(out: *Io.Writer) !void {
    try out.print("Ran new subcommand!\n", .{});
    try out.flush();
}

pub fn runRecord(out: *Io.Writer) !void {
    try out.print("Ran record subcommand!\n", .{});
    try out.flush();
}

pub fn runStatus(alloc: Allocator, out: *Io.Writer) !void {
    const head_commit_hash = try repo.getHeadCommit(alloc);
    const short_hash = head_commit_hash[0..6];
    try out.print("On commit {s}\n", .{short_hash});
    try out.flush();
}

pub fn runTree(out: *Io.Writer) !void {
    try out.print("Ran tree subcommand!\n", .{});
    try out.flush();
}

pub fn runLog(alloc: Allocator, out: *Io.Writer) !void {
    var iter = try repo.commitsIterator(alloc);
    while (try iter.next()) |commit| {
        try out.print("{s}: {s} ({s})\n", .{
            iter.current_hash.?, 
            commit.message, 
            commit.author,
        });
    }
    try out.flush();
}

pub fn runCommit(
    alloc: Allocator,
    out: *Io.Writer, 
    progname: []const u8, 
    args: []const []const u8,
) !void {
    if (args.len < 1) {
        try print_usage(out, progname);
        die("Message required for commit\n", .{});
    }

    try repo.makeCommit(alloc, args[0]);
}

pub fn runCheckout(out: *Io.Writer) !void {
    try out.print("Ran checkout subcommand!\n", .{});
    try out.flush();
}

pub fn runBranch(out: *Io.Writer) !void {
    try out.print("Ran branch subcommand!\n", .{});
    try out.flush();
}

pub fn runMerge(out: *Io.Writer) !void {
    try out.print("Ran branch subcommand!\n", .{});
    try out.flush();
}

pub fn runWeave(out: *Io.Writer) !void {
    try out.print("Ran weave subcommand!\n", .{});
    try out.flush();
}

fn print_usage(out: *Io.Writer, progname: []const u8) !void {
    try out.print("Usage: {s} <subcommand>\n", .{progname});
    try out.flush();
}
