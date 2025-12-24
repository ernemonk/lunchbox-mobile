#!/bin/bash
# Quick deploy for barcode function

cd /Users/user/Projects/lunchbox/backend/functions

# Create temporary deploy directory
DEPLOY_DIR=$(mktemp -d)
cp main.py "$DEPLOY_DIR/"
cp requirements.txt "$DEPLOY_DIR/"
mkdir -p "$DEPLOY_DIR/shared"
cp ../shared/*.py "$DEPLOY_DIR/shared/"
cp ../shared/requirements.txt "$DEPLOY_DIR/shared/requirements.txt"

echo "🚀 Deploying barcode-enrichment..."

gcloud functions deploy barcode-enrichment \
  --runtime python311 \
  --trigger-http \
  --allow-unauthenticated \
  --region us-central1 \
  --memory 512MB \
  --timeout 60s \
  --entry-point barcode_enrichment \
  --source "$DEPLOY_DIR"

if [ $? -eq 0 ]; then
    echo "✅ Barcode enrichment deployed!"
    gcloud functions describe barcode-enrichment --region us-central1 --format="value(serviceConfig.uri)"
else
    echo "❌ Deployment failed"
fi

rm -rf "$DEPLOY_DIR"
