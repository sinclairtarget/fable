pub const hash_len = 64; // Length of hex digest

pub const Commit = struct {
    message: []const u8,
    author: []const u8,
    timestamp: i64,
    tree: []const u8,
    parent: ?[]const u8,
};

pub const Tree = struct {
    children: []Item, // Always stored in sorted order
    
    pub const Item = struct {
        path: []const u8, // Should be "name" maybe
        hash: []const u8,
    };
};

pub const Blob = struct {
    bytes: []const u8,
};
