import functions_framework
import google.generativeai as genai
import requests
import os
import json
import logging
import re
import time
from flask import jsonify, Response, stream_with_context

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

API_KEY = os.getenv("GEMINI_API_KEY")
if not API_KEY:
    raise ValueError("GEMINI_API_KEY environment variable is required")
genai.configure(api_key=API_KEY)

# Cache globals
MODEL_CACHE = None
MODEL_CACHE_TIMESTAMP = 0
CACHE_TTL = 3600  # seconds (1 hour)


def list_models_rest():
    """Call REST API to list models with supported generation methods."""
    url = "https://generativelanguage.googleapis.com/v1beta/models"
    headers = {"x-goog-api-key": API_KEY}
    logger.debug("Listing models via REST...")
    resp = requests.get(url, headers=headers)
    if resp.status_code != 200:
        logger.error(f"List models failed: {resp.status_code}, {resp.text}")
        return []
    data = resp.json()
    return data.get("models", [])


def get_cached_models():
    global MODEL_CACHE, MODEL_CACHE_TIMESTAMP
    now = time.time()
    # Refresh if no cache or cache expired
    if MODEL_CACHE is None or (now - MODEL_CACHE_TIMESTAMP) > CACHE_TTL:
        logger.debug("Refreshing model list from API...")
        MODEL_CACHE = list_models_rest()
        MODEL_CACHE_TIMESTAMP = now
    return MODEL_CACHE


def choose_best_model(models):
    """
    Choose the fastest model available.
    Priority: Flash models (fastest) > Pro models (more capable but slower)
    """
    # Priority order: Fastest models first
    # gemini-2.0-flash-exp is the latest and fastest
    # gemini-1.5-flash is very fast and stable
    # Pro models are slower but more capable (fallback)
    priority = [
        'gemini-2.0-flash-exp',      # Newest, fastest
        'gemini-2.0-flash',           # Fast
        'gemini-1.5-flash-latest',    # Latest 1.5 flash
        'gemini-1.5-flash-8b',        # Smaller, faster variant
        'gemini-1.5-flash',           # Stable fast model
        'gemini-1.5-pro',             # Slower but more capable
        'gemini-pro',                 # Legacy fallback
    ]
    
    for preferred in priority:
        for m in models:
            model_name = m.get('name', '')
            methods = m.get('supportedGenerationMethods', [])
            if preferred in model_name and 'generateContent' in methods:
                logger.info(f"Selected fastest available model: {model_name}")
                return model_name
    
    # Fallback to any model that supports generateContent
    for m in models:
        methods = m.get("supportedGenerationMethods", [])
        logger.debug(f"Model {m.get('name')} supports {methods}")
        if "generateContent" in methods:
            return m.get("name")
    
    raise RuntimeError("No model supports generateContent")


def parse_json_response(text):
    """Extract and parse JSON from response text."""
    # Try to extract JSON block if wrapped in markdown
    pattern = r"```json\s*([\s\S]*?)\s*```"
    match = re.search(pattern, text, re.DOTALL)
    if match:
        json_str = match.group(1).strip()
        try:
            return json.loads(json_str), None
        except json.JSONDecodeError as e:
            return text, f"Invalid JSON: {e}"
    else:
        # Try parsing as direct JSON
        try:
            return json.loads(text), None
        except json.JSONDecodeError:
            return text, "No JSON found"


@functions_framework.http
def generate_response(request):
    """
    HTTP Cloud Function entry point for recipe generation.
    
    Supports both regular and streaming responses.
    
    Request body:
        {"prompt": "Your recipe generation prompt", "stream": false}
    
    Response (regular):
        {"response": {...}} on success
        {"error": "message"} on failure
    
    Response (streaming):
        Server-Sent Events stream of chunks
    """
    # Handle CORS preflight
    if request.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '3600'
        }
        return ('', 204, headers)
    
    # CORS headers for actual request
    cors_headers = {
        'Access-Control-Allow-Origin': '*'
    }
    
    request_json = request.get_json(silent=True)
    if not request_json or "prompt" not in request_json:
        return jsonify({"error": 'Missing "prompt" in request'}), 400, cors_headers

    prompt = request_json["prompt"]
    use_streaming = request_json.get("stream", False)
    
    # Input validation
    if not isinstance(prompt, str) or len(prompt.strip()) == 0:
        return jsonify({"error": "Prompt must be a non-empty string"}), 400, cors_headers
    
    if len(prompt) > 10000:  # Reasonable limit
        return jsonify({"error": "Prompt too long (max 10,000 characters)"}), 400, cors_headers

    try:
        models = get_cached_models()
        if not models:
            return jsonify({"error": "Model list could not be fetched"}), 500, cors_headers

        model_name = choose_best_model(models)
        logger.info(f"Using model {model_name} for generation (streaming={use_streaming})")

        model = genai.GenerativeModel(model_name)
        generation_config = {"response_mime_type": "application/json"}

        if use_streaming:
            # Streaming response using Server-Sent Events
            def generate_stream():
                try:
                    response = model.generate_content(
                        prompt, 
                        generation_config=generation_config,
                        stream=True
                    )
                    
                    full_text = ""
                    for chunk in response:
                        if chunk.text:
                            full_text += chunk.text
                            # Send chunk as SSE
                            yield f"data: {json.dumps({'chunk': chunk.text, 'done': False})}\n\n"
                    
                    # Parse final result
                    parsed, error = parse_json_response(full_text)
                    final_data = {
                        'done': True,
                        'response': parsed
                    }
                    if error:
                        final_data['warning'] = error
                    
                    yield f"data: {json.dumps(final_data)}\n\n"
                    
                except Exception as e:
                    logger.exception("Streaming error")
                    yield f"data: {json.dumps({'error': str(e), 'done': True})}\n\n"
            
            headers = {
                **cors_headers,
                'Content-Type': 'text/event-stream',
                'Cache-Control': 'no-cache',
                'Connection': 'keep-alive',
                'X-Accel-Buffering': 'no'  # Disable nginx buffering
            }
            
            return Response(
                stream_with_context(generate_stream()),
                mimetype='text/event-stream',
                headers=headers
            )
        
        else:
            # Regular (non-streaming) response
            logger.debug("Calling generate_content...")
            response = model.generate_content(prompt, generation_config=generation_config)

            text = response.text
            logger.debug(f"Raw response: {text}")

            parsed, error = parse_json_response(text)
            
            if error:
                return jsonify({"response": parsed, "warning": error}), 200, cors_headers
            else:
                return jsonify({"response": parsed}), 200, cors_headers

    except Exception as e:
        logger.exception("Error during generation")
        return jsonify({"error": str(e)}), 500, cors_headers
