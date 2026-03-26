#!/bin/bash
set -e

echo "════════════════════════════════════════════════════════"
echo "  HYPERPOLYGLOT MEGA UPGRADE - PART 1: Code Files"
echo "════════════════════════════════════════════════════════"

cd ~/polyglot-gcp

# ============================================
# Extended Zig Compute Kernels
# ============================================

echo "[1/6] Creating extended Zig compute kernels..."

cat > compute/mathcore.zig << 'ZIGCODE'
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
ZIGCODE

echo "✓ Extended Zig kernels created"

# ============================================
# LuaJIT Service
# ============================================

echo "[2/6] Creating LuaJIT scripting service..."

mkdir -p services/luajit

cat > services/luajit/bridge.lua << 'LUABRIDGE'
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
LUABRIDGE

cat > services/luajit/server.lua << 'LUASERVER'
local socket = require("socket")
local bridge = require("bridge")

local function json_encode(tbl)
    local items = {}
    for k, v in pairs(tbl) do
        local val = type(v) == "string" and '"'..v..'"' or tostring(v)
        table.insert(items, '"'..k..'":'..val)
    end
    return "{"..table.concat(items, ",").."}"
end

local server = socket.bind("*", 8082)
server:settimeout(0.1)
print("LuaJIT Service listening on port 8082")

while true do
    local client = server:accept()
    if client then
        client:settimeout(10)
        local request = client:receive()
        if request then
            local response_data = {status="ok", service="luajit"}
            if request:match("GET /health") then
                response_data.healthy = true
            elseif request:match("GET /benchmark") then
                response_data = bridge.benchmark(10000)
                response_data.service = "luajit"
            end
            local json = json_encode(response_data)
            local response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: "..#json.."\r\n\r\n"..json
            client:send(response)
        end
        client:close()
    end
end
LUASERVER

