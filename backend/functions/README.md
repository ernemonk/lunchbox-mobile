# Cloud Functions Deployment

This directory contains the Google Cloud Functions deployment package for barcode enrichment.

## Quick Deploy

```bash
./deploy.sh
```

The script will:
1. Check for required tools (gcloud CLI)
2. Verify authentication and project setup
3. Prompt for API keys (optional)
4. Package code with shared modules
5. Deploy to Google Cloud Functions
6. Display function URL

## Manual Deployment

### Prerequisites

1. Install Google Cloud SDK:
```bash
# macOS
brew install --cask google-cloud-sdk

# Or download from: https://cloud.google.com/sdk/docs/install
```

2. Authenticate:
```bash
gcloud auth login
```

3. Set project:
```bash
gcloud config set project YOUR_PROJECT_ID
```

### Deploy Command

```bash
gcloud functions deploy barcode-enrichment \
  --runtime python311 \
  --trigger-http \
  --allow-unauthenticated \
  --region us-central1 \
  --memory 256MB \
  --timeout 60s \
  --entry-point barcode_enrichment \
  --source . \
  --set-env-vars NUTRITIONIX_APP_ID=xxx,NUTRITIONIX_APP_KEY=xxx
```

## Configuration

### Region
Default: `us-central1`

Available regions: https://cloud.google.com/functions/docs/locations

### Memory
Default: `256MB`

Options: `128MB`, `256MB`, `512MB`, `1GB`, `2GB`, `4GB`, `8GB`

### Timeout
Default: `60s`

Max: `540s` (9 minutes) for HTTP functions

### Environment Variables

Set API keys via `--set-env-vars`:

```bash
--set-env-vars \
  NUTRITIONIX_APP_ID=your_id,\
  NUTRITIONIX_APP_KEY=your_key,\
  EDAMAM_APP_ID=your_id,\
  EDAMAM_APP_KEY=your_key,\
  UPC_DATABASE_API_KEY=your_key,\
  USDA_API_KEY=your_key
```

Or use Google Secret Manager for better security:
```bash
gcloud secrets create nutritionix-app-id --data-file=-
# Enter your API key, then Ctrl+D

# Grant access to Cloud Functions service account
gcloud secrets add-iam-policy-binding nutritionix-app-id \
  --member="serviceAccount:YOUR_PROJECT@appspot.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

# Use in function
--set-secrets NUTRITIONIX_APP_ID=nutritionix-app-id:latest
```

## Testing Deployed Function

### Using curl

```bash
# Get function URL
FUNCTION_URL=$(gcloud functions describe barcode-enrichment \
  --region us-central1 \
  --format="value(httpsTrigger.url)")

# Test lookup
curl -X POST $FUNCTION_URL \
  -H "Content-Type: application/json" \
  -d '{"barcode":"3017620422003"}'
```

### Using Python

```python
import requests

url = "https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/barcode-enrichment"
response = requests.post(url, json={"barcode": "3017620422003"})
print(response.json())
```

## Monitoring

### View Logs
```bash
# Real-time logs
gcloud functions logs read barcode-enrichment \
  --region us-central1 \
  --limit 50

# Follow logs
gcloud functions logs read barcode-enrichment \
  --region us-central1 \
  --tail
```

### Metrics
View in Google Cloud Console:
- Invocations/second
- Execution time
- Memory usage
- Error rate

URL: https://console.cloud.google.com/functions

## Cost Optimization

### Free Tier (per month)
- 2 million invocations
- 400,000 GB-seconds
- 200,000 GHz-seconds
- 5 GB network egress

### Reduce Costs
1. Use OpenFoodFacts (free, unlimited) as primary source
2. Cache results in your app to minimize lookups
3. Set appropriate timeout (don't use max if not needed)
4. Use minimum required memory (256MB is usually sufficient)

### Estimate Costs
Use the pricing calculator: https://cloud.google.com/products/calculator

## Security

### Authentication
Current: `--allow-unauthenticated` (public access)

For production, consider:

1. **Cloud IAM**:
```bash
--no-allow-unauthenticated
```
Then require authenticated requests with service account tokens.

2. **API Key**:
Add custom API key validation in code.

3. **Firebase Auth**:
Verify Firebase ID tokens in the function.

### CORS
CORS is enabled for all origins (`*`). For production:

```python
if request.method == 'OPTIONS':
    headers = {
        'Access-Control-Allow-Origin': 'https://yourdomain.com',
        'Access-Control-Allow-Methods': 'POST',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Max-Age': '3600'
    }
```

## Updating the Function

### Update Code Only
```bash
./deploy.sh
```

### Update Environment Variables
```bash
gcloud functions deploy barcode-enrichment \
  --update-env-vars NUTRITIONIX_APP_ID=new_value
```

### Update Memory/Timeout
```bash
gcloud functions deploy barcode-enrichment \
  --memory 512MB \
  --timeout 90s
```

## Rollback

### List Versions
```bash
gcloud functions describe barcode-enrichment \
  --region us-central1 \
  --format="table(versionId,updateTime,state)"
```

### Rollback to Previous Version
Google Cloud Functions doesn't support direct rollback. Instead:
1. Keep previous version of code in git
2. Redeploy from that commit

## Deleting the Function

```bash
gcloud functions delete barcode-enrichment \
  --region us-central1
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Deploy Cloud Function

on:
  push:
    branches: [ main ]
    paths:
      - 'backend/functions/**'
      - 'backend/shared/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: google-github-actions/setup-gcloud@v1
        with:
          service_account_key: ${{ secrets.GCP_SA_KEY }}
          project_id: ${{ secrets.GCP_PROJECT_ID }}
      
      - name: Deploy
        run: |
          cd backend/functions
          gcloud functions deploy barcode-enrichment \
            --runtime python311 \
            --trigger-http \
            --allow-unauthenticated \
            --region us-central1 \
            --set-env-vars NUTRITIONIX_APP_ID=${{ secrets.NUTRITIONIX_APP_ID }}
```

## Architecture

```
functions/
├── main.py              # Cloud Function entry point
├── deploy.sh           # Deployment script
├── requirements.txt    # Function dependencies
└── README.md          # This file

../shared/
├── barcode_data_sources.py      # Plugin framework (imported)
├── barcode_sources_plugins.py   # Data sources (imported)
└── requirements.txt             # Shared dependencies
```

## Function Flow

```
1. HTTP POST request → barcode_enrichment(request)
2. Extract barcode from request JSON
3. Initialize DataSourceRegistry
4. Call lookup() with merge_all strategy
5. Combine data from all configured sources
6. Return JSON response with product data
```

## Data Sources Priority

The function uses all configured data sources with priorities:
1. OpenFoodFacts (100) - Free, unlimited
2. Nutritionix (80) - 200 req/day free tier
3. Edamam (70) - 100 req/month free tier
4. USDA (60) - Depends on tier
5. UPC Database (30) - Trial limits

Data is merged using the `merge_all` strategy, combining information from all sources.

## Troubleshooting

### Deployment Fails
- Check `gcloud auth list` - ensure you're logged in
- Verify project: `gcloud config get-value project`
- Check quotas in Cloud Console

### Function Errors
- View logs: `gcloud functions logs read barcode-enrichment`
- Test locally first with `../local-dev/server.py`
- Verify environment variables are set correctly

### Timeout Errors
- Increase timeout: `--timeout 90s`
- Optimize API calls (some sources are slow)
- Consider caching in Firestore/Redis

### Import Errors
- Ensure `../shared/` modules are copied during deployment
- Check `requirements.txt` includes all dependencies
- Verify Python version compatibility (3.11)
