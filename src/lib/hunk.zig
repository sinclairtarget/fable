pub const Hunk = struct {
    path: []const u8,
    offset: u16, // Cannot support files longer than 65k lines
    lines_deleted: []const []const u8,
    lines_added: []const []const u8,
};
