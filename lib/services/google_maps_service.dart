import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';

class GoogleMapsService {
  static const String _autocompleteUrl = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const String _detailsUrl = 'https://maps.googleapis.com/maps/api/place/details/json';
  static const String _geocodeUrl = 'https://maps.googleapis.com/maps/api/geocode/json';

  /// Suggests places based on user input query, using Google Places Autocomplete API.
  static Future<List<Map<String, dynamic>>> autoSuggest(
    String query, {
    required double latitude,
    required double longitude,
  }) async {
    if (!ApiConstants.isGoogleMapsConfigured) {
      debugPrint('GOOGLE_MAPS_SERVICE_ERROR: Google Maps API key is not configured.');
      return [];
    }

    try {
      final uri = Uri.parse(_autocompleteUrl).replace(
        queryParameters: {
          'input': query,
          'location': '$latitude,$longitude',
          'radius': '50000', // 50 km radius search bias
          'key': ApiConstants.googleMapsApiKey,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List? predictions = data['predictions'];
        if (predictions != null) {
          return predictions.map<Map<String, dynamic>>((pred) {
            return {
              'display_name': pred['description'] ?? '',
              'place_id': pred['place_id'] ?? '',
            };
          }).toList();
        }
      } else {
        debugPrint('GOOGLE_MAPS_SERVICE_ERROR: Status ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('GOOGLE_MAPS_SERVICE_ERROR: Failed to run autoSuggest: $e');
    }
    return [];
  }

  /// Fetches place coordinates and address by placeId using Google Place Details API.
  static Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    if (!ApiConstants.isGoogleMapsConfigured) {
      return null;
    }

    try {
      final uri = Uri.parse(_detailsUrl).replace(
        queryParameters: {
          'place_id': placeId,
          'fields': 'formatted_address,geometry',
          'key': ApiConstants.googleMapsApiKey,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final result = data['result'];
        if (result != null) {
          final geometry = result['geometry'];
          final location = geometry?['location'];
          final double? lat = (location?['lat'] as num?)?.toDouble();
          final double? lng = (location?['lng'] as num?)?.toDouble();
          final String? formattedAddress = result['formatted_address'];

          if (lat != null && lng != null && formattedAddress != null) {
            return {
              'address': formattedAddress,
              'lat': lat,
              'lon': lng,
            };
          }
        }
      } else {
        debugPrint('GOOGLE_MAPS_SERVICE_ERROR: Details Status ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('GOOGLE_MAPS_SERVICE_ERROR: Failed to fetch place details: $e');
    }
    return null;
  }

  /// Reverse geocodes coordinates to a readable address using Google Geocoding API.
  static Future<String?> reverseGeocode(double lat, double lng) async {
    if (!ApiConstants.isGoogleMapsConfigured) {
      return null;
    }

    try {
      final uri = Uri.parse(_geocodeUrl).replace(
        queryParameters: {
          'latlng': '$lat,$lng',
          'key': ApiConstants.googleMapsApiKey,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List? results = data['results'];
        if (results != null && results.isNotEmpty) {
          return results.first['formatted_address'] as String?;
        }
      } else {
        debugPrint('GOOGLE_MAPS_SERVICE_ERROR: Geocode Status ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('GOOGLE_MAPS_SERVICE_ERROR: Failed to run reverseGeocode: $e');
    }
    return null;
  }
}
