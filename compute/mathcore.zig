// mathcore.zig - Extended Compute Kernels
const std = @import("std");

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

export fn factorial(n: u32) u64 {
    if (n <= 1) return 1;
    var result: u64 = 1;
    var i: u32 = 2;
    while (i <= n) : (i += 1) {
        result *= i;
    }
    return result;
}

export fn gcd(a: u64, b: u64) u64 {
    var x = a;
    var y = b;
    while (y != 0) {
        const temp = y;
        y = x % y;
        x = temp;
    }
    return x;
}

export fn sum_array(arr: [*]const f64, len: usize) f64 {
    var total: f64 = 0.0;
    for (0..len) |i| {
        total += arr[i];
    }
    return total;
}

export fn dot_product(a: [*]const f64, b: [*]const f64, len: usize) f64 {
    var sum: f64 = 0.0;
    for (0..len) |i| {
        sum += a[i] * b[i];
    }
    return sum;
}

export fn mean(arr: [*]const f64, len: usize) f64 {
    if (len == 0) return 0.0;
    return sum_array(arr, len) / @as(f64, @floatFromInt(len));
}

export fn hash_djb2(str: [*]const u8, len: usize) u64 {
    var hash: u64 = 5381;
    for (0..len) |i| {
        hash = ((hash << 5) +% hash) +% str[i];
    }
    return hash;
}

export fn hash_fnv1a(data: [*]const u8, len: usize) u64 {
    const FNV_OFFSET: u64 = 14695981039346656037;
    const FNV_PRIME: u64 = 1099511628211;
    var hash: u64 = FNV_OFFSET;
    for (0..len) |i| {
        hash ^= data[i];
        hash *%= FNV_PRIME;
    }
    return hash;
}

export fn quicksort_f64(arr: [*]f64, len: usize) void {
    if (len < 2) return;
    quicksort_partition(arr, 0, len - 1);
}

fn quicksort_partition(arr: [*]f64, low: usize, high: usize) void {
    if (low >= high) return;
    const pivot_idx = partition(arr, low, high);
    if (pivot_idx > 0) {
        quicksort_partition(arr, low, pivot_idx - 1);
    }
    quicksort_partition(arr, pivot_idx + 1, high);
}

fn partition(arr: [*]f64, low: usize, high: usize) usize {
    const pivot = arr[high];
    var i = low;
    for (low..high) |j| {
        if (arr[j] <= pivot) {
            const temp = arr[i];
            arr[i] = arr[j];
            arr[j] = temp;
            i += 1;
        }
    }
    const temp = arr[i];
    arr[i] = arr[high];
    arr[high] = temp;
    return i;
}

export fn benchmark_compute(iterations: u32) u64 {
    var result: u64 = 0;
    var i: u32 = 0;
    while (i < iterations) : (i += 1) {
        result +%= fibonacci(20);
        if (is_prime(result % 10000)) {
            result +%= 1;
        }
    }
    return result;
}
