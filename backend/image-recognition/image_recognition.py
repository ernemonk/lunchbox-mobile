"""
Google Cloud Function: Image Recognition for Food Detection
Premium feature using Google Gemini Flash
"""

import functions_framework
import base64
import json
import google.generativeai as genai
import requests
import logging
import time

# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Configure Gemini API
GEMINI_API_KEY = "AIzaSyDlwRQ1clTVrN2DJeL4ALPjPagP9K2dUW4"
genai.configure(api_key=GEMINI_API_KEY)

# Cache globals
MODEL_CACHE = None
MODEL_CACHE_TIMESTAMP = 0
CACHE_TTL = 3600

def list_models_rest():
    url = "https://generativelanguage.googleapis.com/v1beta/models"
    headers = {"x-goog-api-key": GEMINI_API_KEY}
    logger.debug("Listing models...")
    resp = requests.get(url, headers=headers)
    if resp.status_code != 200:
        logger.error(f"List models failed: {resp.status_code}")
        return []
    return resp.json().get("models", [])

def get_cached_models():
    global MODEL_CACHE, MODEL_CACHE_TIMESTAMP
    now = time.time()
    if MODEL_CACHE is None or (now - MODEL_CACHE_TIMESTAMP) > CACHE_TTL:
        logger.debug("Refreshing model cache...")
        MODEL_CACHE = list_models_rest()
        MODEL_CACHE_TIMESTAMP = now
    return MODEL_CACHE

def choose_best_flash_model(models):
    priority = [
        'gemini-2.0-flash-exp',
        'gemini-2.0-flash',
        'gemini-1.5-flash-latest',
        'gemini-1.5-flash-8b',
        'gemini-1.5-flash',
    ]
    
    for preferred in priority:
        for m in models:
            model_name = m.get('name', '')
            methods = m.get('supportedGenerationMethods', [])
            if preferred in model_name and 'generateContent' in methods:
                result = model_name.replace('models/', '')
                logger.info(f"Selected model: {result}")
                return result
    
    return 'gemini-1.5-flash-latest'

