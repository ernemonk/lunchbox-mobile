#!/bin/bash
# Auto-deploy both cloud functions

cd "$(dirname "$0")"

echo "☁️  Deploying Both Cloud Functions"
echo "=========================================="

# Deploy Barcode Enrichment
echo ""
echo "🔖 [1/2] Deploying Barcode Enrichment..."
DEPLOY_DIR=$(mktemp -d)
cp main.py "$DEPLOY_DIR/"
cp requirements.txt "$DEPLOY_DIR/"
mkdir -p "$DEPLOY_DIR/shared"
cp ../shared/__init__.py "$DEPLOY_DIR/shared/"
cp ../shared/*.py "$DEPLOY_DIR/shared/"

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

BARCODE_STATUS=$?
rm -rf "$DEPLOY_DIR"

if [ $BARCODE_STATUS -eq 0 ]; then
    BARCODE_URL=$(gcloud functions describe barcode-enrichment --region us-central1 --format="value(serviceConfig.uri)" 2>/dev/null)
    echo "✅ Barcode: $BARCODE_URL"
else
    echo "❌ Barcode deployment failed"
fi

# Deploy Image Recognition
echo ""
echo "🍎 [2/2] Deploying Image Recognition..."
DEPLOY_DIR=$(mktemp -d)
cat > "$DEPLOY_DIR/main.py" << 'EOFMAIN'
from image_recognition import image_recognition
__all__ = ['image_recognition']
EOFMAIN

cp image_recognition.py "$DEPLOY_DIR/"
cp requirements.txt "$DEPLOY_DIR/"

gcloud functions deploy image-recognition \
  --runtime python311 \
  --trigger-http \
  --allow-unauthenticated \
  --region us-central1 \
  --memory 512MB \
  --timeout 60s \
  --entry-point image_recognition \
  --source "$DEPLOY_DIR" \
  --quiet

IMAGE_STATUS=$?
rm -rf "$DEPLOY_DIR"

if [ $IMAGE_STATUS -eq 0 ]; then
    IMAGE_URL=$(gcloud functions describe image-recognition --region us-central1 --format="value(serviceConfig.uri)" 2>/dev/null)
    echo "✅ Vision: $IMAGE_URL"
else
    echo "❌ Image recognition deployment failed"
fi

echo ""
echo "=========================================="
echo "📡 Deployed URLs:"
echo "Barcode: $BARCODE_URL"
echo "Vision:  $IMAGE_URL"
echo "=========================================="
