const std = @import("std");

pub fn run_init() !void {
    const out = std.io.getStdOut().writer();
    try out.print("Ran init subcommand!\n", .{});
}

pub fn run_new() !void {
    const out = std.io.getStdOut().writer();
    try out.print("Ran new subcommand!\n", .{});
}

pub fn run_record() !void {
    const out = std.io.getStdOut().writer();
    try out.print("Ran record subcommand!\n", .{});
}

pub fn run_status() !void {
    const out = std.io.getStdOut().writer();
    try out.print("Ran status subcommand!\n", .{});
}

pub fn run_tree() !void {
    const out = std.io.getStdOut().writer();
    try out.print("Ran tree subcommand!\n", .{});
}

pub fn run_log() !void {
    const out = std.io.getStdOut().writer();
    try out.print("Ran log subcommand!\n", .{});
}

pub fn run_commit() !void {
    const out = std.io.getStdOut().writer();
    try out.print("Ran commit subcommand!\n", .{});
}

pub fn run_checkout() !void {
    const out = std.io.getStdOut().writer();
    try out.print("Ran checkout subcommand!\n", .{});
}

pub fn run_branch() !void {
    const out = std.io.getStdOut().writer();
    try out.print("Ran branch subcommand!\n", .{});
}

pub fn run_weave() !void {
    const out = std.io.getStdOut().writer();
    try out.print("Ran weave subcommand!\n", .{});
}
