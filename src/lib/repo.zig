const std = @import("std");
const fs = std.fs;
const Io = std.Io;
const crypto = std.crypto;
const Allocator = std.mem.Allocator;

const Commit = @import("commit.zig").Commit;

const fable_dirname = ".fable";
const obj_dirname = "obj";
const refs_dirname = "refs";

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

    // Ensure .fable/refs exists
    fable.makeDir(refs_dirname) catch |e| {
        switch (e) {
            error.PathAlreadyExists => {}, // cool, no-op
            else => return e,
        }
    };

    // Make root commit
    const commit = Commit{
        .message = "root commit",
        .author = "fable",
        .timestamp = std.time.timestamp(),
        .parent = null,
    };
    try saveCommit(commit);
}

pub fn makeCommit(alloc: Allocator, message: []const u8) !void {
    const head_commit_hash = try getHeadCommit(alloc);
    const commit = Commit{
        .message = message,
        .author = "Sinclair Target",
        .timestamp = std.time.timestamp(),
        .parent = head_commit_hash,
    };
    try saveCommit(commit);
}

fn saveCommit(commit: Commit) !void {
    var commit_buf: [512]u8 = undefined; // We will write the commit here
    var commit_writer: Io.Writer = .fixed(&commit_buf);

    const endian = std.builtin.Endian.big;

    try commit_writer.writeInt(u16, @intCast(commit.message.len), endian);
    try commit_writer.writeAll(commit.message);
    try commit_writer.writeInt(u16, @intCast(commit.author.len), endian);
    try commit_writer.writeAll(commit.author);
    try commit_writer.writeInt(u16, 8, endian);
    try commit_writer.writeInt(i64, commit.timestamp, endian);

    if (commit.parent) |parent| {
        try commit_writer.writeInt(u16, @intCast(parent.len), endian);
        try commit_writer.writeAll(parent);
    } else {
        try commit_writer.writeInt(u16, 0, endian);
    }

    // Now we hash it to get the filename
    var h = crypto.hash.sha2.Sha256.init(.{});
    h.update(&commit_buf);
    const digest = h.finalResult();

    var scratch: [256]u8 = undefined;
    const hexdigest = try std.fmt.bufPrint(&scratch, "{x}", .{digest});

    const cwd = fs.cwd();

    // Write file to obj db
    {
        var obj = try cwd.openDir(".fable/obj", .{}); // TODO: Construct string
        defer obj.close();

        var file = try obj.createFile(hexdigest, .{});
        defer file.close();

        var buf: [128]u8 = undefined;
        var file_writer = file.writer(&buf);
        const writer = &file_writer.interface;
        try writer.writeAll(commit_writer.buffered());
        try writer.flush();
    }

    // Write commit hash to refs/HEAD
    {
        var refs = try cwd.openDir(".fable/refs", .{}); // TODO: Construct string
        defer refs.close();

        var file = try refs.createFile("HEAD", .{});
        defer file.close();

        var buf: [128]u8 = undefined;
        var file_writer = file.writer(&buf);
        const writer = &file_writer.interface;
        try writer.writeAll(hexdigest);
        try writer.writeByte('\n');
        try writer.flush();
    }
}

pub fn getHeadCommit(alloc: Allocator) ![]const u8 {
    const buf: []u8 = try alloc.alloc(u8, 128);

    const head_commit_hash = blk: {
        const cwd = fs.cwd();

        var refs = try cwd.openDir(".fable/refs", .{}); // TODO: Construct string
        defer refs.close();

        var file = try refs.openFile("HEAD", .{});
        defer file.close();

        var file_reader = file.reader(buf);
        const reader = &file_reader.interface;
        break :blk try reader.takeDelimiterExclusive('\n');
    };

    return head_commit_hash;
}