cat > services/luajit/Dockerfile << 'LUADOCKER'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y luajit libluajit-5.1-dev luarocks && rm -rf /var/lib/apt/lists/*
RUN luarocks install luasocket
WORKDIR /app
COPY libmathcore.so ./
COPY bridge.lua ./
COPY server.lua ./
EXPOSE 8082
CMD ["luajit", "server.lua"]
LUADOCKER

echo "✓ LuaJIT service created"

# ============================================
# Julia Service  
# ============================================

echo "[3/6] Creating Julia analytics service..."

mkdir -p services/julia

cat > services/julia/Project.toml << 'JULIAPROJECT'
name = "PolyglotAnalytics"
version = "0.1.0"

[deps]
HTTP = "cd3eb016-35fb-5094-929b-558a96fad6f3"
JSON3 = "0f8b85d8-7281-11e9-16c2-39a750bddbf1"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
JULIAPROJECT

cat > services/julia/main.jl << 'JULIACODE'
using HTTP, JSON3, Statistics

const ziglib = "./libmathcore.so"
fibonacci_zig(n::Int) = ccall((:fibonacci, ziglib), UInt64, (UInt32,), n)
is_prime_zig(n::Int) = ccall((:is_prime, ziglib), Bool, (UInt64,), n)

function analyze_distribution(data::Vector{Float64})
    Dict("mean" => mean(data), "median" => median(data), "std" => std(data))
end

const ROUTER = HTTP.Router()

HTTP.register!(ROUTER, "GET", "/health", req -> 
    HTTP.Response(200, JSON3.write(Dict("status" => "healthy", "service" => "julia"))))

HTTP.register!(ROUTER, "POST", "/api/stats", req -> begin
    body = JSON3.read(req.body)
    result = analyze_distribution(Float64.(body[:data]))
    HTTP.Response(200, JSON3.write(result))
end)

println("Julia Analytics on port 8083...")
HTTP.serve(ROUTER, "0.0.0.0", 8083)
JULIACODE

cat > services/julia/Dockerfile << 'JULIADOCKER'
FROM julia:1.9
WORKDIR /app
COPY Project.toml ./
RUN julia -e 'using Pkg; Pkg.activate("."); Pkg.instantiate()'
COPY libmathcore.so ./
COPY main.jl ./
EXPOSE 8083
CMD ["julia", "--project=.", "main.jl"]
JULIADOCKER

echo "✓ Julia service created"

# ============================================
# Update Python
# ============================================

echo "[4/6] Updating Python service..."

cat > services/python/main.py << 'PYTHONCODE'
from flask import Flask, jsonify, request
import ctypes, os

app = Flask(__name__)
lib = ctypes.CDLL(os.path.join(os.path.dirname(__file__), 'libmathcore.so'))

lib.fibonacci.argtypes = [ctypes.c_uint32]
lib.fibonacci.restype = ctypes.c_uint64
lib.is_prime.argtypes = [ctypes.c_uint64]
lib.is_prime.restype = ctypes.c_bool
lib.factorial.argtypes = [ctypes.c_uint32]
lib.factorial.restype = ctypes.c_uint64
lib.hash_djb2.argtypes = [ctypes.c_char_p, ctypes.c_size_t]
lib.hash_djb2.restype = ctypes.c_uint64

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "python"})

@app.route('/api/fibonacci/<int:n>')
def fibonacci(n):
    if n > 90: return jsonify({"error": "too large"}), 400
    return jsonify({"n": n, "result": int(lib.fibonacci(n))})

@app.route('/api/factorial/<int:n>')
def factorial(n):
    if n > 20: return jsonify({"error": "too large"}), 400
    return jsonify({"n": n, "result": int(lib.factorial(n))})

@app.route('/api/hash', methods=['POST'])
def hash_text():
    text = request.json.get('text', '')
    return jsonify({"hash": int(lib.hash_djb2(text.encode(), len(text)))})

@app.route('/api/primes', methods=['POST'])
def primes():
    data = request.json
    start, end = data.get('start', 1), data.get('end', 100)
    result = [n for n in range(start, end+1) if lib.is_prime(n)]
    return jsonify({"count": len(result), "primes": result[:100]})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
PYTHONCODE

echo "✓ Python updated"

# ============================================
# Update Go Gateway
# ============================================

echo "[5/6] Updating Go gateway..."

cat > services/go/main.go << 'GOCODE'
package main
import ("encoding/json"; "io"; "log"; "net/http"; "os")

var pythonURL = os.Getenv("PYTHON_SERVICE_URL")
var juliaURL = os.Getenv("JULIA_SERVICE_URL")
var luaURL = os.Getenv("LUA_SERVICE_URL")

func proxy(target string) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        req, _ := http.NewRequest(r.Method, target+r.URL.Path, r.Body)
        req.Header = r.Header
        resp, err := http.DefaultClient.Do(req)
        if err != nil { http.Error(w, err.Error(), 502); return }
        defer resp.Body.Close()
        w.WriteHeader(resp.StatusCode)
        io.Copy(w, resp.Body)
    }
}

func main() {
    http.HandleFunc("/api/", proxy(pythonURL))
    http.HandleFunc("/julia/", proxy(juliaURL))
    http.HandleFunc("/lua/", proxy(luaURL))
    http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
        json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
    })
    log.Fatal(http.ListenAndServe(":8000", nil))
}
GOCODE

echo "✓ Go gateway updated"

# ============================================
# Deployment Script
# ============================================

echo "[6/6] Creating deployment script..."

cat > deploy-full.sh << 'DEPLOYSCRIPT'
#!/bin/bash
set -e
PROJECT_ID=$(gcloud config get-value project)
REGION="us-central1"

cd ~/polyglot-gcp/compute
./build.sh
cp libmathcore.so ../services/python/
cp libmathcore.so ../services/julia/
cp libmathcore.so ../services/luajit/

cd ../services/python
gcloud builds submit --tag gcr.io/$PROJECT_ID/python-compute
gcloud run deploy python-compute --image gcr.io/$PROJECT_ID/python-compute --region $REGION --allow-unauthenticated --memory 1Gi
PYTHON_URL=$(gcloud run services describe python-compute --region $REGION --format 'value(status.url)')

cd ../julia
gcloud builds submit --tag gcr.io/$PROJECT_ID/julia-analytics
gcloud run deploy julia-analytics --image gcr.io/$PROJECT_ID/julia-analytics --region $REGION --allow-unauthenticated --memory 2Gi
JULIA_URL=$(gcloud run services describe julia-analytics --region $REGION --format 'value(status.url)')

cd ../luajit
gcloud builds submit --tag gcr.io/$PROJECT_ID/luajit-scripting
gcloud run deploy luajit-scripting --image gcr.io/$PROJECT_ID/luajit-scripting --region $REGION --allow-unauthenticated --memory 512Mi
LUA_URL=$(gcloud run services describe luajit-scripting --region $REGION --format 'value(status.url)')

cd ../go
gcloud builds submit --tag gcr.io/$PROJECT_ID/go-gateway
gcloud run deploy go-gateway --image gcr.io/$PROJECT_ID/go-gateway --region $REGION --allow-unauthenticated \
  --set-env-vars PYTHON_SERVICE_URL=$PYTHON_URL,JULIA_SERVICE_URL=$JULIA_URL,LUA_SERVICE_URL=$LUA_URL

echo "Deployment complete!"
gcloud run services describe go-gateway --region $REGION --format 'value(status.url)'
DEPLOYSCRIPT

chmod +x deploy-full.sh

echo ""
echo "✅ Part 1 Complete! All code files created."
echo "Now create README manually with: micro README.md"
