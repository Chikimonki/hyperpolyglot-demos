#!/bin/bash

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║               🚀 POLYRAFT CLUSTER LAUNCHER                    ║"
echo "║        Distributed Polyglot Consensus System                   ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Build Zig node
echo -e "${BLUE}[1/5]${NC} Building Zig compute node..."
cd nodes/zig
chmod +x build.sh
./build.sh 2>/dev/null || echo "Zig build skipped (install Zig to enable)"
cd ../..

# Install Julia dependencies
echo -e "${BLUE}[2/5]${NC} Checking Julia dependencies..."
cd nodes/julia
julia -e 'using Pkg; Pkg.activate("."); Pkg.instantiate()' 2>/dev/null || echo "Julia deps skipped"
cd ../..

echo -e "${BLUE}[3/5]${NC} Starting Go Coordinator on port 5000..."
cd nodes/go
go run coordinator.go &
GO_PID=$!
cd ../..
sleep 2

echo -e "${BLUE}[4/5]${NC} Starting Julia Aggregator on port 5002..."
cd nodes/julia
julia --project=. aggregator.jl &
JULIA_PID=$!
cd ../..
sleep 2

echo -e "${BLUE}[5/5]${NC} Starting LuaJIT Consensus on port 5003..."
cd nodes/luajit
luajit consensus.lua &
LUA_PID=$!
cd ../..
sleep 2

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ POLYRAFT CLUSTER STARTED!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "  Running nodes:"
echo "    • Go Coordinator:    http://localhost:5000 (PID: $GO_PID)"
echo "    • Julia Aggregator:  http://localhost:5002 (PID: $JULIA_PID)"
echo "    • LuaJIT Consensus:  http://localhost:5003 (PID: $LUA_PID)"
echo ""
echo "  Test endpoints:"
echo "    curl http://localhost:5000/health"
echo "    curl http://localhost:5000/status"
echo "    curl http://localhost:5002/health"
echo "    curl http://localhost:5003/health"
echo ""
echo "  Start monitor:"
echo "    python3 dashboard/monitor.py"
echo ""
echo "  Stop cluster:"
echo "    kill $GO_PID $JULIA_PID $LUA_PID"
echo ""

# Wait for processes
wait

echo "✅ Run script created!"