@functions_framework.http
def image_recognition(request):
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
        request_json = request.get_json(silent=True)
        
        if not request_json or 'image' not in request_json:
            return (
                json.dumps({'success': False, 'error': 'No image provided'}),
                400,
                headers
            )
        
        image_base64 = request_json['image']
        image_bytes = base64.b64decode(image_base64)
        
        # Get mode: 'food' (default) or 'receipt'
        mode = request_json.get('mode', 'food')
        
        logger.info(f'Using Gemini Flash for {mode} detection')
        
        models = get_cached_models()
        model_name = choose_best_flash_model(models)
        model = genai.GenerativeModel(model_name)
        
        # Different prompts based on mode
        if mode == 'receipt':
            prompt = """
You are Lunchbox's inventory intelligence layer. Your mission: transform receipt text into actionable ingredient data with ZERO hallucination tolerance.

ANALYZE this receipt/grocery list image and extract ONLY food items that are actually visible on the receipt.

For each food item, provide:
1. **Exact item name** (from receipt text, preserve brands and specificity)
2. **Quantity** (from receipt, default to 1 if not specified)
3. **Category** (strict: Fruits, Vegetables, Dairy, Meat & Protein, Beverages, Condiments, Bread & Grains, Other)
4. **Price** (from receipt if visible, otherwise omit)
5. **Expiry date** (ONLY if clearly printed on visible product packaging)

CRITICAL CONSTRAINTS:
✓ Extract EXACT text from receipt - do NOT invent or beautify names
✓ SKIP all non-food items (cleaning supplies, toiletries, household goods, medications)
✓ If quantity is listed (e.g., "2x" or "Qty: 3"), use that number
✓ Do NOT guess or infer - if you can't read it, skip it
✓ Return empty array [] if no food items are clearly visible
✓ Preserve brand names when present (e.g., "Kirkland Organic Milk" not "Milk")
✓ Use original receipt spelling/capitalization

CATEGORIZATION GUIDE:
- Fruits: fresh fruits, dried fruits, fruit products
- Vegetables: fresh vegetables, frozen vegetables, canned vegetables
- Dairy: milk, cheese, yogurt, butter, cream, eggs
- Meat & Protein: meat, poultry, fish, seafood, tofu, beans, legumes
- Beverages: juices, sodas, coffee, tea, water, milk alternatives
- Condiments: sauces, dressings, oils, spices, seasonings, spreads
- Bread & Grains: bread, pasta, rice, cereal, grains, tortillas
- Other: anything edible that doesn't fit above

Return ONLY valid JSON array:
[
  {"name": "Organic Whole Milk", "quantity": 2, "category": "Dairy", "price": "5.99", "expiryDate": "Jan 5 2026"},
  {"name": "Bananas", "quantity": 5, "category": "Fruits", "price": "2.49"}
]

Remember: This data powers meal decisions. Accuracy is NOT optional. When in doubt, exclude it.
"""
        else:  # food mode (default)
            prompt = """
You are Lunchbox's visual inventory engine. Your mission: identify what's in this fridge/pantry with maximum specificity to enable intelligent meal decisions.

ANALYZE this photo and identify ALL visible food items.

For each item, provide:
1. **Specific name** (brand + type when visible: "Tropicana Orange Juice" NOT "juice"; "Gala Apple" NOT "apple")
2. **Quantity** (count individual units you can see)
3. **Category** (strict: Fruits, Vegetables, Dairy, Meat & Protein, Beverages, Condiments, Bread & Grains, Other)
4. **Expiry date** (ONLY if clearly visible on packaging - format: "MMM DD YYYY")

CRITICAL REQUIREMENTS:
✓ MAXIMUM SPECIFICITY: "Kerrygold Salted Butter" > "Butter" > "Dairy"
✓ BRAND RECOGNITION: Include brand when label is visible (helps users identify exact items)
✓ COUNT ACCURATELY: 3 identical apples = quantity 3, not 3 separate entries
✓ MERGE INTELLIGENTLY: "2 Honeycrisp Apples + 1 Gala Apple" = TWO entries (different varieties)
✓ NO HALLUCINATION: If you can't clearly see it, don't list it
✓ EDIBILITY ONLY: Skip packaging, decorations, non-food items
✓ EXPIRY DATES: Only include if you can READ the date on the label

CATEGORIZATION GUIDE:
- Fruits: fresh fruits, dried fruits, fruit products
- Vegetables: fresh vegetables, frozen vegetables, leafy greens
- Dairy: milk, cheese, yogurt, butter, cream, eggs, ice cream
- Meat & Protein: meat, poultry, fish, seafood, tofu, tempeh, beans, nuts
- Beverages: juices, sodas, coffee, tea, milk alternatives, alcohol, water
- Condiments: sauces, dressings, oils, vinegars, spices, spreads, jams
- Bread & Grains: bread, pasta, rice, cereal, oats, tortillas, crackers
- Other: prepared foods, snacks, baking ingredients, anything else edible

CONTEXT: This data feeds Lunchbox's AI decision engine. Users with allergies depend on accuracy. Busy families rely on specificity for meal planning.

Return ONLY valid JSON array:
[
  {"name": "Tropicana Pure Premium Orange Juice", "quantity": 1, "category": "Beverages", "expiryDate": "Dec 28 2025"},
  {"name": "Honeycrisp Apple", "quantity": 3, "category": "Fruits"},
  {"name": "Kerrygold Salted Butter", "quantity": 1, "category": "Dairy"}
]

Remember: You are the first layer of intelligence in a constraint-first AI system. Precision empowers users. Vagueness paralyzes them.
"""
        
        response = model.generate_content([
            prompt,
            {'mime_type': 'image/jpeg', 'data': image_bytes}
        ])
        
        response_text = response.text.strip()
        logger.info(f'Gemini response preview: {response_text[:200]}')
        
        if response_text.startswith('```'):
            response_text = response_text.split('```')[1]
            if response_text.startswith('json'):
                response_text = response_text[4:]
        response_text = response_text.strip()
        
        detected_items = json.loads(response_text)
        expiry_dates = [item.get('expiryDate') for item in detected_items if item.get('expiryDate')]
        
        all_detections = []
        for item in detected_items:
            all_detections.append({
                'name': item.get('name', 'Unknown'),
                'quantity': str(item.get('quantity', 1)),
                'unit': 'pieces',
                'category': item.get('category', 'Other'),
                'confidence': '95.0',
                'type': 'gemini'
            })
        
        return (
            json.dumps({
                'success': True,
                'foods': all_detections,
                'count': len(all_detections),
                'expiryDates': expiry_dates
            }),
            200,
            headers
        )
        
    except Exception as e:
        logger.error(f'Error: {str(e)}')
        import traceback
        traceback.print_exc()
        return (
            json.dumps({'success': False, 'error': str(e)}),
            500,
            headers
        )
