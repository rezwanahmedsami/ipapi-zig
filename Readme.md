# ipapi-zig

`ipapi-zig` is a Zig library for querying IP addresses using the [ipquery.io](https://ipquery.io) API.

## Features

- Query details for a specific IP address.
- Bulk query multiple IP addresses.
- Fetch your own public IP address.

## Installation

To integrate this library into your own Zig project, you can use `git` and the `build.zig` system.

### Prerequisites

- [Zig](https://ziglang.org/download/) version 0.10 or later.

### 1. Clone the Repository

Clone the repository into your project directory:

```bash
git clone https://github.com/rezwanahmedsami/ipapi-zig.git
```

### 2. Add the Library to Your `build.zig`

In your project’s `build.zig`, add this library as a dependency. For example:

```zig
const std = @import("std");
const ipapi = b.addExecutable("ipapi-example", "src/main.zig");
ipapi.linkLibC();
ipapi.addPackagePath("ipapi", "./path/to/ipapi-zig");

const ipapi_zig = ipapi.addPackage("ipapi", "./path/to/ipapi-zig/src");
```

### 3. Build the Project

After adding the library, you can build your project as usual with:

```bash
zig build
```

## Usage

### Query a Specific IP Address

To query information about a specific IP address, you can use the `queryIp` function. Here's an example of how to use it:

```zig
const std = @import("std");
const ipapi = @import("ipapi.zig");

pub fn main() void {
    const allocator = std.heap.page_allocator;

    // Create the response buffer to store the result from cURL
    var response_buffer = std.ArrayList(u8).init(allocator);
    // Free the response buffer after usage (!!!!Important!!!!)
    defer response_buffer.deinit();
    
    // Query a specific IP address
    const result = ipapi.queryIp("8.8.8.8", allocator, &response_buffer);
    
    std.debug.print("{}\n", .{result});
}
```

#### Output Example
```plaintext
IPInfo {
    ip: "8.8.8.8",
    isp: { asn: "AS15169", org: "Google LLC", isp: "Google LLC" },
    location: {
        country: "United States",
        country_code: "US",
        city: "Mountain View",
        state: "California",
        zipcode: "94043",
        latitude: 37.436,
        longitude: -122.0938,
        timezone: "America/Los_Angeles",
        localtime: "2024-12-11T18:26:48"
    },
    risk: {
        is_mobile: false,
        is_vpn: false,
        is_tor: false,
        is_proxy: false,
        is_datacenter: true,
        risk_score: 0
    }
}
```

### Bulk Query Multiple IP Addresses

To query multiple IP addresses at once, use the `queryBulk` function:

```zig
const std = @import("std");
const ipapi = @import("ipapi.zig");

pub fn main() void {
    const allocator = std.heap.page_allocator;

    // Create the response buffer to store the result from cURL
    var response_buffer = std.ArrayList(u8).init(allocator);
    // Free the response buffer after usage (!!!!Important!!!!)
    defer response_buffer.deinit();
    
    // Define multiple IPs to query
    const ips = &[_][]const u8{ "8.8.8.8", "1.1.1.1" };
    
    // Perform bulk query
    const results = ipapi.queryBulk(ips, allocator, &response_buffer);
    
    // Print the results for each IP
    for (results) |ip_info| {
        std.debug.print("Queried IP: {s}\n", .{ip_info.ip});
    }
}
```

#### Output Example
```plaintext
Queried IP: 8.8.8.8
Queried IP: 1.1.1.1
```

### Fetch Your Own Public IP Address

Use the `queryOwnIp` function to fetch your own public IP address:

```zig
const std = @import("std");
const ipapi = @import("ipapi.zig");

pub fn main() void {
    const allocator = std.heap.page_allocator;
    
    // Get the public IP address of the current machine
    const own_ip = ipapi.queryOwnIp();
    
    std.debug.print("Own IP: {s}\n", .{own_ip});
}
```

#### Output Example
```plaintext
Own IP: 203.0.113.45
```

## Library Functions

### `queryIp`

```zig
fn queryIp(ip: []const u8, allocator: std.mem.Allocator, response_buffer: *std.ArrayList(u8)) !IPInfo;
```

#### Description

Fetches detailed information about a specific IP address, including its ISP, location, and risk information.

#### Parameters

- `ip`: The IP address to query (as a `[]const u8`).
- `allocator`: The allocator to use for memory allocation.
- `response_buffer`: A buffer to store the response from cURL.

#### Returns

- An `IPInfo` struct containing details about the queried IP address.
- An error if the query fails.

---

### `queryBulk`

```zig
fn queryBulk(ips: [][]const u8, allocator: std.mem.Allocator, response_buffer: *std.ArrayList(u8)) ![]IPInfo;
```

#### Description

Fetches information for multiple IP addresses in a single request.

#### Parameters

- `ips`: A list of IP addresses to query (as a `[][]const u8`).
- `allocator`: The allocator to use for memory allocation.
- `response_buffer`: A buffer to store the response from cURL.

#### Returns

- A slice of `IPInfo` structs containing the information for each IP address.
- An error if the query fails.

---

### `queryOwnIp`

```zig
fn queryOwnIp() ![]const u8;
```

#### Description

Fetches the public IP address of the current machine.

#### Returns

- A `[]const u8` containing the public IP address.
- An error if the query fails.

## Running Tests

To run the library tests (if any), use the following command:

```bash
zig build test
```

This will execute any tests defined within the project and display the results in the terminal.

## Contributing

Contributions are welcome! If you find any bugs or have improvements, feel free to submit an issue or pull request to the [GitHub repository](https://github.com/rezwanahmedsami/ipapi-zig).