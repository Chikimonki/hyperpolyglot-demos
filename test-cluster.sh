#!/bin/bash

echo "Starting Go coordinator..."
cd nodes/go
go run coordinator.go &
GO_PID=$!
sleep 3

echo "Starting Julia aggregator..."
cd ../julia
julia --project=. aggregator.jl &
JULIA_PID=$!
sleep 3

echo "Starting LuaJIT consensus..."
cd ../luajit
luajit consensus.lua &
LUA_PID=$!
sleep 3

cd ../..

echo ""
echo "All services started!"
echo "Go:     PID $GO_PID"
echo "Julia:  PID $JULIA_PID"
echo "LuaJIT: PID $LUA_PID"
echo ""
echo "Testing..."
sleep 2

curl -s http://localhost:5000/health | python3 -m json.tool
curl -s http://localhost:5002/health | python3 -m json.tool
curl -s http://localhost:5003/health | python3 -m json.tool

echo ""
echo "Cluster status:"
curl -s http://localhost:5000/status | python3 -m json.tool

echo ""
echo "Press Ctrl+C to stop all services"

# Wait for Ctrl+C
trap "kill $GO_PID $JULIA_PID $LUA_PID; exit" INT
wait
