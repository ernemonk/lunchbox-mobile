#!/usr/bin/env python3
"""
Local Development Server for Lunchbox Cloud Functions
Serves both barcode lookup and image recognition APIs
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import sys
import os

# Import the actual cloud function handlers
from main import barcode_enrichment
from image_recognition import image_recognition

app = Flask(__name__)
CORS(app)

@app.route('/barcode', methods=['POST', 'OPTIONS'])
def barcode_endpoint():
    """Barcode lookup endpoint"""
    if request.method == 'OPTIONS':
        return '', 204
    return barcode_enrichment(request)

@app.route('/vision', methods=['POST', 'OPTIONS'])
def vision_endpoint():
    """Image recognition endpoint"""
    if request.method == 'OPTIONS':
        return '', 204
    return image_recognition(request)

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'endpoints': {
            'barcode': 'POST /barcode',
            'vision': 'POST /vision'
        }
    })

@app.route('/', methods=['GET'])
def index():
    """Root endpoint with API info"""
    return jsonify({
        'name': 'Lunchbox Cloud Functions Local Server',
        'version': '1.0.0',
        'endpoints': [
            {
                'path': '/barcode',
                'method': 'POST',
                'description': 'Barcode lookup (UPC/EAN)',
                'body': {'barcode': 'string'}
            },
            {
                'path': '/vision',
                'method': 'POST',
                'description': 'Image recognition (Cloud Vision API)',
                'body': {'image': 'base64 encoded image'}
            },
            {
                'path': '/health',
                'method': 'GET',
                'description': 'Health check'
            }
        ]
    })

if __name__ == '__main__':
    print('🚀 Starting Lunchbox Local Development Server...')
    print('📍 Barcode API: http://localhost:8080/barcode')
    print('📍 Vision API:  http://localhost:8080/vision')
    print('📍 Health:      http://localhost:8080/health')
    print('=' * 60)
    
    app.run(
        host='0.0.0.0',
        port=8080,
        debug=True
    )
