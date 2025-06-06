pub const LogicalMap = @import("map/logic.zig").LogicalMap;

test {
    @import("std").testing.refAllDecls(@This());
}
