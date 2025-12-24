# Local Development Server

This directory contains the full-featured local development server for testing barcode enrichment functionality.

## Features

- **Full REST API**: Health checks, barcode lookup, user feedback, statistics
- **Data Source Management**: Enable/disable sources, change priorities, view configurations
- **Local Database**: SQLite caching of lookups and user confirmations
- **Hot Reload**: Changes to shared modules are picked up automatically
- **Comprehensive Logging**: Detailed logs for debugging

## Quick Start

```bash
./start_server.sh
```

The server will start on `http://localhost:8080`

## Manual Setup

If you prefer manual setup:

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
pip install -r ../shared/requirements.txt

# Start server
python3 server.py
```

## API Endpoints

### Health Check
```bash
GET /
```

### List Data Sources
```bash
GET /sources
```

### Enable/Disable Source
```bash
POST /sources/enable
{
  "source_name": "OpenFoodFacts",
  "enabled": true
}
```

### Set Source Priority
```bash
POST /sources/priority
{
  "source_name": "OpenFoodFacts",
  "priority": 100
}
```

### Barcode Lookup
```bash
POST /smart_lookup
{
  "barcode": "3017620422003"
}
```

### User Confirmation
```bash
POST /confirm
{
  "barcode": "3017620422003",
  "user_confirmed": true,
  "source_name": "OpenFoodFacts"
}
```

### Statistics
```bash
GET /stats
```

## Environment Variables

Configure API keys via environment variables:

```bash
export NUTRITIONIX_APP_ID="your_app_id"
export NUTRITIONIX_APP_KEY="your_app_key"
export EDAMAM_APP_ID="your_app_id"
export EDAMAM_APP_KEY="your_app_key"
export UPC_DATABASE_API_KEY="your_key"
export USDA_API_KEY="your_key"
```

Or create a `.env` file (not committed to git):

```
NUTRITIONIX_APP_ID=your_app_id
NUTRITIONIX_APP_KEY=your_app_key
EDAMAM_APP_ID=your_app_id
EDAMAM_APP_KEY=your_app_key
UPC_DATABASE_API_KEY=your_key
USDA_API_KEY=your_key
```

## Testing

Run the comprehensive test suite:

```bash
cd ../tests
python3 test_modular_system.py
```

## Database

The local server uses SQLite for caching:
- Location: `barcode_enrichment.db`
- Tables: `lookups`, `user_confirmations`
- Auto-created on first run

## Port Configuration

Default port: `8080`

To change, edit `server.py`:
```python
app.run(host="0.0.0.0", port=8080, debug=True)
```

## Troubleshooting

### Port Already in Use
```bash
# Find process on port 8080
lsof -i :8080

# Kill the process
kill -9 <PID>
```

### Import Errors
Make sure shared modules are accessible:
```bash
# Verify shared modules
ls -la ../shared/
```

### API Rate Limits
Some data sources have rate limits:
- Nutritionix: 200 requests/day (free tier)
- Edamam: 100 requests/month (free tier)
- UPC Database: Trial limits apply
- OpenFoodFacts: Unlimited (free)
- USDA: Depends on tier

## Development Tips

1. **Add New Data Source**: Create a new plugin in `../shared/barcode_sources_plugins.py`
2. **Modify Merge Strategy**: Edit `data_source_registry.lookup()` in `server.py`
3. **View Logs**: All requests are logged to console with timestamps
4. **Test Changes**: Use `../tests/test_modular_system.py` to verify changes

## Architecture

```
local-dev/
├── server.py           # Flask application
├── start_server.sh     # Startup script
├── requirements.txt    # Dependencies
└── README.md          # This file

../shared/
├── barcode_data_sources.py      # Plugin framework
├── barcode_sources_plugins.py   # Data source implementations
└── requirements.txt             # Shared dependencies

../tests/
├── test_modular_system.py       # Integration tests
└── test_barcode_comprehensive.py # Comprehensive tests
```
