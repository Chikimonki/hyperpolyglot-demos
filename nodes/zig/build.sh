#!/bin/bash
echo "Building Zig compute node..."
zig build-exe compute_node.zig -O ReleaseFast -o compute_node
echo "✓ Built: compute_node"

echo "Building shared library..."
zig build-lib compute_node.zig -dynamic -O ReleaseFast
echo "✓ Built: libcompute_node.so"

echo "Building shared library..."
zig build-lib compute_node.zig -dynamic -O ReleaseFast
echo "✓ Built: libcompute_node.so"
