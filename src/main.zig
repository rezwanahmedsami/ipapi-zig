const std = @import("std");
const ipapi = @import("ipapi.zig");

pub fn main() !void {

    // Initialize the arena allocator
    var arena_state = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    // Defer the deinitialization of the arena allocator
    defer arena_state.deinit();

    // Get the allocator from the arena allocator
    const allocator = arena_state.allocator();

    // Create the response buffer to store the result from cURL
    var response_buffer = std.ArrayList(u8).init(allocator);

    // Query IP information
    const result = try ipapi.queryIp("8.8.8.8", allocator, &response_buffer);

    std.debug.print("{}\n", .{result});

    const stdout = std.io.getStdOut().writer();
    // Print the IP field
    try stdout.print("IP: {s}\n", .{result.ip});

    // Free the response buffer after usage (!!!!Important!!!!)
    response_buffer.deinit();
}
