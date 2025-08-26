//! Working directory functions.

const std = @import("std");
const fs = std.fs;
const Allocator = std.mem.Allocator;

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

pub fn walkFiles(
    alloc: Allocator, 
    filter: *const fn (p: []const u8) bool,
) !FileIterator {
    var cwd = try fs.cwd().openDir(".", .{ .iterate = true });
    errdefer cwd.close();

    const walker = try cwd.walk(alloc);

    return .{ 
        .alloc = alloc,
        .cwd = cwd,
        .walker = walker,
        .filter = filter,
    };
}
