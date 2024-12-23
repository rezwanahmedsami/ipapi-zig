const std = @import("std");
const testing = std.testing;
const cURL = @cImport({
    @cInclude("curl/curl.h");
});

/// The base URL for the ipquery.io API.
const BASE_URL: []const u8 = "https://api.ipquery.io/";

/// Represents information about an ISP (Internet Service Provider).
const IspInfo = struct {
    /// The Autonomous System Number (ASN) of the ISP.
    asn: []const u8,
    /// The organization associated with the ISP.
    org: []const u8,
    /// The name of the ISP.
    isp: []const u8,
};

/// Represents information about the geographical location of an IP address.
const LocationInfo = struct {
    /// The country name.
    country: []const u8,
    /// The ISO country code.
    country_code: []const u8,
    /// The city name.
    city: []const u8,
    /// The state or region.
    state: []const u8,
    /// The postal or ZIP code.
    zipcode: []const u8,
    /// The latitude of the location.
    latitude: f64,
    /// The longitude of the location.
    longitude: f64,
    /// The timezone of the location.
    timezone: []const u8,
    /// The local time in the specified timezone.
    localtime: []const u8,
};

/// Represents information about potential risks associated with an IP address.
const RiskInfo = struct {
    /// Indicates if the IP is associated with a mobile network.
    is_mobile: bool,
    /// Indicates if the IP is using a VPN.
    is_vpn: bool,
    /// Indicates if the IP is part of the Tor network.
    is_tor: bool,
    /// Indicates if the IP is using a proxy.
    is_proxy: bool,
    /// Indicates if the IP is associated with a data center.
    is_datacenter: bool,
    /// A score indicating the risk level (0-100).
    risk_score: u8,
};

/// Represents the full set of information returned by the API for an IP address.
pub const IpInfo = struct {
    /// The IP address.
    ip: []const u8,
    /// Information about the ISP.
    isp: IspInfo,
    /// Information about the location.
    location: LocationInfo,
    /// Information about potential risks.
    risk: RiskInfo,
};
fn writeToArrayListCallback(data: *anyopaque, size: c_uint, nmemb: c_uint, user_data: *anyopaque) callconv(.C) c_uint {
    var buffer: *std.ArrayList(u8) = @alignCast(@ptrCast(user_data));
    var typed_data: [*]u8 = @ptrCast(data);
    buffer.appendSlice(typed_data[0 .. nmemb * size]) catch return 0;
    return nmemb * size;
}

/// Returns an error if the network request fails or the response cannot be deserialized.
/// Otherwise, returns the IP information.
/// /**
/// * Queries the ipquery.io API for information about the specified IP address.
/// * @param ip The IP address to query.
/// * @param allocator The allocator to use for deserialization.
/// * @param response_buffer A buffer to store the response from cURL.
/// * @return The IP information if successful, or an error if the request fails.
/// */
/// Example usage:
/// ```zig
/// const std = @import("std");
/// const ipapi = @import("ipapi.zig");
///
/// pub fn main() !void {
///
///    // Initialize the arena allocator
///   var arena_state = std.heap.ArenaAllocator.init(std.heap.c_allocator);
///   // Defer the deinitialization of the arena allocator
///  defer arena_state.deinit();
///
/// // Get the allocator from the arena allocator
/// const allocator = arena_state.allocator();
///
/// // Create the response buffer to store the result from cURL
/// var response_buffer = std.ArrayList(u8).init(allocator);
///
/// // Query IP information
/// const result = try ipapi.queryIp("8.8.8.8", allocator, &response_buffer);
///
/// std.debug.print("{}\n", .{result});
///
/// const stdout = std.io.getStdOut().writer();
/// // Print the IP field
/// try stdout.print("IP: {s}\n", .{result.ip});
///
/// // Free the response buffer after usage (!!!!Important!!!!)
/// response_buffer.deinit();
/// }
/// ```
///
///
pub fn queryIp(ip: []const u8, allocator: std.mem.Allocator, response_buffer: *std.ArrayList(u8)) !IpInfo {
    var url_buffer: [256]u8 = undefined;
    const url_len_slice = try std.fmt.bufPrint(&url_buffer, "{s}{s}", .{ BASE_URL, ip });
    const url_len = url_len_slice.len;
    url_buffer[url_len] = 0;
    const url = &url_buffer[0 .. url_len + 1];

    // std.debug.print("URL: {s}\n", .{url.*});

    // // Global curl init
    // if (cURL.curl_global_init(cURL.CURL_GLOBAL_ALL) != cURL.CURLE_OK)
    //     return error.CURLGlobalInitFailed;
    // defer cURL.curl_global_cleanup();

    // Curl easy handle init
    const handle = cURL.curl_easy_init();
    defer cURL.curl_easy_cleanup(handle);

    // Setup curl options
    if (cURL.curl_easy_setopt(handle, cURL.CURLOPT_URL, url.ptr) != cURL.CURLE_OK)
        return error.CouldNotSetURL;

    // Set write function callbacks
    if (cURL.curl_easy_setopt(handle, cURL.CURLOPT_WRITEFUNCTION, writeToArrayListCallback) != cURL.CURLE_OK)
        return error.CouldNotSetWriteCallback;
    if (cURL.curl_easy_setopt(handle, cURL.CURLOPT_WRITEDATA, response_buffer) != cURL.CURLE_OK)
        return error.CouldNotSetWriteCallback;

    // Perform the request
    if (cURL.curl_easy_perform(handle) != cURL.CURLE_OK)
        return error.FailedToPerformRequest;

    // std.log.info("Got response of {d} bytes", .{response_buffer.items.len});
    // std.debug.print("{s}\n", .{response_buffer.items});

    // Deserialize the response
    const parsed = try std.json.parseFromSlice(
        IpInfo,
        allocator,
        response_buffer.items,
        .{},
    );
    defer parsed.deinit();

    const json = parsed.value;
    // std.debug.print("ip2: {s}\n", .{json.ip});

    return json;
}
/// Joins an array of IP addresses into a comma-separated string.
pub fn joinIps(ip_arr: []const []const u8, allocator: std.mem.Allocator) ![]const u8 {
    var builder = std.ArrayList(u8).init(allocator);
    defer builder.deinit();

    var first = true;
    for (ip_arr) |ip| {
        if (!first) {
            try builder.appendSlice(","); // Comma separator
        } else {
            first = false;
        }
        try builder.appendSlice(ip);
    }

    return builder.toOwnedSlice();
}

