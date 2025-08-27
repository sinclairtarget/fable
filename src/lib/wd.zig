//! Working directory functions.

const std = @import("std");
const fs = std.fs;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub const FileIterator = struct {
    alloc: Allocator,
    cwd: fs.Dir,
    walker: fs.Dir.Walker,
    filter: *const fn (p: []const u8) bool,

    pub const Entry = struct {
        path: []const u8,
    };

    // Path name is allocated on heap and owned by caller
    pub fn next(self: *FileIterator) !?Entry {
        const entry = while (true) {
            const e = (try self.walker.next()) orelse return null;
            if (e.kind == .file and self.filter(e.path)) {
                break e;
            }
        };

        return .{
            .path = try self.alloc.dupe(u8, entry.path),
        };
    }

    pub fn deinit(self: *FileIterator) void {
        self.walker.deinit();
        self.cwd.close();
    }
};

fn filterFable(path: []const u8) bool {
    return !std.mem.startsWith(u8, path, ".fable");
}

pub fn walkFiles(alloc: Allocator) !FileIterator {
    var cwd = try fs.cwd().openDir(".", .{ .iterate = true });
    errdefer cwd.close();

    const walker = try cwd.walk(alloc);

    return .{
        .alloc = alloc,
        .cwd = cwd,
        .walker = walker,
        .filter = filterFable,
    };
}

pub fn readFileContents(alloc: Allocator, path: []const u8) ![]const u8 {
    const cwd = fs.cwd();
    var file = try cwd.openFile(path, .{});
    defer file.close();

    var buf: [128]u8 = undefined;
    var file_reader = file.reader(&buf);
    const reader = &file_reader.interface;

    var bytes: ArrayList(u8) = .empty;
    defer bytes.deinit(alloc);
    try reader.appendRemainingUnlimited(alloc, &bytes);

    return bytes.items;
}
