#!/bin/bash

echo "═══════════════════════════════════════"
echo "  PolyRaft Cloud Status"
echo "═══════════════════════════════════════"
echo ""

PROJECT_ID=$(gcloud config get-value project)
REGION="us-central1"

# Check each service
for service in polyraft-go polyraft-julia polyraft-luajit; do
    echo "Checking $service..."
    URL=$(gcloud run services describe $service --region $REGION --format 'value(status.url)' 2>/dev/null)
    
    if [ ! -z "$URL" ]; then
        echo "  ✅ Deployed: $URL"
        HEALTH=$(curl -s $URL/health 2>/dev/null)
        if [ ! -z "$HEALTH" ]; then
            echo "  ✅ Healthy: $HEALTH"
        else
            echo "  ⚠️  No health response (still starting?)"
        fi
    else
        echo "  ⏳ Not deployed yet"
    fi
    echo ""
done

echo "Recent builds:"
gcloud builds list --limit 3 --format="table(id,status,createTime,logUrl)"
