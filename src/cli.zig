const std = @import("std");
const Io = std.Io;

const die = @import("fatal.zig").die;
const repo = @import("lib/repo.zig");

pub fn run(out: *Io.Writer, args: []const []const u8) !void {
    if (args.len <= 1) {
        try print_usage(out, args[0]);
        die("Not enough arguments. Expecting subcommand.", .{});
    }

    if (std.mem.eql(u8, args[1], "init")) {
        try runInit(out);
    } else if (std.mem.eql(u8, args[1], "new")) {
        try runNew(out);
    } else if (std.mem.eql(u8, args[1], "record")) {
        try runRecord(out);
    } else if (std.mem.eql(u8, args[1], "status")) {
        try runStatus(out);
    } else if (std.mem.eql(u8, args[1], "tree")) {
        try runTree(out);
    } else if (std.mem.eql(u8, args[1], "log")) {
        try runLog(out);
    } else if (std.mem.eql(u8, args[1], "commit")) {
        try runCommit(out, args[0], args[2..]);
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

pub fn runInit(out: *Io.Writer) !void {
    try repo.reinit();
    try out.print("Ran init subcommand!\n", .{});
}

pub fn runNew(out: *Io.Writer) !void {
    try out.print("Ran new subcommand!\n", .{});
}

pub fn runRecord(out: *Io.Writer) !void {
    try out.print("Ran record subcommand!\n", .{});
}

pub fn runStatus(out: *Io.Writer) !void {
    try out.print("Ran status subcommand!\n", .{});
}

pub fn runTree(out: *Io.Writer) !void {
    try out.print("Ran tree subcommand!\n", .{});
}

pub fn runLog(out: *Io.Writer) !void {
    try out.print("Ran log subcommand!\n", .{});
}

pub fn runCommit(
    out: *Io.Writer, 
    progname: []const u8, 
    args: []const []const u8,
) !void {
    if (args.len < 1) {
        try print_usage(out, progname);
        die("Message required for commit\n", .{});
    }

    try repo.saveCommit(args[0]);
    try out.print("Ran commit subcommand!\n", .{});
}

pub fn runCheckout(out: *Io.Writer) !void {
    try out.print("Ran checkout subcommand!\n", .{});
}

pub fn runBranch(out: *Io.Writer) !void {
    try out.print("Ran branch subcommand!\n", .{});
}

pub fn runMerge(out: *Io.Writer) !void {
    try out.print("Ran branch subcommand!\n", .{});
}

pub fn runWeave(out: *Io.Writer) !void {
    try out.print("Ran weave subcommand!\n", .{});
}

fn print_usage(out: *Io.Writer, progname: []const u8) !void {
    try out.print("Usage: {s} <subcommand>\n", .{progname});
    try out.flush();
}
