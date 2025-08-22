const std = @import("std");
const fs = std.fs;

const fable_dirname = ".fable";
const obj_dirname = "obj";

pub fn reinit() !void {
    const current = fs.cwd();

    // Ensure .fable directory exists
    current.makeDir(fable_dirname) catch |e| {
        switch (e) {
            error.PathAlreadyExists => {}, // cool, no-op
            else => return e,
        }
    };

    var fable = try current.openDir(fable_dirname, .{});
    defer fable.close();

    // Ensure .fable/obj exists
    fable.makeDir(obj_dirname) catch |e| {
        switch (e) {
            error.PathAlreadyExists => {}, // cool, no-op
            else => return e,
        }
    };
}
