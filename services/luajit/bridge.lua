local ffi = require("ffi")
local lib = ffi.load("./libmathcore.so")

ffi.cdef[[
    uint64_t fibonacci(uint32_t n);
    bool is_prime(uint64_t n);
    uint64_t factorial(uint32_t n);
    uint64_t hash_djb2(const uint8_t* str, size_t len);
    uint64_t benchmark_compute(uint32_t iterations);
]]

local M = {}

function M.fibonacci(n)
    return tonumber(lib.fibonacci(n))
end

function M.is_prime(n)
    return lib.is_prime(n)
end

function M.factorial(n)
    return tonumber(lib.factorial(n))
end

function M.hash_string(str)
    local len = #str
    local bytes = ffi.cast("const uint8_t*", str)
    return tonumber(lib.hash_djb2(bytes, len))
end

function M.benchmark(iterations)
    iterations = iterations or 1000
    local start = os.clock()
    local result = lib.benchmark_compute(iterations)
    local elapsed = os.clock() - start
    return {
        result = tonumber(result),
        iterations = iterations,
        time_seconds = elapsed,
        ops_per_sec = math.floor(iterations / elapsed)
    }
end

return M
