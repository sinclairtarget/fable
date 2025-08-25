const std = @import("std");
const fs = std.fs;
const Io = std.Io;
const crypto = std.crypto;
const Allocator = std.mem.Allocator;

const Commit = @import("commit.zig").Commit;

const endian = std.builtin.Endian.big;

pub fn readCommit(alloc: Allocator, hash: []const u8) !*Commit {
    const cwd = fs.cwd();

    var obj = try cwd.openDir(".fable/obj", .{}); // TODO: Construct string
    defer obj.close();

    var file = try obj.openFile(hash, .{});
    defer file.close();

    var buf: [128]u8 = undefined;
    var file_reader = file.reader(&buf);
    const reader = &file_reader.interface;
    
    const commit = try alloc.create(Commit);
    errdefer alloc.destroy(commit);

    // Read message
    const message = blk: {
        const len = try reader.takeVarInt(u16, endian, 2);
        const s = try reader.take(len);
        const val = try alloc.alloc(u8, len);
        @memcpy(val, s);
        break :blk val;
    };
    errdefer alloc.free(message);

    // Read author
    const author = blk: {
        const len = try reader.takeVarInt(u16, endian, 2);
        const s = try reader.take(len);
        const val = try alloc.alloc(u8, len);
        @memcpy(val, s);
        break :blk val;
    };
    errdefer alloc.free(author);

    // Read timestamp
    const timestamp = blk: {
        _ = try reader.takeVarInt(u16, endian, 2);
        break :blk try reader.takeVarInt(i64, endian, 8);
    };

    // Read parent
    const parent = blk: {
        const len = try reader.takeVarInt(u16, endian, 2);
        if (len == 0) {
            break :blk null;
        }

        const s = try reader.take(len);
        const val = try alloc.alloc(u8, len);
        @memcpy(val, s);
        break :blk val;
    };

    commit.* = .{
        .message = message,
        .author = author,
        .timestamp = timestamp,
        .parent = parent,
    };
    
    // TODO: Check here that commit is valid?

    return commit;
}

pub fn saveCommit(commit: Commit) !void {
    var commit_buf: [512]u8 = undefined; // We will write the commit here
    var commit_writer: Io.Writer = .fixed(&commit_buf);

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
