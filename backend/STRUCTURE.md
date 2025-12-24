# Backend Folder Structure

## Clean & Organized Structure

```
backend/
├── local-dev/              # Local development server
│   ├── server.py           # Full Flask app with caching & stats
│   ├── start_server.sh     # Quick start script
│   ├── requirements.txt    # Flask dependencies
│   └── README.md           # Local dev documentation
│
├── functions/              # Cloud Functions (barcode enrichment)
│   ├── main.py             # Cloud Function entry point
│   ├── deploy.sh           # GCP deployment script
│   ├── requirements.txt    # Minimal cloud dependencies
│   └── README.md           # Deployment guide
│
├── shared/                 # Shared code (used by both)
│   ├── barcode_data_sources.py       # Plugin framework
│   ├── barcode_sources_plugins.py    # Data source implementations
│   └── requirements.txt              # Core dependencies
│
├── generate-recipes/       # Separate cloud function (recipe generation)
│   ├── main.py
│   ├── requirements.txt
│   └── README.md
│
├── tests/                  # Test suite
│   ├── test_barcode_comprehensive.py # Full barcode test
│   ├── test_modular_system.py        # Plugin system test
│   ├── test_streaming.py             # Recipe generation test
│   └── BARCODE_TEST_ANALYSIS.md      # Test results
│
├── README.md               # Main backend overview
├── REORGANIZATION_GUIDE.md # Migration guide
└── SECURITY_CHECKLIST.md   # Security best practices
```

## What Got Cleaned Up

### Deleted (Duplicates/Old Files)
- ❌ `cloud-functions/` - Old folder (replaced by `functions/` + `shared/`)
- ❌ `barcode_test_results_*.json` - Old test outputs
- ❌ `CLOUD_FUNCTIONS_SETUP.md` - Outdated documentation
- ❌ `MODULAR_SYSTEM_SUMMARY.md` - Replaced by new READMEs
- ❌ `*.pyc` files - Python cache
- ❌ `__pycache__/` directories - Python cache

### Kept (Active/Useful)
- ✅ `local-dev/` - Full-featured development server
- ✅ `functions/` - Cloud deployment (barcode)
- ✅ `shared/` - Plugin system used by both
- ✅ `generate-recipes/` - Separate recipe generation function
- ✅ `tests/` - Test suite
- ✅ Documentation files

## Quick Commands

**Start local server:**
```bash
cd local-dev && ./start_server.sh
```

**Deploy barcode function:**
```bash
cd functions && ./deploy.sh
```

**Run tests:**
```bash
cd tests && python3 test_modular_system.py
```

## Architecture

Both `local-dev/` and `functions/` share the same code from `shared/`:
- Same plugin system
- Same data sources
- Same barcode lookup logic

They run **independently**:
- Local: For development & testing
- Cloud: For production deployment

No network calls between them - they just import the same modules.
