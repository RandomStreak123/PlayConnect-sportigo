import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';

class MapplsService {
  static const String _autosuggestUrl = 'https://search.mappls.com/search/places/autosuggest/json';
  static const String _reverseGeocodeUrl = 'https://search.mappls.com/search/address/rev-geocode';

  /// Autocomplete search for places using Mappls Autosuggest REST API
  static Future<List<Map<String, dynamic>>> autoSuggest(
    String query, {
    required double latitude,
    required double longitude,
  }) async {
    if (!ApiConstants.isMapplsConfigured) {
      return [];
    }

    try {
      final uri = Uri.parse(_autosuggestUrl).replace(
        queryParameters: {
          'query': query,
          'location': '$latitude,$longitude',
          'access_token': ApiConstants.mapplsApiKey,
        },
      );

      final response = await http.get(uri, headers: {
        'Referer': 'https://sportigo.com',
      });

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List? locations = data['suggestedLocations'];
        if (locations != null) {
          return locations.map<Map<String, dynamic>>((loc) {
            final double lat = (loc['latitude'] as num?)?.toDouble() ?? 0.0;
            final double lon = (loc['longitude'] as num?)?.toDouble() ?? 0.0;
            final String placeName = loc['placeName'] ?? '';
            final String placeAddress = loc['placeAddress'] ?? '';
            final String displayName = placeAddress.isNotEmpty
                ? (placeName.isNotEmpty ? '$placeName, $placeAddress' : placeAddress)
                : placeName;
            
            return {
              'display_name': displayName,
              'lat': lat,
              'lon': lon,
            };
          }).toList();
        }
      }
    } catch (e) {
      // Safely ignore or fallback to Photon
    }
    return [];
  }

  /// Reverse geocode coordinates to a readable address using Mappls Rev-Geocode REST API
  static Future<String?> reverseGeocode(double lat, double lng) async {
    if (!ApiConstants.isMapplsConfigured) {
      return null;
    }

    try {
      final uri = Uri.parse(_reverseGeocodeUrl).replace(
        queryParameters: {
          'lat': lat.toString(),
          'lng': lng.toString(),
          'access_token': ApiConstants.mapplsApiKey,
        },
      );

      final response = await http.get(uri, headers: {
        'Referer': 'https://sportigo.com',
      });

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final String? displayName = data['display_name'] ?? data['formatted_address'];
        return displayName;
      }
    } catch (e) {
      // Safely ignore or fallback to Nominatim
    }
    return null;
  }
}
