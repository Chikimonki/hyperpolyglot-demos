const std = @import("std");
const net = std.net;

// Node state
const NodeState = enum {
    follower,
    candidate,
    leader,
};

// Configuration
const config = struct {
    const node_id: []const u8 = "zig_compute_1";
    const listen_port: u16 = 5001;
    const heartbeat_interval_ms: u64 = 100;
    const election_timeout_ms: u64 = 500;
};

// Compute functions (from your existing library!)
export fn fibonacci(n: u32) u64 {
    if (n <= 1) return n;
    var a: u64 = 0;
    var b: u64 = 1;
    for (0..n - 1) |_| {
        const temp = a + b;
        a = b;
        b = temp;
    }
    return b;
}

export fn is_prime(n: u64) bool {
    if (n < 2) return false;
    if (n == 2) return true;
    if (n % 2 == 0) return false;
    var i: u64 = 3;
    while (i * i <= n) : (i += 2) {
        if (n % i == 0) return false;
    }
    return true;
}

// Compute a range of Fibonacci numbers
export fn compute_fib_range(start: u32, end: u32, results: [*]u64) void {
    var i: u32 = start;
    while (i <= end) : (i += 1) {
        results[i - start] = fibonacci(i);
    }
}

// Count primes in range
export fn count_primes_in_range(start: u64, end: u64) u64 {
    var count: u64 = 0;
    var n: u64 = start;
    while (n <= end) : (n += 1) {
        if (is_prime(n)) count += 1;
    }
    return count;
}

// Message handler (simplified)
fn handleMessage(msg: []const u8) ![]const u8 {
    // Parse JSON, dispatch to appropriate handler
    // For now, just echo
    _ = msg;
    return "ACK";
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    
    try stdout.print("═══════════════════════════════════════\n", .{});
    try stdout.print("  PolyRaft Zig Compute Node\n", .{});
    try stdout.print("  ID: {s}\n", .{config.node_id});
    try stdout.print("  Port: {d}\n", .{config.listen_port});
    try stdout.print("═══════════════════════════════════════\n", .{});
    
    // Quick self-test
    try stdout.print("\nSelf-test:\n", .{});
    try stdout.print("  fibonacci(20) = {d}\n", .{fibonacci(20)});
    try stdout.print("  is_prime(17) = {}\n", .{is_prime(17)});
    try stdout.print("  primes in 1-100 = {d}\n", .{count_primes_in_range(1, 100)});
    
    try stdout.print("\n✓ Zig compute node ready!\n", .{});
    
    // TODO: Start TCP listener for cluster communication
    // For now, this demonstrates the compute capability
}
