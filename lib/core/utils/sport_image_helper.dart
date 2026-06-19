import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SportImageHelper {
  static final Map<String, List<String>> _sportImages = {};
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      List<String> imagePaths = [];
      
      try {
        // Modern Flutter 3.10+ official way
        final AssetManifest assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
        imagePaths = assetManifest.listAssets()
            .where((String key) => key.startsWith('assets/images/') && 
                   (key.endsWith('.jpg') || key.endsWith('.png') || key.endsWith('.jpeg')))
            .toList();
        debugPrint('SportImageHelper: Loaded assets using modern AssetManifest API');
      } catch (e) {
        debugPrint('SportImageHelper: Modern API failed ($e). Falling back to legacy JSON manifest parsing...');
        // Legacy fallback
        final manifestContent = await rootBundle.loadString('AssetManifest.json');
        final Map<String, dynamic> manifestMap = json.decode(manifestContent);
        imagePaths = manifestMap.keys
            .where((String key) => key.startsWith('assets/images/') && 
                   (key.endsWith('.jpg') || key.endsWith('.png') || key.endsWith('.jpeg')))
            .toList();
      }

      _sportImages.clear();
      for (var path in imagePaths) {
        // Decode percent-encoded paths (e.g. "images%20(4).jpg" -> "images (4).jpg")
        final decodedPath = Uri.decodeComponent(path);
        final parts = decodedPath.split('/');
        
        // Path format: assets/images/sport_name/image.jpg
        if (parts.length >= 4) {
          final sport = parts[2].toLowerCase(); 
          if (!_sportImages.containsKey(sport)) {
            _sportImages[sport] = [];
          }
          _sportImages[sport]!.add(decodedPath);
        }
      }
      
      _initialized = true;
      debugPrint('==================================================');
      debugPrint('SportImageHelper initialized successfully!');
      debugPrint('Loaded sports: ${_sportImages.keys.toList()}');
      _sportImages.forEach((sport, paths) {
        debugPrint('  - Sport: "$sport" has ${paths.length} image(s): $paths');
      });
      debugPrint('==================================================');
    } catch (e) {
      debugPrint('==================================================');
      debugPrint('Error loading asset manifest: $e');
      debugPrint('==================================================');
    }
  }

  static String getImageForSport(String sport, {String? matchId}) {
    var lowerSport = sport.toLowerCase().trim();
    
    // Spelling correction for user input variations (e.g. Pedal vs Padel)
    if (lowerSport == 'pedal') {
      lowerSport = 'padel';
    }
    
    final images = _sportImages[lowerSport];
    if (images != null && images.isNotEmpty) {
      // Use matchId or sport name for a stable deterministic hash index
      final stableSeed = (matchId ?? sport).hashCode.abs();
      final index = stableSeed % images.length;
      final selected = images[index];
      debugPrint('SportImageHelper: Selected stable image for "$sport" (matchId: $matchId) -> $selected');
      return selected;
    }
    debugPrint('SportImageHelper WARNING: No images found for sport "$sport" (lowercase: "$lowerSport").');
    debugPrint('  - Loaded sport folders: ${_sportImages.keys.toList()}');
    debugPrint('  - Falling back to default match_bg.png.');
    // Fallback to the default match background if no sport-specific image is found
    return 'assets/images/match_bg.png';
  }

  static List<String> getAllImagePaths() {
    final List<String> allPaths = [];
    _sportImages.values.forEach(allPaths.addAll);
    if (!allPaths.contains('assets/images/match_bg.png')) {
      allPaths.add('assets/images/match_bg.png');
    }
    return allPaths;
  }
}


