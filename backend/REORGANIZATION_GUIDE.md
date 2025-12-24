# Backend Reorganization Summary

## Overview

The backend folder has been reorganized to separate local development from cloud deployment, while maintaining shared code for consistency.

## New Structure

```
backend/
├── local-dev/          # Local Development Environment
├── functions/          # Cloud Functions Deployment
├── shared/             # Shared Modules
└── tests/              # Test Suite
```

## Migration Guide

### Before (Old Structure)
```
backend/
└── cloud-functions/
    ├── local_server.py              # Mixed purpose (dev + deployment)
    ├── barcode_data_sources.py      # Core framework
    ├── barcode_sources_plugins.py   # Plugin implementations
    └── example_custom_source.py     # Template
```

### After (New Structure)
```
backend/
├── local-dev/
│   ├── server.py                 # Full Flask app (dev only)
│   ├── start_server.sh          # Quick start script
│   ├── requirements.txt         # Flask + requests
│   └── README.md
│
├── functions/
│   ├── main.py                  # Cloud Function (deployment only)
│   ├── deploy.sh                # GCP deployment script
│   ├── requirements.txt         # Minimal deps (functions-framework)
│   └── README.md
│
├── shared/
│   ├── barcode_data_sources.py      # Plugin framework (shared)
│   ├── barcode_sources_plugins.py   # Plugin implementations (shared)
│   ├── example_custom_source.py     # Template (shared)
│   └── requirements.txt             # Core deps (requests)
│
└── tests/
    ├── test_modular_system.py
    └── test_barcode_comprehensive.py
```

## What Changed

### 1. **Local Development** (`local-dev/`)
- **File**: `server.py` (replaces `cloud-functions/local_server.py`)
- **Features**:
  - Full Flask application with 10+ endpoints
  - SQLite database for caching
  - User confirmation tracking
  - Data source management API
  - Comprehensive logging
- **Usage**: `./start_server.sh` or `python3 server.py`

### 2. **Cloud Deployment** (`functions/`)
- **File**: `main.py` (new, optimized for Cloud Functions)
- **Features**:
  - Single `barcode_enrichment(request)` function
  - CORS support (pre-flight + headers)
  - Minimal dependencies
  - Production error handling
  - No local database (stateless)
- **Usage**: `./deploy.sh`

### 3. **Shared Code** (`shared/`)
- **Files**:
  - `barcode_data_sources.py` - Plugin framework
  - `barcode_sources_plugins.py` - 6 built-in sources
  - `example_custom_source.py` - Template
- **Imported by**: Both `local-dev/server.py` AND `functions/main.py`
- **Ensures**: Code consistency between environments

### 4. **Tests** (`tests/`)
- Moved from root of `backend/` to organized folder
- Can test both local and deployed versions

## Key Differences

| Feature | Local Dev | Cloud Functions |
|---------|-----------|-----------------|
| **Framework** | Flask | functions-framework |
| **Endpoints** | 10+ (full REST API) | 1 (barcode_enrichment) |
| **Database** | SQLite (caching) | None (stateless) |
| **User Feedback** | ✅ Tracked in DB | ❌ Not implemented |
| **Source Management** | ✅ Enable/disable/priority | ❌ Static config |
| **CORS** | ✅ Flask-CORS | ✅ Manual headers |
| **Logging** | ✅ Detailed console | ✅ Cloud Logging |
| **Cost** | Free (local) | Pay-per-use |
| **Scaling** | Manual | Auto-scaling |

## Startup Scripts

### Root Level Script
- **File**: `/start_barcode_server.sh`
- **Updated**: Now delegates to `backend/local-dev/start_server.sh`
- **Usage**: `./start_barcode_server.sh` (still works!)

### Local Dev Script
- **File**: `backend/local-dev/start_server.sh`
- **Features**:
  - Creates virtual environment
  - Installs dependencies
  - Starts Flask server
  - Shows available endpoints

### Deployment Script
- **File**: `backend/functions/deploy.sh`
- **Features**:
  - Checks gcloud installation
  - Prompts for API keys
  - Packages code with shared modules
  - Deploys to Google Cloud Functions
  - Shows function URL

