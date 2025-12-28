# Local Development

## Quick Start (Recommended)

Use the unified local development launcher to run any combination of functions:

```bash
cd backend
./start_local_dev.sh
```

This will show an interactive menu where you can:
- Select individual functions (e.g., `1`, `2`, `3`)
- Select multiple functions (e.g., `1,2` or `1,3`)
- Run all functions at once (press `A`)
- Automatically handles port assignments and virtual environments

**Example session:**
```
Available functions:

  [1] 🔖 Barcode Lookup & Enrichment
      Function: barcode-enrichment
      Port: 8080

  [2] 🍎 Image Recognition (Cloud Vision)
      Function: image-recognition
      Port: 8081

  [3] 🤖 AI Recipe Generation (Gemini)
      Function: generate-recipes
      Port: 8082

  [A] All functions
  [Q] Quit

Select functions to run (e.g., 1 or 1,2,3 or A): 1,2
```

## Available Functions

| Function | Port | Start Command | Test Command |
|----------|------|---------------|--------------|
| **Barcode Enrichment** | 8080 | `cd barcode-enrichment && ./start_local.sh` | `curl -X POST http://localhost:8080 -H "Content-Type: application/json" -d '{"barcode":"012345678905"}'` |
| **Image Recognition** | 8081 | `cd image-recognition && ./start_local.sh` | `cd image-recognition && python test_vision.py <image.jpg>` |
| **Recipe Generation** | 8082 | `cd generate-recipes && ./start_local.sh` | `curl -X POST http://localhost:8082 -H "Content-Type: application/json" -d '{"ingredients":["chicken","rice"]}'` |

## Setup Requirements

### All Functions
- Python 3.8+
- Virtual environment (automatically created by start_local.sh)

### Barcode Enrichment
- Optional: Set API keys in `.env.barcode` for enhanced results
  - `NUTRITIONIX_APP_ID` and `NUTRITIONIX_APP_KEY`
  - `EDAMAM_APP_ID` and `EDAMAM_APP_KEY`

### Image Recognition
- **Required**: Google Cloud service account key
  - Place `vision-key.json` in `local-dev/` or `image-recognition/` folder
  - Download from: [Google Cloud Console](https://console.cloud.google.com/iam-admin/serviceaccounts)

### Recipe Generation
- **Required**: Gemini API key
  - Copy `.env.recipes.example` to `.env.recipes`
  - Add your `GEMINI_API_KEY`
  - Get key from: [Google AI Studio](https://makersuite.google.com/app/apikey)

## Local Development Workflow

1. **Start functions locally**:
   ```bash
   cd backend
   ./start_local_dev.sh
   # Select the functions you want to run
   ```

2. **Test the endpoint**:
   ```bash
   # In a new terminal
   curl -X POST http://localhost:8080 \
     -H "Content-Type: application/json" \
     -d '{"barcode":"012345678905"}'
   ```

3. **Make code changes** - the server will auto-reload

4. **Deploy when ready**:
   ```bash
   cd backend
   ./deploy-functions.sh barcode-enrichment
   ```

## Running Multiple Functions

Each function runs on a different port, so you can run them simultaneously:

```bash
# Terminal 1
cd backend/barcode-enrichment && ./start_local.sh

# Terminal 2  
cd backend/image-recognition && ./start_local.sh

# Terminal 3
cd backend/generate-recipes && ./start_local.sh
```

## Troubleshooting

**Virtual environment issues**:
```bash
# Delete and recreate venv
rm -rf venv
./start_local.sh  # Will recreate automatically
```

**Port already in use**:
```bash
# Find and kill the process
lsof -ti:8080 | xargs kill -9
```

**Missing dependencies**:
```bash
source venv/bin/activate
pip install -r requirements.txt
```

## Legacy Local Dev Folder

The `local-dev/` folder contains legacy test utilities and service account keys:
- `vision-key.json` - Cloud Vision credentials (used by image-recognition)
- `test_vision_quick.py` - Quick Vision API test script
- `test_vision.sh` - Legacy test script (deprecated)

**Note**: Each function now has its own `start_local.sh` in its folder. The combined server approach in `local-dev/` is deprecated.
