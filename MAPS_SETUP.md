# Google Maps Setup Instructions

## Issue: Maps not showing in Clinic Locator

The clinic locator screen shows empty maps because the Google Maps API key is not properly configured.

## Solution:

1. **Get a Google Maps API Key:**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select existing one
   - Enable "Maps SDK for Android" API
   - Create an API key with Android restrictions

2. **Add the API key to your app:**
   - Open `android/secrets.properties`
   - Replace the dummy key with your real API key:
   ```
   GOOGLE_MAPS_API_KEY=YOUR_ACTUAL_API_KEY_HERE
   ```

3. **Rebuild the app:**
   ```bash
   flutter clean
   flutter build apk --release
   ```

## Current Status:
- The app has a dummy API key for development
- Maps will show blank until you add a real Google Maps API key
- All other features work normally

## Security Note:
- Never commit your real API key to version control
- Add `android/secrets.properties` to `.gitignore`
- Use API key restrictions in Google Cloud Console
