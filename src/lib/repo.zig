const std = @import("std");
const fs = std.fs;
const Io = std.Io;

const Commit = @import("commit.zig").Commit;

const fable_dirname = ".fable";
const obj_dirname = "obj";

pub fn reinit() !void {
    const cwd = fs.cwd();

    // Ensure .fable directory exists
    cwd.makeDir(fable_dirname) catch |e| {
        switch (e) {
            error.PathAlreadyExists => {}, // cool, no-op
            else => return e,
        }
    };

    var fable = try cwd.openDir(fable_dirname, .{});
    defer fable.close();

    // Ensure .fable/obj exists
    fable.makeDir(obj_dirname) catch |e| {
        switch (e) {
            error.PathAlreadyExists => {}, // cool, no-op
            else => return e,
        }
    };
}

pub fn saveCommit(message: []const u8) !void {
    const now = std.time.timestamp();

    const commit = Commit{
        .message = message,
        .author = "Sinclair Target",
        .timestamp = now,
    };

    const cwd = fs.cwd();

    var obj = try cwd.openDir(".fable/obj", .{}); // TODO: Construct string
    defer obj.close();

    var file = try obj.createFile("commit", .{});
    defer file.close();

    var buf: [128]u8 = undefined;
    var file_writer = file.writer(&buf);
    const writer = &file_writer.interface;

    const endian = std.builtin.Endian.little;

    try writer.writeInt(u16, @intCast(commit.message.len), endian);
    try writer.writeAll(commit.message);
    try writer.writeInt(u16, @intCast(commit.author.len), endian);
    try writer.writeAll(commit.author);
    try writer.writeInt(u16, 8, endian);
    try writer.writeInt(i64, commit.timestamp, endian);
    try writer.flush();
}
