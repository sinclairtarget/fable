const std = @import("std");
const fs = std.fs;
const Allocator = std.mem.Allocator;

const Commit = @import("commit.zig").Commit;
const db = @import("db.zig");

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
    try db.saveCommit(commit);
}

pub fn makeCommit(alloc: Allocator, message: []const u8) !void {
    const head_commit_hash = try getHeadCommit(alloc);
    const commit = Commit{
        .message = message,
        .author = "Sinclair Target",
        .timestamp = std.time.timestamp(),
        .parent = head_commit_hash,
    };
    try db.saveCommit(commit);
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
        const commit = try db.readCommit(self.alloc, hash);
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