/// Fetches information for multiple IP addresses.
///
/// The function queries the ipquery.io API for information about multiple IP addresses.
///
/// # Parameters
/// - `ip_arr`: An array of IP addresses to query.
/// - `allocator`: The allocator to use for deserialization.
/// - `response_buffer`: A buffer to store the response from cURL.
///
/// # Returns
/// An array of `IpInfo` structs containing the information for each IP address.
///
/// # Example
/// ```zig
/// const std = @import("std");
/// const ipapi = @import("ipapi.zig");
///
/// pub fn main() !void {
///
///    // Initialize the arena allocator
///  var arena_state = std.heap.ArenaAllocator.init(std.heap.c_allocator);
/// // Defer the deinitialization of the arena allocator
///  defer arena_state.deinit();
///
/// // Get the allocator from the arena allocator
/// const allocator = arena_state.allocator();
/// var response_buffer_bulk = std.ArrayList(u8).init(allocator);
/// // Free the response buffer after usage (!!!!Important!!!!)
/// defer response_buffer_bulk.deinit();
/// // Define the IPs as a slice
/// const ips: []const []const u8 = &[_][]const u8{ "8.8.8.8", "1.1.1.1" };
/// // Call queryBulk
/// const results = try ipapi.queryBulk(ips, allocator, &response_buffer_bulk);
/// // Print the results
/// for (results) |ip_info| {
///     std.debug.print("Queried IP: {s}\n", .{ip_info.ip});
/// }
pub fn queryBulk(ip_arr: []const []const u8, allocator: std.mem.Allocator, response_buffer: *std.ArrayList(u8)) ![]IpInfo {
    // Initialize the result list
    var result_list = std.ArrayList(IpInfo).init(allocator);
    defer result_list.deinit();

    //ip_arr to ip,ip
    const ips = try joinIps(ip_arr, allocator);

    // Construct the URL
    var url_buffer: [256]u8 = undefined;
    const url_len_slice = try std.fmt.bufPrint(&url_buffer, "{s}{s}", .{ BASE_URL, ips });
    const url_len = url_len_slice.len;
    url_buffer[url_len] = 0;

    const url = &url_buffer[0 .. url_len + 1];

    // Global curl init
    // if (cURL.curl_global_init(cURL.CURL_GLOBAL_ALL) != cURL.CURLE_OK)
    //     return error.CURLGlobalInitFailed;
    // defer cURL.curl_global_cleanup();

    // Curl easy handle init
    const handle = cURL.curl_easy_init();
    defer cURL.curl_easy_cleanup(handle);

    // Setup curl options
    if (cURL.curl_easy_setopt(handle, cURL.CURLOPT_URL, url.ptr) != cURL.CURLE_OK)
        return error.CouldNotSetURL;

    // Set write function callbacks
    if (cURL.curl_easy_setopt(handle, cURL.CURLOPT_WRITEFUNCTION, writeToArrayListCallback) != cURL.CURLE_OK)
        return error.CouldNotSetWriteCallback;

    if (cURL.curl_easy_setopt(handle, cURL.CURLOPT_WRITEDATA, response_buffer) != cURL.CURLE_OK)
        return error.CouldNotSetWriteCallback;

    // Perform the request
    if (cURL.curl_easy_perform(handle) != cURL.CURLE_OK)
        return error.FailedToPerformRequest;

    // Deserialize the response
    const parsed = try std.json.parseFromSlice(
        []IpInfo,
        allocator,
        response_buffer.items,
        .{},
    );

    // Append the results to the result list
    for (parsed.value) |ip_info| {
        try result_list.append(ip_info);
    }

    // Return the results as a slice
    return result_list.toOwnedSlice();
}

