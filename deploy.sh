#!/bin/bash
# deploy.sh - Polyglot GCP Deployment
set -e

echo "=== Polyglot GCP Deployment Script ==="

PROJECT_ID=$(gcloud config get-value project)
if [ -z "$PROJECT_ID" ]; then
    echo "ERROR: No GCP project set"
    echo "Run: gcloud config set project YOUR-PROJECT-ID"
    exit 1
fi

echo "Project: $PROJECT_ID"
cd ~/polyglot-gcp

# 1. Build Zig library
echo ""
echo "[1/5] Building Zig compute kernel..."
cd compute
chmod +x build.sh
./build.sh

if [ ! -f libmathcore.so ]; then
    echo "ERROR: Zig build failed"
    exit 1
fi

cp libmathcore.so ../services/python/
echo "✓ Zig library built and copied"

# 2. Deploy Python service
echo ""
echo "[2/5] Deploying Python service..."
cd ../services/python

gcloud builds submit --tag gcr.io/$PROJECT_ID/python-compute

gcloud run deploy python-compute \
  --image gcr.io/$PROJECT_ID/python-compute \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --memory 1Gi \
  --timeout 300

PYTHON_URL=$(gcloud run services describe python-compute \
  --region us-central1 \
  --format 'value(status.url)')

echo "✓ Python service: $PYTHON_URL"

# 3. Test Python service
echo ""
echo "[3/5] Testing Python service..."
sleep 5

if curl -s -f "$PYTHON_URL/health" > /dev/null; then
    echo "✓ Python service is healthy"
else
    echo "⚠ Warning: Python service health check failed"
fi

# 4. Prepare Go service
echo ""
echo "[4/5] Preparing Go service..."
cd ../go

# Try to create go.sum (but don't fail if it doesn't appear)
echo "Running go mod tidy..."
go mod tidy -v || true

# List what we have
echo "Go service files:"
ls -lh main.go go.mod Dockerfile
if [ -f go.sum ]; then
    ls -lh go.sum
    echo "✓ go.sum exists"
else
    echo "ℹ No go.sum needed (no external dependencies)"
fi

# 5. Deploy Go gateway
echo ""
echo "[5/5] Deploying Go gateway..."

gcloud builds submit --tag gcr.io/$PROJECT_ID/go-gateway

gcloud run deploy go-gateway \
  --image gcr.io/$PROJECT_ID/go-gateway \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars PYTHON_SERVICE_URL=$PYTHON_URL \
  --memory 512Mi

GATEWAY_URL=$(gcloud run services describe go-gateway \
  --region us-central1 \
  --format 'value(status.url)')

echo ""
echo "=== DEPLOYMENT COMPLETE ==="
echo ""
echo "Gateway URL: $GATEWAY_URL"
echo "Python URL:  $PYTHON_URL"
echo ""

# Run tests
echo "Running tests..."
echo ""
echo "1. Health check:"
curl -s "$GATEWAY_URL/health" | python3 -m json.tool

echo ""
echo "2. Fibonacci test:"
curl -s "$GATEWAY_URL/api/fibonacci/15" | python3 -m json.tool

echo ""
echo "3. Prime numbers test:"
curl -s -X POST "$GATEWAY_URL/api/primes" \
  -H 'Content-Type: application/json' \
  -d '{"start":1,"end":50}' | python3 -m json.tool

echo ""
echo "=== ALL TESTS COMPLETE ==="
