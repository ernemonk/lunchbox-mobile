#!/bin/bash
# Deploy only barcode function

cd "$(dirname "$0")"

echo "🔖 Deploying Barcode Enrichment..."
DEPLOY_DIR=$(mktemp -d)
cp main.py "$DEPLOY_DIR/"
cp requirements.txt "$DEPLOY_DIR/"
mkdir -p "$DEPLOY_DIR/shared"
cp ../shared/__init__.py "$DEPLOY_DIR/shared/"
cp ../shared/*.py "$DEPLOY_DIR/shared/"

echo "📦 Deploy directory contents:"
ls -la "$DEPLOY_DIR"
echo ""
echo "📦 Shared folder contents:"
ls -la "$DEPLOY_DIR/shared"
echo ""

gcloud functions deploy barcode-enrichment \
  --runtime python311 \
  --trigger-http \
  --allow-unauthenticated \
  --region us-central1 \
  --memory 512MB \
  --timeout 60s \
  --entry-point barcode_enrichment \
  --source "$DEPLOY_DIR" \
  --quiet

if [ $? -eq 0 ]; then
    BARCODE_URL=$(gcloud functions describe barcode-enrichment --region us-central1 --format="value(serviceConfig.uri)" 2>/dev/null)
    echo ""
    echo "✅ Barcode deployed: $BARCODE_URL"
else
    echo "❌ Deployment failed"
fi

rm -rf "$DEPLOY_DIR"
