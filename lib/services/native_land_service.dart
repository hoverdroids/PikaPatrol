import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

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

/// Service to query Native Land Digital API for Indigenous territories
/// API Documentation: https://api-docs.native-land.ca/
///
/// NOTE: The Native Land Digital API now requires an API key.
/// To enable this feature, sign up at https://api-docs.native-land.ca/get-and-use-your-api-key
/// and set your API key as an environment variable or constant below.
class NativeLandService {
  static const String _baseUrl = 'https://native-land.ca/api/index.php';
  static const int _timeoutSeconds = 10;

  /// API key for Native Land Digital API
  /// Set this to your API key obtained from https://api-docs.native-land.ca/
  /// If null, the service will return empty results
  static const String? _apiKey = null;

  /// Whether the API service is available (has an API key configured)
  static bool get isAvailable => _apiKey != null;

  /// Query territories at the given coordinates
  /// Returns a list of territories found at the location
  static Future<List<Territory>> getTerritoriesAt({
    required double latitude,
    required double longitude,
  }) async {
    if (!isAvailable) {
      developer.log(
        'Native Land Digital API not configured. '
        'Get an API key at https://api-docs.native-land.ca/get-and-use-your-api-key',
      );
      return [];
    }

    try {
      final String url = '$_baseUrl?maps=territories&position=$longitude,$latitude&key=$_apiKey';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(
        const Duration(seconds: _timeoutSeconds),
        onTimeout: () => throw Exception('Territory lookup timeout'),
      );

      if (response.statusCode == 200) {
        // The API returns a FeatureCollection
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Check for error in response
        if (data['error'] != null) {
          developer.log('Native Land API error: ${data['error']}');
          return [];
        }

        final List<dynamic> features = data['features'] ?? [];

        return features
            .map((feature) => Territory.fromJson(feature as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 404) {
        // No territory found at this location
        return [];
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        developer.log('Native Land API authentication failed. Check your API key.');
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
      final String url = '$_baseUrl?maps=languages&position=$longitude,$latitude&key=$_apiKey';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(
        const Duration(seconds: _timeoutSeconds),
        onTimeout: () => throw Exception('Language lookup timeout'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['error'] != null) {
          developer.log('Native Land API error: ${data['error']}');
          return [];
        }

        final List<dynamic> features = data['features'] ?? [];

        return features
            .map((feature) => Territory.fromJson(feature as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 404) {
        return [];
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        developer.log('Native Land API authentication failed. Check your API key.');
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

