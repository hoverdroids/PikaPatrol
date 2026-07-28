# Native Land Digital API Key Setup Guide

## Quick Setup (3 Simple Steps)

### Step 1: Get Your API Key
1. Visit https://api-docs.native-land.ca/get-and-use-your-api-key
2. Sign up for a free account
3. Generate an API key
4. Copy the API key to your clipboard

### Step 2: Add Your API Key to .env File
1. Open the `.env` file in the project root directory
2. Replace `YOUR_API_KEY_HERE` with your actual API key
3. Example:
   ```
   NATIVE_LAND_API_KEY=abc123def456ghi789jkl
   ```
4. Save the file

### Step 3: Restart the App
1. Stop the running app (if it's running)
2. Run `flutter run` again
3. The app will now load your API key from the `.env` file

## How It Works

- The `.env` file contains your API key as an environment variable
- The app loads this file when it starts up (in `main.dart`)
- The `NativeLandService` reads the key and uses it for API requests
- The `.env` file is in `.gitignore` so it won't be committed to version control

## Important Security Notes

✅ **What We Do Right:**
- API key is never hardcoded in source code
- `.env` file is in `.gitignore` (won't be committed to git)
- Easy to change API keys without modifying code
- Works for development and testing

⚠️ **For Production Deployment:**
- Don't commit `.env` files to version control
- Use environment-specific `.env` files for different environments
- Consider using Firebase Remote Config for runtime configuration
- Never share your API key publicly

## Files Involved

- **`.env`** - Your actual API key (private, in .gitignore)
- **`.env.example`** - Template showing the format (public, in version control)
- **`lib/main.dart`** - Loads `.env` file on startup
- **`lib/services/native_land_service.dart`** - Reads API key from environment

## Troubleshooting

### "No Indigenous territory found" appears
- Check that your `.env` file has the correct API key
- Verify there are no extra spaces or quotes around the key
- Restart the app
- Check in the debug console for error messages

### App won't start
- Ensure `.env` file exists in the project root
- Don't use quotes around the API key in `.env`
- Check that there are no typos in the filename

### Still having issues?
- Check that `flutter_dotenv` is installed: `flutter pub get`
- Look at the debug output for any error messages
- The service logs errors to the Flutter debug console

