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
port = parse(Int, get(ENV, "PORT", "8083"))
println("Julia Analytics starting on port $port...")
HTTP.serve(ROUTER, "0.0.0.0", port)
