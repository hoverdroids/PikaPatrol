# Native Land API Key Setup

## Quick Setup

1. Get a Native Land API key from the Native Land API docs.
2. Copy `.env.example` to `.env` in the project root.
3. Replace `YOUR_API_KEY_HERE` with your actual API key.
4. Restart the app.

## Example `.env`

```dotenv
NATIVE_LAND_API_KEY=abc123def456ghi789jkl
```

## How It Works

- `lib/main.dart` loads `.env` at startup.
- `lib/services/native_land_service.dart` reads `NATIVE_LAND_API_KEY` from the environment.
- The key stays out of version control because `.env` is in `.gitignore`.

## Notes

- This is the simplest setup for using the Native Land API without committing the key.
- If you ever change the key, update `.env` and restart the app.

