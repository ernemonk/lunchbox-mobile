#!/bin/bash
# Test Cloud Vision API locally

export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/vision-key.json"

echo "🚀 Starting Cloud Vision API test server..."
echo "📍 Running at: http://localhost:8081"
echo ""
echo "Test with:"
echo '  curl -X POST http://localhost:8081 -H "Content-Type: application/json" -d '"'"'{"image":"BASE64_IMAGE_HERE"}'"'"''
echo ""
echo "Press Ctrl+C to stop"
echo ""

functions-framework --target=image_recognition --source=image_recognition.py --port=8081
