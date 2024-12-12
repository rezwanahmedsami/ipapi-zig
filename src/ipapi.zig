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
/// queryIp("8.8.8.8") BASE)URL+"8.8.8.8"
pub fn queryIp(ip: []const u8) !IpInfo {
    // Dynamically format the URL
    // var url_buffer: [256]u8 = undefined;
    // const url_len = try std.fmt.bufPrint(&url_buffer, "{s}{s}", .{ BASE_URL, ip });

    // // Ensure null termination at the end of the used portion of the buffer
    // url_buffer[url_len] = 0; // Null-terminate the string at the correct index
    // const url = "https://api.ipquery.io/8.8.8.8";
    // std.log.info("Querying IP address {s}", .{ip});

    var url_buffer: [256]u8 = undefined;
    const url_len_slice = try std.fmt.bufPrint(&url_buffer, "{s}{s}", .{ BASE_URL, ip });

    // Calculate the length of the formatted string
    const url_len = url_len_slice.len;

    // Null-terminate the URL
    url_buffer[url_len] = 0;

    // Define the URL slice including the null terminator
    const url = &url_buffer[0 .. url_len + 1];

    // std.debug.print("URL: {s}\n", .{url.*});

    var arena_state = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena_state.deinit();

    const allocator = arena_state.allocator();

    // Global curl init
    if (cURL.curl_global_init(cURL.CURL_GLOBAL_ALL) != cURL.CURLE_OK)
        return error.CURLGlobalInitFailed;
    // std.debug.print("CURLGlobalInitFailed\n", .{});
    defer cURL.curl_global_cleanup();

    // Curl easy handle init
    const handle = cURL.curl_easy_init();
    defer cURL.curl_easy_cleanup(handle);

    var response_buffer = std.ArrayList(u8).init(allocator);
    defer response_buffer.deinit();

    // Setup curl options
    if (cURL.curl_easy_setopt(handle, cURL.CURLOPT_URL, url.ptr) != cURL.CURLE_OK)
        return error.CouldNotSetURL;
    // std.debug.print("CouldNotSetURL\n", .{});

    // Set write function callbacks
    if (cURL.curl_easy_setopt(handle, cURL.CURLOPT_WRITEFUNCTION, writeToArrayListCallback) != cURL.CURLE_OK)
        return error.CouldNotSetWriteCallback;
    // std.debug.print("CouldNotSetWriteCallback\n", .{});
    if (cURL.curl_easy_setopt(handle, cURL.CURLOPT_WRITEDATA, &response_buffer) != cURL.CURLE_OK)
        return error.CouldNotSetWriteCallback;
    // std.debug.print("CouldNotSetWriteCallback\n", .{});

    // Perform the request
    if (cURL.curl_easy_perform(handle) != cURL.CURLE_OK)
        return error.FailedToPerformRequest;
    // std.debug.print("FailedToPerformRequest\n", .{});

    std.log.info("Got response of {d} bytes", .{response_buffer.items.len});
    std.debug.print("{s}\n", .{response_buffer.items});

    // Deserialize the response
    const parsed = try std.json.parseFromSlice(
        IpInfo,
        allocator,
        response_buffer.items,
        .{},
    );
    defer parsed.deinit();

    const json = parsed.value;
    std.debug.print("ip2: {s}\n", .{json.ip});

    return json;
}