## Import Changes

### Old (cloud-functions/local_server.py)
```python
from barcode_data_sources import DataSourceRegistry
from barcode_sources_plugins import (
    OpenFoodFactsSource,
    NutritionixSource,
    ...
)
```

### New (local-dev/server.py)
```python
import sys
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from shared.barcode_data_sources import DataSourceRegistry
from shared.barcode_sources_plugins import (
    OpenFoodFactsSource,
    NutritionixSource,
    ...
)
```

### New (functions/main.py)
```python
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../shared'))

from barcode_data_sources import DataSourceRegistry
from barcode_sources_plugins import OpenFoodFactsSource, ...
```

## Benefits

### ✅ Separation of Concerns
- Development server has full features for testing
- Cloud function is streamlined for production
- No unnecessary dependencies in deployment

### ✅ Code Reuse
- Shared plugin system used by both
- Single source of truth for data sources
- Bug fixes apply to both environments

### ✅ Easy Testing
- Test locally with full features
- Deploy to cloud with confidence
- Shared modules ensure consistency

### ✅ Flexible Deployment
- Can deploy to multiple cloud platforms
- Local dev doesn't require cloud access
- Environment-specific optimizations

### ✅ Clear Documentation
- Each directory has its own README
- Startup/deployment scripts are self-contained
- Examples and guides for each environment

## Migration Checklist

If you had custom modifications to the old structure:

- [ ] **Custom data sources**: Move to `shared/barcode_sources_plugins.py`
- [ ] **API keys**: Set as environment variables for both local and cloud
- [ ] **Database queries**: Only in `local-dev/server.py` (Cloud Functions is stateless)
- [ ] **Flask routes**: Add to `local-dev/server.py`
- [ ] **Cloud-specific code**: Add to `functions/main.py`
- [ ] **Tests**: Move to `tests/` directory
- [ ] **Documentation**: Update to reflect new structure

## Quick Reference

### Start Local Server
```bash
# Option 1: From project root
./start_barcode_server.sh

# Option 2: From backend/local-dev
cd backend/local-dev
./start_server.sh

# Option 3: Manual
cd backend/local-dev
python3 server.py
```

### Deploy to Cloud
```bash
cd backend/functions
./deploy.sh
```

### Run Tests
```bash
cd backend/tests
python3 test_modular_system.py
```

### Add New Data Source
1. Edit `backend/shared/barcode_sources_plugins.py`
2. Create new class extending `BarcodeDataSource`
3. Test locally
4. Redeploy cloud function

## Environment Variables

Both local and cloud use the same environment variables:

```bash
# Optional API keys (set as needed)
export NUTRITIONIX_APP_ID="..."
export NUTRITIONIX_APP_KEY="..."
export EDAMAM_APP_ID="..."
export EDAMAM_APP_KEY="..."
export UPC_DATABASE_API_KEY="..."
export USDA_API_KEY="..."
```

**Local Dev**: Set in terminal or `.env` file  
**Cloud Functions**: Set during deployment via `deploy.sh` or gcloud command

## Next Steps

1. ✅ **Structure created** - All directories and files in place
2. ✅ **Shared code** - Plugin system works in both environments
3. ✅ **Scripts ready** - Startup and deployment scripts created
4. ✅ **Documentation** - READMEs for each component
5. ⏭️ **Test locally** - Run `./start_barcode_server.sh`
6. ⏭️ **Test cloud** - Deploy with `./deploy.sh`
7. ⏭️ **Archive old files** - Move/delete old `cloud-functions/` if desired

## Backward Compatibility

The root-level `start_barcode_server.sh` has been updated to:
- Look for `backend/local-dev/` instead of `backend/cloud-functions/`
- Delegate to `backend/local-dev/start_server.sh` if it exists
- Fall back to manual start if needed
- Show helpful error messages if structure is different

## Questions?

Check the README files:
- `backend/README.md` - Overview and architecture
- `backend/local-dev/README.md` - Local development guide
- `backend/functions/README.md` - Cloud deployment guide
- `shared/DATA_SOURCES_README.md` - Plugin system documentation
