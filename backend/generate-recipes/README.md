# Generate Recipes Cloud Function

AI-powered recipe generation using Google Gemini with streaming support.

## Features

- ✅ Fast model selection (prefers `gemini-1.5-flash`)
- ✅ Model caching (1 hour TTL)
- ✅ **Streaming support** via Server-Sent Events (SSE)
- ✅ CORS enabled
- ✅ JSON response parsing

## Environment Variables

| Variable | Description |
|----------|-------------|
| `GEMINI_API_KEY` | Google AI Studio API key |

## Local Development

```bash
cd backend/generate-recipes
pip install -r requirements.txt
export GEMINI_API_KEY="your-key"
functions-framework --target=generate_response --debug
```

## Deploy

```bash
gcloud functions deploy generate-recipes \
  --gen2 \
  --runtime=python311 \
  --region=us-central1 \
  --source=. \
  --entry-point=generate_response \
  --trigger=http \
  --allow-unauthenticated \
  --set-env-vars=GEMINI_API_KEY=your-key \
  --min-instances=1 \
  --memory=512MB
```

## API

### Regular Request

**POST /**

```json
{"prompt": "Generate a keto dinner recipe as JSON"}
```

**Response:**
```json
{"response": {"title": "...", "ingredients": [...], "instructions": [...]}}
```

### Streaming Request

**POST /** with `stream: true`

```json
{"prompt": "Generate a keto dinner recipe as JSON", "stream": true}
```

**Response:** Server-Sent Events stream

```
data: {"chunk": "{ \"title\":", "done": false}

data: {"chunk": " \"Keto", "done": false}

data: {"chunk": " Chicken\"", "done": false}

...

data: {"done": true, "response": {"title": "Keto Chicken", ...}}
```

### Flutter Client Example

```dart
// In your Flutter app
final request = http.Request('POST', Uri.parse(apiUrl));
request.headers['Content-Type'] = 'application/json';
request.body = jsonEncode({'prompt': prompt, 'stream': true});

final client = http.Client();
final response = await client.send(request);

await for (final chunk in response.stream.transform(utf8.decoder)) {
  // Parse SSE format: "data: {...}\n\n"
  if (chunk.startsWith('data: ')) {
    final json = jsonDecode(chunk.substring(6));
    if (json['done'] == true) {
      // Final response
      print(json['response']);
    } else {
      // Partial chunk - update UI progressively
      print(json['chunk']);
    }
  }
}
```
```
