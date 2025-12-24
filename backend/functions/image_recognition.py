"""
Google Cloud Function: Image Recognition for Food Detection
Premium feature using Google Cloud Vision API
"""

import functions_framework
import base64
import json
from google.cloud import vision
import os

# Initialize Vision API client
vision_client = vision.ImageAnnotatorClient()

@functions_framework.http
def image_recognition(request):
    """
    Recognize food items in an image using Google Cloud Vision API
    
    Request body:
    {
        "image": "base64_encoded_image_string"
    }
    
    Response:
    {
        "success": true,
        "foods": [
            {"name": "banana", "confidence": "95.2"},
            {"name": "apple", "confidence": "89.1"}
        ]
    }
    """
    
    # CORS headers
    if request.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '3600'
        }
        return ('', 204, headers)
    
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
    }
    
    try:
        # Parse request
        request_json = request.get_json(silent=True)
        
        if not request_json or 'image' not in request_json:
            return (
                json.dumps({'success': False, 'error': 'No image provided'}),
                400,
                headers
            )
        
        # Decode base64 image
        image_base64 = request_json['image']
        image_bytes = base64.b64decode(image_base64)
        
        # Create Vision API image object
        image = vision.Image(content=image_bytes)
        
        # Perform label detection (identifies objects)
        label_response = vision_client.label_detection(image=image)
        labels = label_response.label_annotations
        
        # Perform object localization (finds food items)
        object_response = vision_client.object_localization(image=image)
        objects = object_response.localized_object_annotations
        
        # Combine results
        detected_foods = []
        food_keywords = {
            'food', 'fruit', 'vegetable', 'meat', 'dairy', 'bread', 'grain',
            'snack', 'dessert', 'beverage', 'drink', 'meal', 'dish', 'cuisine'
        }
        
        # Process label detections
        for label in labels:
            label_lower = label.description.lower()
            confidence = label.score * 100
            
            # Check if it's food-related or a specific food item
            if any(keyword in label_lower for keyword in food_keywords) or confidence > 70:
                detected_foods.append({
                    'name': label.description,
                    'confidence': f'{confidence:.1f}',
                    'type': 'label'
                })
        
        # Process object localizations (more specific)
        for obj in objects:
            obj_lower = obj.name.lower()
            confidence = obj.score * 100
            
            if any(keyword in obj_lower for keyword in food_keywords) or confidence > 60:
                detected_foods.append({
                    'name': obj.name,
                    'confidence': f'{confidence:.1f}',
                    'type': 'object'
                })
        
        # Remove duplicates and sort by confidence
        seen = set()
        unique_foods = []
        
        for food in sorted(detected_foods, key=lambda x: float(x['confidence']), reverse=True):
            name_lower = food['name'].lower()
            if name_lower not in seen:
                seen.add(name_lower)
                unique_foods.append(food)
        
        # Limit to top 10
        unique_foods = unique_foods[:10]
        
        return (
            json.dumps({
                'success': True,
                'foods': unique_foods,
                'count': len(unique_foods)
            }),
            200,
            headers
        )
        
    except Exception as e:
        print(f'Error: {str(e)}')
        return (
            json.dumps({
                'success': False,
                'error': str(e)
            }),
            500,
            headers
        )
