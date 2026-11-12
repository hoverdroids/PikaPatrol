# Indigenous Territory Lookup Feature

## Overview
This feature integrates Native Land Digital territory data into Pika Patrol. When users capture GPS coordinates via the app's location capture button, the app automatically identifies and displays the Indigenous tribe(s) and languages associated with that geographic location.

## Components Implemented

### 1. Native Land Service (`lib/services/native_land_service.dart`)
A service that queries the Native Land Digital API directly using a local `.env` API key.

**Key Methods:**
- `getTerritoriesAt(latitude, longitude)` - Fetches Indigenous territories at specified coordinates
- `getLanguagesAt(latitude, longitude)` - Fetches Indigenous languages at specified coordinates
- `getTerritoriesAndLanguagesAt(latitude, longitude)` - Fetches both territories and languages

**Data Source:**
- App client: `NATIVE_LAND_API_KEY` from `.env`
- Upstream API: https://native-land.ca/api/index.php
- The upstream API returns GeoJSON FeatureCollections with territory/language information

### 2. Observation Model Updates (`lib/model/observation.dart`)
Added two new fields to store territory information:
- `indigenousTerritories: List<String>?` - List of Indigenous territories
- `indigenousLanguages: List<String>?` - List of Indigenous languages spoken in the area

### 3. Observation Screen Integration (`lib/screens/observation_screen.dart`)
Updated the GPS location capture flow to include territory lookup:

**Modified Method:**
- `_getCurrentPositionAndUpdateUi()` - Now calls territory lookup after capturing coordinates

**New Method:**
- `_fetchAndSetIndigenousTerritories()` - Handles async territory API calls and displays results
- `_buildIndigenousTerritoryInfo()` - Displays territories and languages in the UI with icons

**User Flow:**
1. User taps GPS button to capture coordinates
2. App fetches location from device
3. App automatically queries the Native Land API for territories at that location
4. Territories and languages are:
   - Stored in the observation object
   - Displayed visually with icons (📍 for territories, 🌐 for languages)
   - Shown in a toast notification to the user

### 4. Translation Support (`lib/l10n/translations.dart`)
Added the following translation keys for multilingual support:
- `indigenousTerritories` - Label for territories section
- `indigenousLanguages` - Label for languages section
- `lookingUpIndigenousTerritories` - Loading message
- `noIndigenousTerritoryFound` - Message when no data found
- `failedToFetchTerritoryData` - Error message for API failures

## User Experience

### Visual Display
When territories are found, they appear in the observation header under the location and date fields:

```
Indigenous Territories
📍 Blackfoot Territory
📍 Ktunaxa Territory

Indigenous Languages
🌐 Ktunaxa Language
🌐 Blackfoot Language
```

### Notifications
Users receive toast notifications at each step:
1. "Fetching location..." - When getting GPS coordinates
2. "Looking up Indigenous territories..." - During API call
3. Territory results or "No Indigenous territory data found for this location."

### API Details

### Endpoints Used:
- `GET /api/index.php?maps=territories&position=longitude,latitude&key=YOUR_API_KEY` - For territories
- `GET /api/index.php?maps=languages&position=longitude,latitude&key=YOUR_API_KEY` - For languages

The API key is loaded from the app's local `.env` file and is not committed to the repo.

### Response Format:
```json
{
  "features": [
    {
      "properties": {
        "name": "Territory/Language Name",
        "description": "Optional description"
      }
    }
  ]
}
```

### Error Handling:
- 10-second timeout on API requests to prevent UI hangs
- Graceful fallback if API is unavailable
- No territories found (404 response) results in appropriate user message

## Data Persistence
- Territory and language information is stored with each observation
- Data is saved locally and uploaded to Firebase along with other observation data
- Territory info is displayed when viewing previously saved observations

## Dependencies
- `http` package (already in pubspec.yaml) - For API calls
- `flutter_dotenv` (already in pubspec.yaml) - For loading `.env`

## Notes for Developers

### Respecting Indigenous Peoples
This feature honors Native Land Digital's commitment to:
- Accurate representation of Indigenous territories
- Proper naming and spelling of tribal nations
- Educational awareness about Indigenous lands

### API Rate Limiting
Native Land Digital's free API has reasonable rate limits. Monitor logs if implementing bulk operations.

### Future Enhancements
Potential improvements:
1. Cache territory data locally to reduce API calls for frequently visited areas
2. Add an option to share observations with relevant Indigenous nations
3. Display treaties information (also available from Native Land Digital)
4. Add educational content links about specific territories
5. Allow users to manually enter or correct territory information

## Testing
To test this feature:
1. Open an observation in edit mode
2. Tap the GPS location button in the top-left corner
3. Grant location permissions when prompted
4. Wait for the territory lookup to complete
5. Observe the Indigenous territories and languages displayed
6. Save the observation - territory data will be preserved

## References
- Native Land Digital: https://native-land.ca/
- API Documentation: https://native-land.ca/api-docs/
- Mission: To map Indigenous lands, languages, and treaties

