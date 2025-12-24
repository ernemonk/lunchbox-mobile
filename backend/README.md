# Lunchbox Backend - Barcode Enrichment Service

Modular barcode enrichment system with support for multiple data sources and flexible deployment options.

## 📁 Directory Structure

```
backend/
├── local-dev/          # Local development server
│   ├── server.py       # Full-featured Flask app
│   ├── start_server.sh # Quick start script
│   ├── requirements.txt
│   └── README.md
│
├── functions/          # Google Cloud Functions deployment
│   ├── main.py         # Cloud Function entry point
│   ├── deploy.sh       # Deployment script
│   ├── requirements.txt
│   └── README.md
│
├── shared/             # Shared code (used by both)
│   ├── barcode_data_sources.py      # Plugin framework
│   ├── barcode_sources_plugins.py   # Data source implementations
│   └── requirements.txt
│
└── tests/              # Test suite
    ├── test_modular_system.py       # Integration tests
    └── test_barcode_comprehensive.py # Comprehensive tests
```

## 🚀 Quick Start

### Local Development

```bash
cd local-dev
./start_server.sh
```

Server runs on `http://localhost:8080`

### Cloud Deployment

```bash
cd functions
./deploy.sh
```

Follow prompts to deploy to Google Cloud Functions.

## 🔌 Data Sources

The system uses a modular plugin architecture supporting multiple data sources:

### Built-in Sources

| Source | Priority | Rate Limit | Cost | Status |
|--------|----------|------------|------|--------|
| **OpenFoodFacts** | 100 | Unlimited | Free | ✅ Enabled |
| **Nutritionix** | 80 | 200/day | Free tier | 🔧 Configure |
| **Edamam** | 70 | 100/month | Free tier | 🔧 Configure |
| **USDA** | 60 | Varies | Free/Paid | ⚙️ Optional |
| **UPC Database** | 30 | Trial limits | Trial/Paid | ⚙️ Optional |

This folder contains the Google Cloud Functions that power the Lunchbox app.

## Structure

```
backend/
├── generate-recipes/       # AI recipe generation function
│   ├── main.py
│   ├── requirements.txt
│   └── README.md
└── README.md              # This file
```

## Cloud Functions

| Function | Description | Endpoint |
|----------|-------------|----------|
| `generate-recipes` | AI-powered recipe generation using Gemini | `POST /` |

## Adding a New Function

1. Create a new folder: `backend/<function-name>/`
2. Add `main.py` with your function code
3. Add `requirements.txt` with dependencies
4. Add `README.md` with documentation
5. Deploy using `gcloud functions deploy`

## Deployment

Each function is deployed independently from its own folder:

```bash
cd backend/<function-name>
gcloud functions deploy <function-name> \
  --gen2 \
  --runtime=python311 \
  --region=us-central1 \
  --source=. \
  --entry-point=<entry_point> \
  --trigger=http
```

## Environment Variables

All functions may require:

| Variable | Description |
|----------|-------------|
| `GEMINI_API_KEY` | Google AI Studio API key |

## Performance Tips

1. **Use `--min-instances=1`** to eliminate cold starts
2. **Prefer `gemini-1.5-flash`** over `gemini-1.5-pro` for 5-10x faster responses
3. **Cache model lists** to reduce API calls (already implemented)

