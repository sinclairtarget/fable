const std = @import("std");
const fs = std.fs;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const model = @import("model.zig");
const db = @import("db.zig");
const Commit = model.Commit;
const Tree = model.Tree;
const Blob = model.Blob;

const fable_dirname = ".fable";
const obj_dirname = "obj";
const refs_dirname = "refs";

pub fn reinit(alloc: Allocator) !void {
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

    // Root commit has empty tree
    const empty_tree = Tree{
        .children = &[_]Tree.Item{},
    };
    const tree_hash = try db.putTree(alloc, empty_tree);

    // Make root commit
    const commit = Commit{
        .message = "root commit",
        .author = "fable",
        .timestamp = std.time.timestamp(),
        .tree = tree_hash,
        .parent = null,
    };
    try db.putCommit(commit);
}

pub fn makeCommit(alloc: Allocator, message: []const u8) !void {
    const tree_hash = try makeTree(alloc, ".");
    const head_commit_hash = try getHeadCommit(alloc);
    const commit = Commit{
        .message = message,
        .author = "Sinclair Target",
        .timestamp = std.time.timestamp(),
        .tree = tree_hash,
        .parent = head_commit_hash,
    };
    try db.putCommit(commit);
}

fn lessThan(ctx: void, lhs: Tree.Item, rhs: Tree.Item) bool {
    _ = ctx;
    return std.mem.order(u8, lhs.hash, rhs.hash) == .lt;
}

fn makeTree(alloc: Allocator, dirpath: []const u8) ![]const u8 {
    const cwd = fs.cwd();
    var dir = try cwd.openDir(dirpath, .{.iterate = true});
    defer dir.close();

    var tree_items: ArrayList(Tree.Item) = .empty;
    defer tree_items.deinit(alloc);

    var iter = dir.iterate();
    while (try iter.next()) |entry| {
        if (std.mem.eql(u8, entry.name, ".fable")) {
            continue; // ignore!
        }

        // TODO: Are we sure we want to use the OS-specific path separator?
        const path = try fs.path.join(
            alloc, 
            &[_][]const u8{dirpath, entry.name},
        );

        if (entry.kind == .file) {
            const hash = try makeBlob(alloc, path);
            try tree_items.append(alloc, .{.path = entry.name, .hash = hash});
        } else if (entry.kind == .directory) {
            const hash = try makeTree(alloc, path);
            try tree_items.append(alloc, .{.path = entry.name, .hash = hash});
        }
    }

    // Ensure tree items are always in the same order! Sort by hash
    std.sort.heap(Tree.Item, tree_items.items, {}, lessThan);

    const tree_hash = try db.putTree(alloc, .{.children = tree_items.items});
    return tree_hash;
}

fn makeBlob(alloc: Allocator, path: []const u8) ![]const u8 {
    const cwd = fs.cwd();
    var file = try cwd.openFile(path, .{});
    defer file.close();

    var buf: [128]u8 = undefined;
    var file_reader = file.reader(&buf);
    const reader = &file_reader.interface;

    var bytes: ArrayList(u8) = .empty;
    defer bytes.deinit(alloc);
    try reader.appendRemainingUnlimited(alloc, &bytes);

    const blob = Blob{
        .bytes = bytes.items,
    };
    const hash = try db.putBlob(alloc, blob);
    return hash;
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

const CommitIterator = struct {
    current_hash: ?[]const u8,
    next_hash: ?[]const u8,
    alloc: Allocator,

    pub fn next(self: *CommitIterator) !?*Commit {
        const hash = self.next_hash orelse return null;
        const commit = try db.getCommit(self.alloc, hash);
        self.current_hash = hash;
        self.next_hash = commit.parent;
        return commit;
    }
};

pub fn commitsIterator(alloc: Allocator) !CommitIterator {
    const head_commit_hash = try getHeadCommit(alloc);
    return .{
        .current_hash = null,
        .next_hash = head_commit_hash,
        .alloc = alloc,
    };
}
