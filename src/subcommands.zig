const std = @import("std");
const Io = std.Io;

pub fn run_init(out: *Io.Writer) !void {
    try out.print("Ran init subcommand!\n", .{});
}

pub fn run_new(out: *Io.Writer) !void {
    try out.print("Ran new subcommand!\n", .{});
}

pub fn run_record(out: *Io.Writer) !void {
    try out.print("Ran record subcommand!\n", .{});
}

pub fn run_status(out: *Io.Writer) !void {
    try out.print("Ran status subcommand!\n", .{});
}

pub fn run_tree(out: *Io.Writer) !void {
    try out.print("Ran tree subcommand!\n", .{});
}

pub fn run_log(out: *Io.Writer) !void {
    try out.print("Ran log subcommand!\n", .{});
}

pub fn run_commit(out: *Io.Writer) !void {
    try out.print("Ran commit subcommand!\n", .{});
}

pub fn run_checkout(out: *Io.Writer) !void {
    try out.print("Ran checkout subcommand!\n", .{});
}

pub fn run_branch(out: *Io.Writer) !void {
    try out.print("Ran branch subcommand!\n", .{});
}

pub fn run_merge(out: *Io.Writer) !void {
    try out.print("Ran branch subcommand!\n", .{});
}

pub fn run_weave(out: *Io.Writer) !void {
    try out.print("Ran weave subcommand!\n", .{});
}
