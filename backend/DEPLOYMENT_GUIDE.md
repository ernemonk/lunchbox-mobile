# Unified Cloud Functions Deployment System

A metadata-driven deployment system for Google Cloud Functions that auto-discovers deployable functions and manages their configuration through JSON metadata files.

## 🌟 Features

- **Auto-discovery**: Automatically finds all deployable functions in the backend directory
- **Metadata-driven**: Each function configured via `function.json` file
- **Environment management**: Per-function `.env` files with automatic loading
- **Shared dependencies**: Automatic copying of shared code modules
- **Interactive & scriptable**: Works both interactively and in CI/CD pipelines
- **Local development**: Export all environment variables for local testing
- **Status tracking**: Detailed deployment summaries and URLs

## 📁 Project Structure

```
backend/
├── deploy-functions.sh          # Unified deployment script
├── barcode-enrichment/          # Barcode enrichment function
│   ├── function.json           # Function metadata
│   ├── main.py                 # Function code
│   ├── requirements.txt        # Python dependencies
│   ├── .env.barcode            # Env vars (gitignored)
│   └── .env.barcode.example    # Env template
├── image-recognition/           # Image recognition function
│   ├── function.json           # Function metadata
│   ├── image_recognition.py    # Function code
│   ├── requirements.txt        # Python dependencies
│   ├── init_firestore_config.py # Firestore setup script
│   ├── .env.vision             # Env vars (gitignored)
│   └── .env.vision.example     # Env template
├── generate-recipes/            # Recipe generation function
│   ├── function.json           # Function metadata
│   ├── main.py                 # Function code
│   ├── requirements.txt        # Python dependencies
│   ├── .env.recipes            # Env vars (gitignored)
│   └── .env.recipes.example    # Env template
├── shared/                      # Shared code modules
│   └── *.py                    # Shared Python files
└── functions/                   # Legacy folder (utilities only)
    ├── local_server.py         # Local dev server
    └── test_vision.sh          # Vision API test script
```

## 🚀 Quick Start

### 1. Setup Environment Variables

Copy example files and fill in your API keys:

```bash
# Barcode enrichment
cp backend/barcode-enrichment/.env.barcode.example backend/barcode-enrichment/.env.barcode
# Edit .env.barcode and add your API keys

# Image recognition (no keys needed - uses Cloud Vision defaults)
cp backend/image-recognition/.env.vision.example backend/image-recognition/.env.vision

# Recipe generation
cp backend/generate-recipes/.env.recipes.example backend/generate-recipes/.env.recipes
# Edit .env.recipes and add your GEMINI_API_KEY
```

### 2. Deploy Functions

```bash
cd backend

# List available functions
./deploy-functions.sh --list

# Interactive deployment (choose functions)
./deploy-functions.sh

# Deploy all functions
./deploy-functions.sh --all

# Deploy specific function
./deploy-functions.sh barcode-enrichment
./deploy-functions.sh image-recognition
./deploy-functions.sh generate-recipes
```

### 3. Export for Local Development

```bash
# Export all env vars to .env.local
./deploy-functions.sh --export-env

# Use them locally
source .env.local
```

## 📝 Function Metadata Format

Each function requires a `function.json` (or `<name>.function.json`) file:

```json
{
  "name": "my-function",
  "description": "What this function does",
  "icon": "🚀",
  "entrypoint": "my_function_handler",
  "runtime": "python311",
  "memory": "512MB",
  "timeout": "60s",
  "region": "us-central1",
  "source_files": [
    "main.py",
    "requirements.txt"
  ],
  "shared_dependencies": true,
  "env_file": ".env.myfunction",
  "env_vars": [
    "API_KEY",
    "SECRET_TOKEN"
  ],
  "main_py_content": "from mymodule import handler\n__all__ = ['handler']"
}
```

### Field Descriptions

| Field | Required | Description |
|-------|----------|-------------|
| `name` | ✅ | Cloud Function name (must be unique) |
| `description` | ✅ | Human-readable description |
| `icon` | ❌ | Emoji icon for display (default: 📦) |
| `entrypoint` | ✅ | Python function name to invoke |
| `runtime` | ❌ | Python runtime version (default: python311) |
| `memory` | ❌ | Memory allocation (default: 512MB) |
| `timeout` | ❌ | Execution timeout (default: 60s) |
| `region` | ❌ | GCP region (default: us-central1) |
| `source_files` | ✅ | Files to include in deployment |
| `shared_dependencies` | ❌ | Copy `backend/shared/` folder (default: false) |
| `env_file` | ❌ | Environment file name (e.g., `.env.barcode`) |
| `env_vars` | ❌ | List of expected env variable names |
| `main_py_content` | ❌ | Custom main.py content (if needed) |

## 📦 Existing Functions

### 🔖 barcode-enrichmebarcode-enrichment/`  
**Description**: Barcode lookup using multiple data sources (OpenFoodFacts, Nutritionix, Edamam)  
**Env vars**: Optional API keys for premium sources  
**Endpoint**: https://barcode-enrichment-<hash>.a.run.app

