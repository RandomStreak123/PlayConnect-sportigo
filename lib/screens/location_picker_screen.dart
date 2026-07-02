import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'location_picker/widgets/location_search_bar.dart';
import 'location_picker/widgets/location_address_card.dart';
import 'location_picker/widgets/location_map_container.dart';
import '../core/constants/api_constants.dart';
import '../services/mappls_service.dart';

class LocationResult {
  final String address;
  final double latitude;
  final double longitude;

  LocationResult({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

class LocationPickerScreen extends StatefulWidget {
  final String? initialAddress;
  const LocationPickerScreen({super.key, this.initialAddress});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng _currentCenter = const LatLng(8.5668163, 76.8711487); // Default to pincode 695582, Kazhakkoottam, Trivandrum
  String _address = 'Kazhakkoottam, Thiruvananthapuram, Kerala, 695582, India';
  bool _isGeocoding = false;
  Timer? _debounceTimer;
  bool _isSearching = false;
  String? _customAddressQuery;
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _address = _sanitizeAddress(widget.initialAddress!);
      _searchController.text = widget.initialAddress!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchAddress();
        }
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGeocoding = true;
      _address = 'Locating...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled. Please enable them in settings.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() {
          _isGeocoding = false;
          _address = 'Location services disabled';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          setState(() {
            _isGeocoding = false;
            _address = 'Permission denied';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied. We cannot request permissions.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() {
          _isGeocoding = false;
          _address = 'Permission denied permanently';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final newCenter = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentCenter = newCenter;
      });
      _mapController.move(newCenter, 15.0);
      await _reverseGeocode(newCenter);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get current location: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() {
        _isGeocoding = false;
        _address = 'Failed to locate user';
      });
    }
  }

  String _sanitizeAddress(String address) {
    String sanitized = address;
    final lowercase = address.toLowerCase();
    if (lowercase.contains('kazhakkoottam') || 
        lowercase.contains('kazhakootm') || 
        lowercase.contains('kazhakuttam')) {
      sanitized = sanitized.replaceAll('695001', '695582');
    }
    return sanitized;
  }

  Future<void> _reverseGeocode(LatLng position, {String? fallbackAddress}) async {
    setState(() {
      _isGeocoding = true;
    });

    if (ApiConstants.isMapplsConfigured) {
      try {
        final address = await MapplsService.reverseGeocode(position.latitude, position.longitude);
        if (address != null && address.isNotEmpty) {
          setState(() {
            _address = _sanitizeAddress(address);
            _isGeocoding = false;
          });
          return;
        }
      } catch (e) {
        // Fallback to OSM Nominatim
      }
    }

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'sportigo-app/1.0',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final displayName = data['display_name'] as String?;
        if (displayName != null) {
          setState(() {
            _address = _sanitizeAddress(displayName);
            _isGeocoding = false;
          });
          return;
        }
      }
    } catch (e) {
      // Ignore network errors
    }

    setState(() {
      _address = fallbackAddress ?? 'Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
      _isGeocoding = false;
    });
  }

  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;

    setState(() {
      _currentCenter = camera.center;
      _address = 'Locating...';
      _isGeocoding = true;
      _searchResults = [];
    });

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      _reverseGeocode(_currentCenter);
    });
  }

  void _onSearchResultSelected(LatLng point, String address) {
    setState(() {
      _currentCenter = point;
      _address = _sanitizeAddress(address);
      _customAddressQuery = null;
      _searchResults = [];
    });
    _mapController.move(point, 15.0);
    _reverseGeocode(point, fallbackAddress: address);
  }

  void _onSuggestionTapped(int index) {
    final result = _searchResults[index];
    final lat = result['lat'] is double
        ? result['lat'] as double
        : double.parse(result['lat'].toString());
    final lon = result['lon'] is double
        ? result['lon'] as double
        : double.parse(result['lon'].toString());
    final displayName = (result['display_name'] ?? _searchController.text.trim()) as String;
    FocusScope.of(context).unfocus();
    _onSearchResultSelected(LatLng(lat, lon), displayName);
  }

  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _customAddressQuery = null;
      _searchResults = [];
    });

    if (ApiConstants.isMapplsConfigured) {
      try {
        final results = await MapplsService.autoSuggest(
          query,
          latitude: 8.5241,  // Trivandrum center
          longitude: 76.9366, // Trivandrum center
        );
        if (results.isNotEmpty) {
          // Filter to Trivandrum district bounds only
          final filtered = results.where((r) {
            final lat = (r['lat'] as num).toDouble();
            final lon = (r['lon'] as num).toDouble();
            return lat >= 8.25 && lat <= 8.80 && lon >= 76.65 && lon <= 77.20;
          }).toList();
          if (filtered.isNotEmpty) {
            setState(() {
              _searchResults = filtered;
              _isSearching = false;
            });
            return;
          }
        }
      } catch (e) {
        // Fallback to OSM Nominatim
      }
    }

    // Trivandrum district bounds (fixed)
    const double left = 76.65;
    const double right = 77.20;
    const double top = 8.80;
    const double bottom = 8.25;

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?format=json'
        '&q=${Uri.encodeComponent(query)}'
        '&countrycodes=in'
        '&viewbox=$left,$top,$right,$bottom'
        '&bounded=1'
        '&limit=5',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'sportigo-app/1.0',
      });

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            _searchResults = data.map((item) => {
              'lat': item['lat'],
              'lon': item['lon'],
              'display_name': item['display_name'],
            }).toList();
          });
        } else {
          setState(() {
            _customAddressQuery = query;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No results for "$query". You can use it as a custom name.')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Location'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Stack(
        children: [
          LocationMapContainer(
            mapController: _mapController,
            currentCenter: _currentCenter,
            onPositionChanged: _onMapPositionChanged,
            onTap: (tapPosition, point) {
              setState(() {
                _currentCenter = point;
                _isGeocoding = true;
                _address = 'Locating...';
              });
              _mapController.move(point, _mapController.camera.zoom);
              _reverseGeocode(point);
            },
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: GestureDetector(
                onTap: _isGeocoding
                    ? null
                    : () {
                        Navigator.pop(
                          context,
                          LocationResult(
                            address: _address,
                            latitude: _currentCenter.latitude,
                            longitude: _currentCenter.longitude,
                          ),
                        );
                      },
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 44,
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LocationSearchBar(
                  controller: _searchController,
                  isSearching: _isSearching,
                  onSearchPressed: _searchAddress,
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    constraints: const BoxConstraints(maxHeight: 250),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        final name = (result['display_name'] ?? 'Unknown') as String;
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.location_on_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          title: Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          onTap: () => _onSuggestionTapped(index),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: LocationAddressCard(
              address: _address,
              isGeocoding: _isGeocoding,
              customAddressQuery: _customAddressQuery,
              onConfirm: () {
                Navigator.pop(
                  context,
                  LocationResult(
                    address: _address,
                    latitude: _currentCenter.latitude,
                    longitude: _currentCenter.longitude,
                  ),
                );
              },
              onUseCustomAddressQuery: () {
                setState(() {
                  _address = _sanitizeAddress(_customAddressQuery!);
                  _customAddressQuery = null;
                });
              },
            ),
          ),
          Positioned(
            bottom: 250,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Theme.of(context).colorScheme.primary,
              onPressed: _isGeocoding ? null : _getCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
