import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Model for territory data from Native Land Digital API
class Territory {
  final String name;
  final String? properties;

  Territory({
    required this.name,
    this.properties,
  });

  factory Territory.fromJson(Map<String, dynamic> json) {
    return Territory(
      name: json['properties']?['name'] ?? 'Unknown Territory',
      properties: json['properties']?['description'] ?? json['properties']?['name'],
    );
  }
}

/// Service to query Indigenous territory and language data from Native Land.
///
/// The API key is loaded from `.env` at build/run time using `flutter_dotenv`.
/// Keep `NATIVE_LAND_API_KEY` out of version control by storing it only in your
/// local `.env` file or CI secret store.
class NativeLandService {
  static const String _baseUrl = 'https://native-land.ca/api/index.php';
  static const String _apiKeyEnvKey = 'NATIVE_LAND_API_KEY';
  static const int _timeoutSeconds = 10;

  static String? get _apiKey {
    final configured = dotenv.env[_apiKeyEnvKey]?.trim();
    if (configured != null && configured.isNotEmpty) {
      return configured;
    }
    return null;
  }

  static bool get _isPlaceholderKey => _apiKey == 'YOUR_API_KEY_HERE';

  /// Logs whether the Native Land API key was loaded, without printing the key.
  static void logApiKeyStatus() {
    final key = _apiKey;
    final isLoaded = key != null;
    final length = key?.length ?? 0;
    final looksValid = isLoaded && !_isPlaceholderKey;

    developer.log(
      '[NativeLandService] env status -> NATIVE_LAND_API_KEY loaded=$isLoaded length=$length placeholder=$_isPlaceholderKey usable=$looksValid',
    );

    if (!looksValid) {
      developer.log(
        '[NativeLandService] Native Land lookup is disabled until a real NATIVE_LAND_API_KEY is set in .env.',
      );
    }
  }

  static Uri _buildUri({
    required String maps,
    required double latitude,
    required double longitude,
  }) {
    final uri = Uri.parse(_baseUrl);
    return uri.replace(
      queryParameters: {
        'maps': maps,
        // Native Land expects latitude,longitude ordering.
        'position': '$latitude,$longitude',
        'key': _apiKey ?? '',
      },
    );
  }

  static List<Territory> _parseTerritories(String responseBody) {
    final dynamic decoded = jsonDecode(responseBody);

    // Native Land may return either a FeatureCollection-like map or a top-level feature list.
    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Territory.fromJson)
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      if (decoded['error'] != null) {
        developer.log('Native Land API error: ${decoded['error']}');
        return [];
      }

      final features = decoded['features'];
      if (features is List) {
        return features
            .whereType<Map<String, dynamic>>()
            .map(Territory.fromJson)
            .toList();
      }
    }

    developer.log('Native Land API returned an unexpected response shape.');
    return [];
  }

  /// Whether the service can make Native Land requests.
  static bool get isAvailable => _apiKey != null && !_isPlaceholderKey;

  /// Query territories at the given coordinates
  /// Returns a list of territories found at the location
  static Future<List<Territory>> getTerritoriesAt({
    required double latitude,
    required double longitude,
  }) async {
    if (!isAvailable) {
      developer.log(
        'Native Land API key is not configured. Add NATIVE_LAND_API_KEY to .env.',
      );
      return [];
    }

    try {
      final uri = _buildUri(
        maps: 'territories',
        latitude: latitude,
        longitude: longitude,
      );

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(
        const Duration(seconds: _timeoutSeconds),
        onTimeout: () => throw Exception('Territory lookup timeout'),
      );

      if (response.statusCode == 200) {
        return _parseTerritories(response.body);
      } else if (response.statusCode == 404) {
        // No territory found at this location
        return [];
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        developer.log('Native Land authentication failed. Check NATIVE_LAND_API_KEY.');
        return [];
      } else {
        throw Exception('Failed to fetch territories: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching territories: $e');
      return [];
    }
  }

  /// Query languages at the given coordinates
  static Future<List<Territory>> getLanguagesAt({
    required double latitude,
    required double longitude,
  }) async {
    if (!isAvailable) {
      return [];
    }

    try {
      final uri = _buildUri(
        maps: 'languages',
        latitude: latitude,
        longitude: longitude,
      );

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(
        const Duration(seconds: _timeoutSeconds),
        onTimeout: () => throw Exception('Language lookup timeout'),
      );

      if (response.statusCode == 200) {
        return _parseTerritories(response.body);
      } else if (response.statusCode == 404) {
        return [];
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        developer.log('Native Land authentication failed. Check NATIVE_LAND_API_KEY.');
        return [];
      } else {
        throw Exception('Failed to fetch languages: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching languages: $e');
      return [];
    }
  }

  /// Query territories and languages at the given coordinates
  static Future<List<Territory>> getTerritoriesAndLanguagesAt({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final territories = await getTerritoriesAt(latitude: latitude, longitude: longitude);
      final languages = await getLanguagesAt(latitude: latitude, longitude: longitude);
      return [...territories, ...languages];
    } catch (e) {
      developer.log('Error fetching territories and languages: $e');
      return [];
    }
  }
}

