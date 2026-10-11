import 'package:flutter_dotenv/flutter_dotenv.dart';

// A setting from the .env file bundled with the app (see .env.example), or "" if it isn't set or
// the file didn't load. These are public settings, not secrets: anything in the app can be read.
String envValue(String key) => dotenv.isInitialized ? (dotenv.env[key]?.trim() ?? "") : "";