### 🍎 image-recognition
**Location**: `backend/image-recognition
**Location**: `backend/functions/`  
**Description**: Food detection using Google Cloud Vision API with Firestore configuration  
**Env vars**: None (uses Cloud Vision defaults)  
**Endpoint**: https://image-recognition-<hash>.a.run.app

### 🤖 generate-recipes
**Location**: `backend/generate-recipes/`  
**Description**: AI recipe generation using Google Gemini API  
**Env vars**: `GEMINI_API_KEY` (required)  
**Endpoint**: https://generate-recipes-<hash>.a.run.app

## 🔧 Adding a New Function

1. **Create function folder**:
   ```bash
   mkdir -p backend/my-new-function
   cd backend/my-new-function
   ```

2. **Create function.json**:
   ```json
   {
     "name": "my-new-function",
     "description": "Does something awesome",
     "icon": "⚡",
     "entrypoint": "my_handler",
     "runtime": "python311",
     "memory": "256MB",
     "timeout": "30s",
     "region": "us-central1",
     "source_files": [
       "main.py",
       "requirements.txt"
     ],
     "env_file": ".env.myfunction"
   }
   ```

3. **Create main.py**:
   ```python
   import functions_framework
   
   @functions_framework.http
   def my_handler(request):
       return {"message": "Hello World!"}
   ```

4. **Create requirements.txt**:
   ```
   functions-framework==3.8.2
   ```

5. **Create .env file** (if needed):
   ```bash
   echo "MY_API_KEY=secret" > .env.myfunction
   ```

6. **Deploy**:
   ```bash
   cd ../../
   ./deploy-functions.sh my-new-function
   ```

That's it! The deployment script will auto-discover your function.

## 🌍 Environment Variables

### Per-Function .env Files

Each function can have its own `.env` file specified in `function.json`:

```bash
# backend/functions/.env.barcode
NUTRITIONIX_APP_ID=abc123
NUTRITIONIX_APP_KEY=xyz789
```

The deployment script:
- ✅ Automatically loads variables from the `.env` file
- ✅ Skips commented lines and empty lines
- ✅ Ignores placeholder values (starting with `your_`)
- ✅ Passes them to Cloud Functions via `--set-env-vars`

### Local Development

Export all environment variables for local testing:

```bash
./deploy-functions.sh --export-env
source .env.local

# Now all function env vars are available
echo $GEMINI_API_KEY
```

## 📊 Deployment Output

Example output:

```
☁️  Google Cloud Functions Unified Deployment
============================================================

ℹ️  Project: lunchbox-gen

✅ Found 3 deployable function(s)

📋 Available Cloud Functions
============================================================

#   NAME                           DESCRIPTION                                        LOCATION
────────────────────────────────────────────────────────────────────────────────────────────
🔖  barcode-enrichment             Barcode lookup using multiple data sources         functions
🍎  image-recognition              Food detection using Cloud Vision API              functions  
🤖  generate-recipes               AI recipe generation using Gemini                  generate-recipes

🚀 Starting Deployment
============================================================
ℹ️  Deploying 3 function(s)

🔖  Deploying: barcode-enrichment
============================================================
ℹ️  Description: Barcode lookup using multiple data sources
ℹ️  Location: /Users/user/Projects/lunchbox/backend/functions
ℹ️  Preparing deployment package...
ℹ️  Copied shared dependencies
ℹ️  Loading environment variables from: .env.barcode
ℹ️  Deploying with 4 environment variables
ℹ️  Deploying to Google Cloud Functions...

✅ Deployed successfully!
📡 URL: https://barcode-enrichment-xyz.a.run.app

📊 Deployment Summary
============================================================
Successfully deployed (3):
  ✅ barcode-enrichment
     https://barcode-enrichment-xyz.a.run.app
  ✅ image-recognition
     https://image-recognition-abc.a.run.app
  ✅ generate-recipes
     https://generate-recipes-def.a.run.app

============================================================
✅ Deployment complete!
```

## 🔒 Security Best Practices

1. **Never commit .env files**:
   ```bash
   # Already in .gitignore
   echo "*.env.*" >> .gitignore
   echo "!*.env.example" >> .gitignore
   ```

2. **Use .env.example templates**:
   - Commit `.env.example` files with placeholder values
   - Copy to `.env.<name>` and fill in real values locally

3. **Rotate API keys regularly**:
   ```bash
   # Update .env file
   vim backend/functions/.env.barcode
   
   # Redeploy with new keys
   ./deploy-functions.sh barcode-enrichment
   ```

4. **Use Secret Manager for production**:
   Consider Google Cloud Secret Manager for sensitive production credentials

## 🐛 Troubleshooting

### "jq not found"
```bash
brew install jq
```

### "gcloud not authenticated"
```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

### "Function not found"
Check that your function has a valid `function.json`:
```bash
./deploy-functions.sh --list
```

### "Deployment failed"
- Check `function.json` syntax (must be valid JSON)
- Verify all `source_files` exist
- Ensure `entrypoint` matches your Python function name
- Check Cloud Function logs: `gcloud functions logs read <function-name>`

## 🔄 Migrating from Old Scripts

Old deployment scripts in `backend/functions/`:
- ❌ `deploy.sh` - Replaced by unified script
- ❌ `deploy_auto.sh` - Replaced by `--all` flag
- ❌ `deploy_barcode.sh` - Use `./deploy-functions.sh barcode-enrichment`
- ❌ `deploy_barcode_only.sh` - Use specific function name

These can be safely deleted after migration.

## 📚 Advanced Usage

### CI/CD Integration

```yaml
# .github/workflows/deploy.yml
- name: Deploy Cloud Functions
  run: |
    cd backend
    ./deploy-functions.sh --all
```

### Conditional Deployment

Deploy only changed functions:

```bash
# Get changed function directories
CHANGED=$(git diff --name-only HEAD~1 | grep '^backend/' | cut -d'/' -f2 | sort -u)

for func in $CHANGED; do
    ./deploy-functions.sh $func
done
```

### Custom Configuration

Override settings per deployment:

```bash
# Deploy with different region
jq '.region = "us-west1"' function.json > function.tmp.json
mv function.tmp.json function.json
./deploy-functions.sh my-function
```

## 🤝 Contributing

When adding new functions:
1. Create `function.json` metadata
2. Add `.env.example` file
3. Update this README
4. Test locally before deploying

## 📄 License

MIT License - See main project LICENSE file