/// Fetches the IP address of the current machine.
pub fn queryOwnIp() ![]const u8 {
    const allocator = std.heap.page_allocator;
    var response_buffer = std.ArrayList(u8).init(allocator);
    defer response_buffer.deinit();

    // Use BASE_URL directly
    const url = BASE_URL;

    // Curl easy handle init
    const handle = cURL.curl_easy_init();
    if (handle == null) {
        return error.CouldNotInitCurlHandle; // Handle the case if the handle could not be initialized
    }
    defer cURL.curl_easy_cleanup(handle);

    // Setup curl options
    if (cURL.curl_easy_setopt(handle, cURL.CURLOPT_URL, url.ptr) != cURL.CURLE_OK) {
        return error.CouldNotSetURL;
    }

    // Set write function callbacks
    if (cURL.curl_easy_setopt(handle, cURL.CURLOPT_WRITEFUNCTION, writeToArrayListCallback) != cURL.CURLE_OK) {
        return error.CouldNotSetWriteCallback;
    }

    if (cURL.curl_easy_setopt(handle, cURL.CURLOPT_WRITEDATA, &response_buffer) != cURL.CURLE_OK) {
        return error.CouldNotSetWriteCallback;
    }

    // Perform the request
    if (cURL.curl_easy_perform(handle) != cURL.CURLE_OK) {
        std.debug.print("Failed to perform request {}\n", .{cURL.curl_easy_perform(handle)});
        return error.FailedToPerformRequest;
    }

    // Return the data in the response buffer as a slice
    return response_buffer.toOwnedSlice();
}

test "Testing queryIp" {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();

    // Use arena_state.allocator() instead of arena.allocator
    var response_buffer = std.ArrayList(u8).init(arena_state.allocator());
    defer response_buffer.deinit();
    const result = try queryIp("8.8.8.8", arena_state.allocator(), &response_buffer);
    // std.debug.print("{s}\n", .{result.ip});
    const ip_g: []const u8 = "8.8.8.8";
    try testing.expect(std.mem.eql(u8, result.ip, ip_g));
    try testing.expect(std.mem.eql(u8, result.isp.asn, "AS15169"));
    try testing.expect(std.mem.eql(u8, result.isp.org, "Google LLC"));
    try testing.expect(std.mem.eql(u8, result.isp.isp, "Google LLC"));
    try testing.expect(std.mem.eql(u8, result.location.country, "United States"));
    try testing.expect(std.mem.eql(u8, result.location.country_code, "US"));
    try testing.expect(std.mem.eql(u8, result.location.city, "Mountain View"));
    try testing.expect(std.mem.eql(u8, result.location.state, "California"));
    try testing.expect(std.mem.eql(u8, result.location.zipcode, "94043"));
    try testing.expect(std.mem.eql(u8, result.location.timezone, "America/Los_Angeles"));
}

test "Testing queryBulk" {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();

    var response_buffer = std.ArrayList(u8).init(arena_state.allocator());
    defer response_buffer.deinit();

    const ips: []const []const u8 = &[_][]const u8{ "8.8.8.8", "1.1.1.1" };

    const results = try queryBulk(ips, arena_state.allocator(), &response_buffer);

    try testing.expect(results.len == 2);

    const ip1: []const u8 = "8.8.8.8";
    const ip2: []const u8 = "1.1.1.1";

    try testing.expect(std.mem.eql(u8, results[0].ip, ip1));
    try testing.expect(std.mem.eql(u8, results[1].ip, ip2));

    try testing.expect(std.mem.eql(u8, results[0].isp.asn, "AS15169"));
    try testing.expect(std.mem.eql(u8, results[1].isp.asn, "AS13335"));

    try testing.expect(std.mem.eql(u8, results[0].isp.org, "Google LLC"));
    try testing.expect(std.mem.eql(u8, results[1].isp.org, "Cloudflare, Inc."));
}
