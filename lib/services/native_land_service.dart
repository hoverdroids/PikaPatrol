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
    final props = json['properties'] as Map<String, dynamic>?;
    // Native Land returns "Name" (capital N).
    final name = props?['Name'] as String? ?? props?['name'] as String? ?? 'Unknown Territory';
    final description = props?['description'] as String? ?? name;
    return Territory(
      name: name,
      properties: description,
    );
  }
}

/// Resolved map selection data for Native Land's map page.
class NativeLandMapSelection {
  final String category;
  final String name;
  final List<double> center;
  final List<double> bbox;

  NativeLandMapSelection({
    required this.category,
    required this.name,
    required this.center,
    required this.bbox,
  });

  String get centerQuery => '${center[0]},${center[1]}';
  String get bboxQuery => jsonEncode(bbox);
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

  static List<String> _searchQueries(String name) {
    final normalized = name.trim();
    final queries = <String>{normalized.toLowerCase()};

    final withoutParenthetical = normalized.replaceAll(RegExp(r'\s*\([^)]*\)\s*'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (withoutParenthetical.isNotEmpty) {
      queries.add(withoutParenthetical.toLowerCase());
    }

    final withoutComma = normalized.split(',').first.trim();
    if (withoutComma.isNotEmpty) {
      queries.add(withoutComma.toLowerCase());
    }

    final withoutDash = normalized.split('—').first.trim();
    if (withoutDash.isNotEmpty) {
      queries.add(withoutDash.toLowerCase());
    }

    return queries.where((query) => query.isNotEmpty).toList();
  }

  static NativeLandMapSelection? _selectionFromSearchResult(
    Map<String, dynamic> json, {
    required String category,
  }) {
    final name = json['name'] as String?;
    final centroid = json['centroid'] as Map<String, dynamic>?;
    final centroidCoordinates = centroid?['coordinates'];
    final bounds = json['bounds'] as Map<String, dynamic>?;
    final boundsCoordinates = bounds?['coordinates'];

    if (name == null || centroidCoordinates is! List || centroidCoordinates.length < 2 || boundsCoordinates is! List || boundsCoordinates.isEmpty) {
      return null;
    }

    final centerLng = (centroidCoordinates[0] as num?)?.toDouble();
    final centerLat = (centroidCoordinates[1] as num?)?.toDouble();
    if (centerLng == null || centerLat == null) {
      return null;
    }

    final firstRing = boundsCoordinates.first;
    if (firstRing is! List || firstRing.isEmpty) {
      return null;
    }

    double? minLng;
    double? minLat;
    double? maxLng;
    double? maxLat;

    for (final point in firstRing) {
      if (point is! List || point.length < 2) continue;
      final lng = (point[0] as num?)?.toDouble();
      final lat = (point[1] as num?)?.toDouble();
      if (lng == null || lat == null) continue;

      minLng = minLng == null || lng < minLng ? lng : minLng;
      minLat = minLat == null || lat < minLat ? lat : minLat;
      maxLng = maxLng == null || lng > maxLng ? lng : maxLng;
      maxLat = maxLat == null || lat > maxLat ? lat : maxLat;
    }

    if (minLng == null || minLat == null || maxLng == null || maxLat == null) {
      return null;
    }

    return NativeLandMapSelection(
      category: category,
      name: name,
      center: [centerLng, centerLat],
      bbox: [minLng, minLat, maxLng, maxLat],
    );
  }

  /// Resolve a Native Land territory/language name to map zoom metadata.
  static Future<NativeLandMapSelection?> resolveMapSelection({
    required String name,
    required String category,
  }) async {
    for (final query in _searchQueries(name)) {
      try {
        // Native Land's searcher endpoint only recognizes `category` filter
        // values of languages/treaties/greetings; passing "territories"
        // (or anything else) silently returns zero results. Search
        // unfiltered instead and match the desired category client-side —
        // every result already carries its own `category` field.
        final uri = Uri.https(
          'native-land.ca',
          '/api/entry/searcher',
          {
            's': query,
            'geosearch': 'true',
          },
        );

        developer.log('[NativeLandService] map selection search: ${uri.replace(queryParameters: {...uri.queryParameters, 's': query})}');

        final response = await http.get(
          uri,
          headers: {'Accept': 'application/json'},
        ).timeout(
          const Duration(seconds: _timeoutSeconds),
          onTimeout: () => throw Exception('Map selection search timeout'),
        );

        if (response.statusCode != 200) {
          continue;
        }

        final decoded = jsonDecode(response.body);
        if (decoded is! List || decoded.isEmpty) {
          continue;
        }

        final matches = decoded
            .whereType<Map<String, dynamic>>()
            .where((item) => item['category'] == category)
            .map((item) => _selectionFromSearchResult(item, category: category))
            .whereType<NativeLandMapSelection>()
            .toList();
        if (matches.isEmpty) {
          continue;
        }

        final queryLower = query.toLowerCase();
        final exactMatch = matches.where((match) => match.name.toLowerCase() == queryLower).toList();
        return exactMatch.isNotEmpty ? exactMatch.first : matches.first;
      } catch (e) {
        developer.log('Error resolving Native Land map selection for "$name": $e');
      }
    }

    return null;
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

      // Log the request URL with the key redacted for debugging.
      developer.log('[NativeLandService] territories request: ${uri.replace(queryParameters: {...uri.queryParameters, 'key': '***'})}');

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(
        const Duration(seconds: _timeoutSeconds),
        onTimeout: () => throw Exception('Territory lookup timeout'),
      );

      if (response.statusCode == 200) {
        final results = _parseTerritories(response.body);
        developer.log('[NativeLandService] territories result: ${results.length} item(s)');
        return results;
      } else if (response.statusCode == 404) {
        developer.log('[NativeLandService] territories 404 at this location');
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

      // Log the request URL with the key redacted for debugging.
      developer.log('[NativeLandService] languages request: ${uri.replace(queryParameters: {...uri.queryParameters, 'key': '***'})}');

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

