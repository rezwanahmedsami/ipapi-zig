const std = @import("std");
const ipapi = @import("ipapi.zig");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    // Query IP information
    const result = try ipapi.queryIp("8.8.8.8");
    // ipapi.queryIp("8.8.8.8");

    std.debug.print("{}\n", .{result});

    // Print the IP field
    try stdout.print("IP: {s}\n", .{result.ip});
}
