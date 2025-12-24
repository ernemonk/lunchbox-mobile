#!/bin/bash

# Build and test script for Lunchbox barcode/OCR features
# This script handles native plugin compilation

set -e

PROJECT_DIR="/Users/user/Projects/lunchbox"
cd "$PROJECT_DIR"

echo "═══════════════════════════════════════════════════════"
echo "🚀 Building Lunchbox with Barcode Scanning & OCR"
echo "═══════════════════════════════════════════════════════"
echo ""

# Step 1: Clean
echo "📦 Step 1: Cleaning build artifacts..."
rm -rf build/ .dart_tool/
rm -rf ios/Pods ios/Podfile.lock
rm -rf android/.gradle android/build

# Step 2: Get dependencies
echo "📚 Step 2: Getting dependencies..."
flutter pub get

# Step 3: Generate local modules (if needed)
echo "🔧 Step 3: Generating local modules..."
flutter pub run build_runner build --delete-conflicting-outputs 2>/dev/null || true

# Step 4: Build iOS
echo "📱 Step 4: Building iOS app..."
flutter build ios --no-codesign --verbose

echo ""
echo "═══════════════════════════════════════════════════════"
echo "✅ Build completed successfully!"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Next: Run 'flutter run' to test on device"
