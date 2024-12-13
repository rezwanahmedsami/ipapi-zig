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
    // Free the response buffer after usage (!!!!Important!!!!)
    defer response_buffer.deinit();

    // Query IP information
    const result = try ipapi.queryIp("8.8.8.8", allocator, &response_buffer);

    std.debug.print("{}\n", .{result});

    // const stdout = std.io.getStdOut().writer();
    // // Print the IP field
    // try stdout.print("IP: {s}\n", .{result.ip});

    // Create the response buffer for queryBulk to store the result from cURL
    var response_buffer_bulk = std.ArrayList(u8).init(allocator);
    // Free the response buffer after usage (!!!!Important!!!!)
    defer response_buffer_bulk.deinit();

    // Define the IPs as a slice
    const ips: []const []const u8 = &[_][]const u8{ "8.8.8.8", "1.1.1.1" };

    // Call queryBulk
    const results = try ipapi.queryBulk(ips, allocator, &response_buffer_bulk);

    // Print the results
    for (results) |ip_info| {
        std.debug.print("Queried IP: {s}\n", .{ip_info.ip});
    }

    // queryOwnIP
    const own_ip = try ipapi.queryOwnIp();
    std.debug.print("Own IP: {s}\n", .{own_ip});
}
