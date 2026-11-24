import 'package:flutter/foundation.dart';

import '../data/ph_golf_hole_coords.dart';
import '../models/course_map_manifest.dart';
import 'course_map_cache_service.dart';

/// One hole of a CRSE-041 map pack, ready to draw.
class HoleMapPack {
  const HoleMapPack({
    required this.entry,
    required this.imageBytes,
    this.attribution = kOsmAttribution,
  });

  final HoleMapManifestEntry entry;

  /// The cache service's instance for this image, so repeat loads share one
  /// `MemoryImage` key.
  final Uint8List imageBytes;
  final String attribution;
}

const kOsmAttribution = '© OpenStreetMap contributors (ODbL)';

/// Supplies pack images for the FWY map background; tests substitute a fake.
abstract class HoleMapPackSource {
  /// Null when the course has no pack, the hole is missing or has no rotated
  /// `frame`, or the read fails.
  Future<HoleMapPack?> loadHole(String courseName, int holeNumber);

  static HoleMapPackSource instance = const CachedHoleMapPackSource();
}

/// Reads packs through [CourseMapCacheService] (disk on native, Cache API on
/// web), downloading the requested hole first on first use.
class CachedHoleMapPackSource implements HoleMapPackSource {
  const CachedHoleMapPackSource();

  @override
  Future<HoleMapPack?> loadHole(String courseName, int holeNumber) async {
    final coords = holeCoordinates(courseName, holeNumber);
    if (coords == null) return null;
    final cache = CourseMapCacheService.instance;
    try {
      final result = await cache.resolveHoleMap(
        courseName: courseName,
        holeNumber: holeNumber,
        coords: coords,
        allowDownload: true,
      );
      final frame = result.frame;
      if (result.kind != CourseMapResolveKind.satellite ||
          frame == null ||
          frame.entry.frame == null) {
        return null;
      }
      final bytes = cache.cachedImageBytes(frame);
      if (bytes == null) return null;
      return HoleMapPack(entry: frame.entry, imageBytes: bytes);
    } catch (error) {
      debugPrint('Map pack unavailable for $courseName #$holeNumber: $error');
      return null;
    }
  }
}
