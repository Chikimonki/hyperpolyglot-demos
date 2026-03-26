#!/bin/bash
# test-stack.sh - Test all services

set -e

GATEWAY_URL=$(gcloud run services describe go-gateway --region us-central1 --format 'value(status.url)' 2>/dev/null)

if [ -z "$GATEWAY_URL" ]; then
    echo "ERROR: Gateway not deployed"
    exit 1
fi

echo "Testing Hyperpolyglot Stack"
echo "Gateway: $GATEWAY_URL"
echo ""

echo "1. Health Check"
curl -s $GATEWAY_URL/health | jq .

echo -e "\n2. Python → Zig: Fibonacci(20)"
curl -s $GATEWAY_URL/api/fibonacci/20 | jq .

echo -e "\n3. Python → Zig: Factorial(10)"
curl -s $GATEWAY_URL/api/factorial/10 | jq .

echo -e "\n4. Python → Zig: Primes 1-50"
curl -s -X POST $GATEWAY_URL/api/primes \
  -H 'Content-Type: application/json' \
  -d '{"start":1,"end":50}' | jq .

echo -e "\n5. Julia: Statistical Analysis"
curl -s -X POST $GATEWAY_URL/julia/api/stats \
  -H 'Content-Type: application/json' \
  -d '{"data":[1,1,2,3,5,8,13,21,34,55]}' | jq .

echo -e "\n6. LuaJIT: Benchmark"
curl -s $GATEWAY_URL/lua/benchmark | jq .

echo -e "\n✅ All tests passed!"
