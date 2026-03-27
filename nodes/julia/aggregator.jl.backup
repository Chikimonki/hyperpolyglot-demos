# PolyRaft Julia Aggregator
# Aggregates results from compute nodes and provides analytics

using HTTP
using JSON3
using Statistics
using Dates

# Configuration
const CONFIG = (
    node_id = "julia_aggregator",
    port = 5002,
    coordinator_url = "http://localhost:5000"
)

# Aggregation state
mutable struct AggregatorState
    results::Dict{String, Vector{Float64}}
    timestamps::Dict{String, DateTime}
    task_count::Int
end

const state = AggregatorState(
    Dict{String, Vector{Float64}}(),
    Dict{String, DateTime}(),
    0
)

# Aggregate results from multiple nodes
function aggregate_results(task_id::String, node_results::Vector{Vector{Float64}})
    # Combine all results
    all_values = vcat(node_results...)
    
    # Compute statistics
    stats = Dict(
        "task_id" => task_id,
        "node_count" => length(node_results),
        "total_values" => length(all_values),
        "sum" => sum(all_values),
        "mean" => mean(all_values),
        "median" => median(all_values),
        "std" => std(all_values),
        "min" => minimum(all_values),
        "max" => maximum(all_values),
        "computed_at" => string(now())
    )
    
    return stats
end

# Register with coordinator
function register_with_coordinator()
    try
        response = HTTP.post(
            "$(CONFIG.coordinator_url)/register",
            ["Content-Type" => "application/json"],
            JSON3.write(Dict(
                "id" => CONFIG.node_id,
                "address" => "localhost:$(CONFIG.port)"
            ))
        )
        println("✓ Registered with coordinator")
        return true
    catch e
        println("⚠ Could not register: $e")
        return false
    end
end

# Send heartbeat
function send_heartbeat()
    try
        HTTP.post(
            "$(CONFIG.coordinator_url)/heartbeat",
            ["Content-Type" => "application/json"],
            JSON3.write(Dict("id" => CONFIG.node_id))
        )
    catch e
        # Silent fail for heartbeat
    end
end

# HTTP Router
const ROUTER = HTTP.Router()

HTTP.register!(ROUTER, "GET", "/health", req -> begin
    HTTP.Response(200, ["Access-Control-Allow-Origin" => "*"],
        JSON3.write(Dict(
            "service" => "polyraft-aggregator",
            "status" => "healthy",
            "task_count" => state.task_count
        ))
    )
end)

HTTP.register!(ROUTER, "POST", "/aggregate", req -> begin
    try
        body = JSON3.read(req.body)
        task_id = get(body, :task_id, "unknown")
        node_results = [Float64.(r) for r in body[:results]]
        
        stats = aggregate_results(task_id, node_results)
        state.task_count += 1
        
        HTTP.Response(200, ["Access-Control-Allow-Origin" => "*"],
            JSON3.write(stats)
        )
    catch e
        HTTP.Response(400, JSON3.write(Dict("error" => string(e))))
    end
end)

HTTP.register!(ROUTER, "GET", "/stats", req -> begin
    HTTP.Response(200, ["Access-Control-Allow-Origin" => "*"],
        JSON3.write(Dict(
            "tasks_processed" => state.task_count,
            "active_results" => length(state.results)
        ))
    )
end)

function main()
    println("═══════════════════════════════════════")
    println("  PolyRaft Julia Aggregator")
    println("  Port: $(CONFIG.port)")
    println("═══════════════════════════════════════")
    
    # Register with coordinator
    register_with_coordinator()
    
    # Start heartbeat task
    @async while true
        send_heartbeat()
        sleep(2)
    end
    
    println("\n✓ Julia aggregator ready!")
    println("  Endpoints:")
    println("    GET  /health    - Health check")
    println("    POST /aggregate - Aggregate results")
    println("    GET  /stats     - Aggregation stats")
    
    HTTP.serve(ROUTER, "0.0.0.0", CONFIG.port)
end

# Run
main()


