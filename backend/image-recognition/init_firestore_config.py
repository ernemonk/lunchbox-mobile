#!/usr/bin/env python3
"""
Initialize Firestore configuration for image recognition
Run this once to set up the dynamic configuration
"""

from google.cloud import firestore

# Initialize Firestore
db = firestore.Client()

# Configuration for food detection
config = {
    'food_keywords': [
        # General food categories
        'food', 'fruit', 'vegetable', 'meat', 'dairy', 'bread', 'grain',
        'snack', 'dessert', 'beverage', 'drink', 'meal', 'dish', 'cuisine',
        'produce', 'protein', 'ingredient', 'condiment', 'sauce',
        
        # Specific common fridge items
        'milk', 'cheese', 'butter', 'yogurt', 'egg', 'cream',
        'apple', 'banana', 'orange', 'grape', 'berry', 'lemon', 'lime',
        'lettuce', 'tomato', 'carrot', 'onion', 'garlic', 'potato',
        'chicken', 'beef', 'pork', 'fish', 'salmon', 'turkey',
        'juice', 'soda', 'water', 'beer', 'wine',
        'ketchup', 'mustard', 'mayo', 'salsa', 'jam', 'jelly',
        'leftovers', 'container', 'jar', 'bottle', 'carton', 'package'
    ],
    'non_food_labels': [
        # Colors
        'pink', 'purple', 'blue', 'red', 'green', 'yellow', 'white', 'black',
        # Shapes
        'sphere', 'circle', 'rectangle', 'square', 'triangle',
        # Materials
        'plastic', 'glass', 'metal', 'wood', 'paper', 'cardboard',
        # Other generic labels
        'light', 'shadow', 'reflection', 'texture', 'pattern'
    ],
    'max_results': 15,
    'label_confidence_threshold': 85,
    'object_confidence_threshold': 70,
    'updated_at': firestore.SERVER_TIMESTAMP
}

# Write to Firestore
db.collection('config').document('image_recognition').set(config)

print('✅ Firestore configuration initialized!')
print(f'   - {len(config["food_keywords"])} food keywords')
print(f'   - {len(config["non_food_labels"])} non-food filters')
print(f'   - Max results: {config["max_results"]}')
print(f'   - Label threshold: {config["label_confidence_threshold"]}%')
print(f'   - Object threshold: {config["object_confidence_threshold"]}%')
print('')
print('💡 To update config in the future:')
print('   1. Edit values in Firestore console: config/image_recognition')
print('   2. Changes take effect immediately (no redeploy needed!)')
