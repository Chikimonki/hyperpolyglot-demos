#!/bin/bash
set -e

echo "═══════════════════════════════════════════════════════"
echo "  HYPERPOLYGLOT FULL STACK DEPLOYMENT"
echo "═══════════════════════════════════════════════════════"

PROJECT_ID=$(gcloud config get-value project)
REGION="us-central1"

if [ -z "$PROJECT_ID" ]; then
    echo "ERROR: No GCP project set"
    exit 1
fi

echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo ""

cd ~/polyglot-gcp

# Build Zig library
echo "[1/5] Building Zig compute library..."
cd compute
./build.sh
cp libmathcore.so ../services/python/
cp libmathcore.so ../services/julia/
cp libmathcore.so ../services/luajit/
echo "✓ Zig library built and distributed"

# Deploy Python
echo ""
echo "[2/5] Deploying Python service..."
cd ../services/python
gcloud builds submit --tag gcr.io/$PROJECT_ID/python-compute
gcloud run deploy python-compute \
  --image gcr.io/$PROJECT_ID/python-compute \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --memory 1Gi \
  --port 8080

PYTHON_URL=$(gcloud run services describe python-compute \
  --region $REGION --format 'value(status.url)')
echo "✓ Python: $PYTHON_URL"

# Deploy Julia
echo ""
echo "[3/5] Deploying Julia service..."
cd ../julia
gcloud builds submit --tag gcr.io/$PROJECT_ID/julia-analytics
gcloud run deploy julia-analytics \
  --image gcr.io/$PROJECT_ID/julia-analytics \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --memory 2Gi \
  --timeout 300 \
  --port 8080

JULIA_URL=$(gcloud run services describe julia-analytics \
  --region $REGION --format 'value(status.url)')
echo "✓ Julia: $JULIA_URL"

# Deploy LuaJIT
echo ""
echo "[4/5] Deploying LuaJIT service..."
cd ../luajit
gcloud builds submit --tag gcr.io/$PROJECT_ID/luajit-scripting
gcloud run deploy luajit-scripting \
  --image gcr.io/$PROJECT_ID/luajit-scripting \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --memory 512Mi \
  --port 8080

LUA_URL=$(gcloud run services describe luajit-scripting \
  --region $REGION --format 'value(status.url)')
echo "✓ LuaJIT: $LUA_URL"

# Deploy Go Gateway
echo ""
echo "[5/5] Deploying Go gateway..."
cd ../go
touch go.sum
gcloud builds submit --tag gcr.io/$PROJECT_ID/go-gateway
gcloud run deploy go-gateway \
  --image gcr.io/$PROJECT_ID/go-gateway \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --set-env-vars PYTHON_SERVICE_URL=$PYTHON_URL,JULIA_SERVICE_URL=$JULIA_URL,LUA_SERVICE_URL=$LUA_URL \
  --memory 512Mi \
  --port 8080

GATEWAY_URL=$(gcloud run services describe go-gateway \
  --region $REGION --format 'value(status.url)')

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  DEPLOYMENT COMPLETE!"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Gateway:  $GATEWAY_URL"
echo "Python:   $PYTHON_URL"
echo "Julia:    $JULIA_URL"
echo "LuaJIT:   $LUA_URL"
echo ""
echo "Test commands:"
echo "  curl $GATEWAY_URL/health"
echo "  curl $GATEWAY_URL/api/fibonacci/25"
echo "  curl -X POST $GATEWAY_URL/julia/api/stats -H 'Content-Type: application/json' -d '{\"data\":[1,2,3,4,5]}'"
echo "  curl $GATEWAY_URL/lua/benchmark"
echo ""
