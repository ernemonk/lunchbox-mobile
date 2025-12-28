# Cloud Vision Dynamic Configuration

## Overview
The Cloud Vision API food detection now supports **dynamic configuration** through Firestore. You can update detection settings without redeploying the Cloud Function.

## Firestore Configuration

### Location
```
Collection: config
Document: image_recognition
```

### Configuration Fields

```json
{
  "food_keywords": [
    "food", "fruit", "vegetable", "meat", "dairy", "bread",
    "milk", "cheese", "butter", "yogurt", "egg", "cream",
    "apple", "banana", "orange", "grape", "berry",
    "lettuce", "tomato", "carrot", "onion", "garlic",
    "chicken", "beef", "pork", "fish", "salmon",
    "juice", "soda", "water", "ketchup", "mustard",
    ... (40+ keywords)
  ],
  "non_food_labels": [
    "pink", "purple", "blue", "red", "green", "yellow",
    "sphere", "circle", "rectangle", "square",
    "plastic", "glass", "metal", "wood", "paper",
    ... (20+ filters)
  ],
  "max_results": 15,
  "label_confidence_threshold": 85,
  "object_confidence_threshold": 70,
  "updated_at": "TIMESTAMP"
}
```

## How to Update Configuration

### Option 1: Firebase Console (Recommended)
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **lunchbox-gen**
3. Navigate to Firestore Database
4. Find collection: `config`
5. Edit document: `image_recognition`
6. Update any field and save
7. Changes take effect **immediately** (no redeploy!)

### Option 2: Using Python Script
```bash
cd backend/functions
python3 init_firestore_config.py
```
⚠️ Requires proper Firestore write permissions

### Option 3: Manually Create in Firestore
1. Create collection: `config`
2. Create document: `image_recognition`
3. Add fields from the JSON schema above

## Configuration Parameters

### `food_keywords` (Array of Strings)
- List of keywords that identify food items
- Items matching these keywords are included in results
- Add specific items your users commonly scan (e.g., "tofu", "soy milk")
- Case-insensitive matching

### `non_food_labels` (Array of Strings)  
- List of generic labels to filter out
- Prevents colors, shapes, materials from being detected as food
- Add problematic labels you notice in results (e.g., "container", "packaging")

### `max_results` (Number)
- Maximum number of food items to return
- Default: 15 (suitable for fridge photos)
- Increase for pantry scans, decrease for single item focus

### `label_confidence_threshold` (Number, 0-100)
- Minimum confidence % for label detections
- Default: 85
- Higher = fewer but more accurate results
- Lower = more results but may include false positives

### `object_confidence_threshold` (Number, 0-100)
- Minimum confidence % for object localizations
- Default: 70
- Object detections are typically more specific than labels
- Can be lower than label threshold

## Fallback Behavior
If Firestore config is unavailable:
- ✅ Cloud Function uses **hardcoded defaults**
- ✅ API continues to work normally
- ⚠️ Logs warning: "Using default config (Firestore unavailable)"

## Example Use Cases

### Improve Detection for Asian Foods
Add keywords:
```json
"food_keywords": [
  ...,
  "rice", "noodles", "tofu", "seaweed", "miso", 
  "kimchi", "soy sauce", "fish sauce", "ramen"
]
```

### Filter Out Packaging Labels
Add filters:
```json
"non_food_labels": [
  ...,
  "package", "container", "wrapper", "box", "bag"
]
```

### Get More Results for Pantry Scans
```json
"max_results": 25
```

### Stricter Detection (Fewer False Positives)
```json
"label_confidence_threshold": 90,
"object_confidence_threshold": 80
```

## Deployment Status
✅ Cloud Function deployed with Firestore integration
✅ Dynamic configuration ready
⚠️ Firestore document needs to be created (see setup instructions above)

## Testing
After updating config:
1. Take a test fridge photo in the app
2. Check Cloud Function logs for: `📋 Loaded config from Firestore`
3. Verify detection results match your expectations
4. Adjust thresholds if needed
