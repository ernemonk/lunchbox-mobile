#!/bin/bash
# Deploy Cloud Functions to Google Cloud

echo "☁️  Deploying Cloud Functions to Google Cloud"
echo "==========================================================="

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ Error: gcloud CLI not found. Please install Google Cloud SDK."
    exit 1
fi

# Check if logged in
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
    echo "❌ Error: Not logged in to gcloud. Run: gcloud auth login"
    exit 1
fi

# Get current project
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ]; then
    echo "❌ Error: No GCP project set. Run: gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi

echo "📋 Project: $PROJECT_ID"
echo ""
echo "Select function to deploy:"
echo "  1) Barcode Enrichment (barcode-enrichment)"
echo "  2) Image Recognition (image-recognition)"
echo "  3) Both"
echo ""
read -p "Enter choice [1-3]: " CHOICE

# Deploy Barcode Enrichment
if [ "$CHOICE" = "1" ] || [ "$CHOICE" = "3" ]; then
    echo ""
    echo "🔖 Deploying Barcode Enrichment Function"
    echo "========================================="
    
    # Prompt for API keys
    echo "🔑 API Keys (press Enter to skip):"
    read -p "Nutritionix App ID: " NUTRITIONIX_APP_ID
    read -p "Nutritionix App Key: " NUTRITIONIX_APP_KEY
    read -p "Edamam App ID: " EDAMAM_APP_ID
    read -p "Edamam App Key: " EDAMAM_APP_KEY
    read -p "UPC Database API Key: " UPC_DATABASE_API_KEY
    read -p "USDA API Key: " USDA_API_KEY
    
    # Build env vars
    ENV_VARS=""
    [ ! -z "$NUTRITIONIX_APP_ID" ] && ENV_VARS="${ENV_VARS}NUTRITIONIX_APP_ID=$NUTRITIONIX_APP_ID,"
    [ ! -z "$NUTRITIONIX_APP_KEY" ] && ENV_VARS="${ENV_VARS}NUTRITIONIX_APP_KEY=$NUTRITIONIX_APP_KEY,"
    [ ! -z "$EDAMAM_APP_ID" ] && ENV_VARS="${ENV_VARS}EDAMAM_APP_ID=$EDAMAM_APP_ID,"
    [ ! -z "$EDAMAM_APP_KEY" ] && ENV_VARS="${ENV_VARS}EDAMAM_APP_KEY=$EDAMAM_APP_KEY,"
    [ ! -z "$UPC_DATABASE_API_KEY" ] && ENV_VARS="${ENV_VARS}UPC_DATABASE_API_KEY=$UPC_DATABASE_API_KEY,"
    [ ! -z "$USDA_API_KEY" ] && ENV_VARS="${ENV_VARS}USDA_API_KEY=$USDA_API_KEY,"
    ENV_VARS=${ENV_VARS%,}
    
    # Create temporary deploy directory
    DEPLOY_DIR=$(mktemp -d)
    cp main.py "$DEPLOY_DIR/"
    cp requirements.txt "$DEPLOY_DIR/"
    mkdir -p "$DEPLOY_DIR/shared"
    cp ../shared/*.py "$DEPLOY_DIR/shared/" 2>/dev/null || true
    cp ../shared/requirements.txt "$DEPLOY_DIR/shared/requirements.txt" 2>/dev/null || true
    
    echo ""
    echo "🚀 Deploying barcode-enrichment..."
    
    DEPLOY_CMD="gcloud functions deploy barcode-enrichment \
      --runtime python311 \
      --trigger-http \
      --allow-unauthenticated \
      --region us-central1 \
      --memory 512MB \
      --timeout 60s \
      --entry-point barcode_enrichment \
      --source $DEPLOY_DIR"
    
    [ ! -z "$ENV_VARS" ] && DEPLOY_CMD="$DEPLOY_CMD --set-env-vars $ENV_VARS"
    
    eval $DEPLOY_CMD
    
    if [ $? -eq 0 ]; then
        echo "✅ Barcode enrichment deployed!"
        BARCODE_URL=$(gcloud functions describe barcode-enrichment --region us-central1 --format="value(httpsTrigger.url)")
        echo "📡 URL: $BARCODE_URL"
    else
        echo "❌ Barcode deployment failed"
    fi
    
    rm -rf "$DEPLOY_DIR"
fi

# Deploy Image Recognition
if [ "$CHOICE" = "2" ] || [ "$CHOICE" = "3" ]; then
    echo ""
    echo "🍎 Deploying Image Recognition Function"
    echo "========================================"
    
    # Check if image_recognition.py exists
    if [ ! -f "image_recognition.py" ]; then
        echo "❌ Error: image_recognition.py not found"
        exit 1
    fi
    
    # Create temporary deploy directory
    DEPLOY_DIR=$(mktemp -d)
    
    # Copy image recognition files
    cat > "$DEPLOY_DIR/main.py" << 'EOF'
# Import from image_recognition module
from image_recognition import image_recognition

# Export for Cloud Functions
__all__ = ['image_recognition']
EOF
    
    cp image_recognition.py "$DEPLOY_DIR/"
    cp requirements.txt "$DEPLOY_DIR/"
    
    echo ""
    echo "🚀 Deploying image-recognition..."
    
    gcloud functions deploy image-recognition \
      --runtime python311 \
      --trigger-http \
      --allow-unauthenticated \
      --region us-central1 \
      --memory 512MB \
      --timeout 60s \
      --entry-point image_recognition \
      --source $DEPLOY_DIR
    
    if [ $? -eq 0 ]; then
        echo "✅ Image recognition deployed!"
        IMAGE_URL=$(gcloud functions describe image-recognition --region us-central1 --format="value(httpsTrigger.url)")
        echo "📡 URL: $IMAGE_URL"
        echo ""
        echo "⚠️  Important: Update this URL in Flutter app:"
        echo "   lib/services/image_recognition_service.dart"
        echo "   Replace 'YOUR_CLOUD_FUNCTION_URL' with: $IMAGE_URL"
    else
        echo "❌ Image recognition deployment failed"
    fi
    
    rm -rf "$DEPLOY_DIR"
fi

echo ""
echo "==========================================================="
echo "✅ Deployment complete!"
echo "==========================================================="
