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

  Future<void> _reverseGeocode(LatLng position) async {
    setState(() {
      _isGeocoding = true;
    });

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
      _address = 'Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
      _isGeocoding = false;
    });
  }

  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;

    setState(() {
      _currentCenter = camera.center;
      _address = 'Locating...';
      _isGeocoding = true;
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
    });
    _mapController.move(point, 15.0);
    _reverseGeocode(point);
  }

  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    final lat = _currentCenter.latitude;
    final lon = _currentCenter.longitude;
    final left = lon - 0.5;
    final right = lon + 0.5;
    final top = lat + 0.5;
    final bottom = lat - 0.5;

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?format=json'
        '&q=${Uri.encodeComponent(query)}'
        '&countrycodes=in'
        '&viewbox=$left,$top,$right,$bottom'
        '&limit=5',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'sportigo-app/1.0',
      });

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final LatLng newCenter = LatLng(lat, lon);
          _onSearchResultSelected(newCenter, data[0]['display_name'] ?? query);
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
            child: LocationSearchBar(
              controller: _searchController,
              isSearching: _isSearching,
              onSearchPressed: _searchAddress,
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
