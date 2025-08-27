//! Functions for getting objects from and putting objects into the object
//! store.

const std = @import("std");
const fs = std.fs;
const Io = std.Io;
const crypto = std.crypto;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const model = @import("model.zig");
const Commit = model.Commit;
const Tree = model.Tree;
const Blob = model.Blob;

const endian = std.builtin.Endian.big;

pub fn computeHash(alloc: Allocator, bytes: []const u8) ![]const u8 {
    var h = crypto.hash.sha2.Sha256.init(.{});
    h.update(bytes);
    const digest = h.finalResult();
    const hexdigest = try std.fmt.allocPrint(alloc, "{x}", .{digest});
    return hexdigest;
}

pub fn getCommit(alloc: Allocator, hash: []const u8) !*Commit {
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

    // Read tree
    const tree = blk: {
        const len = try reader.takeVarInt(u16, endian, 2);
        const s = try reader.take(len);
        const val = try alloc.alloc(u8, len);
        @memcpy(val, s);
        break :blk val;
    };

    commit.* = .{
        .message = message,
        .author = author,
        .timestamp = timestamp,
        .tree = tree,
        .parent = parent,
    };

    // TODO: Check here that commit is valid?

    return commit;
}

pub fn putCommit(alloc: Allocator, commit: Commit) ![]const u8 {
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

    try commit_writer.writeInt(u16, @intCast(commit.tree.len), endian);
    try commit_writer.writeAll(commit.tree);

    // Now we hash it to get the filename
    const hexdigest = try computeHash(alloc, &commit_buf);

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

    return hexdigest;
}

pub fn getBlob(alloc: Allocator, hash: []const u8) !*Blob {
    _ = alloc;
    _ = hash;
    return null;
}

pub fn putBlob(alloc: Allocator, blob: Blob) ![]const u8 {
    const hexdigest = try computeHash(alloc, blob.bytes);

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
        try writer.writeAll(blob.bytes);
        try writer.flush();
    }

    return hexdigest;
}

pub fn getTree(alloc: Allocator, tree_hash: []const u8) !*Tree {
    std.debug.assert(tree_hash.len == model.hash_len);

    const cwd = fs.cwd();

    var obj = try cwd.openDir(".fable/obj", .{}); // TODO: Construct string
    defer obj.close();

    var file = try obj.openFile(tree_hash, .{});
    defer file.close();

    var buf: [128]u8 = undefined;
    var file_reader = file.reader(&buf);
    const reader = &file_reader.interface;

    const tree = try alloc.create(Tree);
    errdefer alloc.destroy(tree);

    var children: ArrayList(Tree.Item) = .empty;
    errdefer children.deinit(alloc);

    while (true) {
        const len = reader.takeVarInt(u16, endian, 2) catch |err| {
            if (err == error.EndOfStream) {
                break;
            }

            return err;
        };

        // Read path part
        var s = try reader.take(len);
        const path = try alloc.alloc(u8, len);
        @memcpy(path, s);

        // Read hash part
        s = try reader.take(model.hash_len);
        const hash = try alloc.alloc(u8, model.hash_len);
        @memcpy(hash, s);

        try children.append(alloc, .{ .path = path, .hash = hash });
    }

    tree.* = .{ .children = children.items };
    return tree;
}

pub fn putTree(alloc: Allocator, tree: Tree) ![]const u8 {
    var tree_buf: [512]u8 = undefined; // We will write the tree here
    var tree_writer: Io.Writer = .fixed(&tree_buf);

    for (tree.children) |item| {
        try tree_writer.writeInt(u16, @intCast(item.path.len), endian);
        try tree_writer.writeAll(item.path);
        try tree_writer.writeAll(item.hash);
    }

    const hexdigest = try computeHash(alloc, &tree_buf);

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
        try writer.writeAll(tree_writer.buffered());
        try writer.flush();
    }

    return hexdigest;
}
