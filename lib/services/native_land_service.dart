import 'dart:convert';
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

/// Service to query Native Land Digital API for Indigenous territories
/// API Documentation: https://native-land.ca/api-docs/
class NativeLandService {
  static const String _baseUrl = 'https://native-land.ca/api/index.php';
  static const int _timeoutSeconds = 10;

  /// Query territories at the given coordinates
  /// Returns a list of territories found at the location
  static Future<List<Territory>> getTerritoriesAt({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final String url = '$_baseUrl?maps=territories&position=$longitude,$latitude';

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
        final List<dynamic> features = data['features'] ?? [];

        return features
            .map((feature) => Territory.fromJson(feature as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 404) {
        // No territory found at this location
        return [];
      } else {
        throw Exception('Failed to fetch territories: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching territories: $e');
      return [];
    }
  }

  /// Query languages at the given coordinates
  static Future<List<Territory>> getLanguagesAt({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final String url = '$_baseUrl?maps=languages&position=$longitude,$latitude';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(
        const Duration(seconds: _timeoutSeconds),
        onTimeout: () => throw Exception('Language lookup timeout'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> features = data['features'] ?? [];

        return features
            .map((feature) => Territory.fromJson(feature as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Failed to fetch languages: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching languages: $e');
      return [];
    }
  }

  /// Query treaties at the given coordinates
  static Future<List<Territory>> getTerritoriesAndLanguagesAt({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final territories = await getTerritoriesAt(latitude: latitude, longitude: longitude);
      final languages = await getLanguagesAt(latitude: latitude, longitude: longitude);
      return [...territories, ...languages];
    } catch (e) {
      print('Error fetching territories and languages: $e');
      return [];
    }
  }
}

