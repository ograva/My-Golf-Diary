import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../data/ph_golf_hole_coords.dart';
import '../models/course_map_manifest.dart';
import 'sync_identity.dart';

/// One hole of a CRSE-041 map pack, ready to draw.
class HoleMapPack {
  const HoleMapPack({
    required this.entry,
    required this.imageBytes,
    this.attribution = kOsmAttribution,
  });

  final HoleMapManifestEntry entry;
  final Uint8List imageBytes;
  final String attribution;
}

const kOsmAttribution = '© OpenStreetMap contributors (ODbL)';

/// Supplies pack images for the FWY map background. The Storage
/// implementation is deliberately thin so it can later delegate to
/// `CourseMapCacheService` (CRSE-022: disk/web cache and versioning).
abstract class HoleMapPackSource {
  /// Null when the course has no pack, the hole is missing, or the read fails.
  Future<HoleMapPack?> loadHole(String courseName, int holeNumber);

  static HoleMapPackSource instance = StorageHoleMapPackSource();
}

/// Established `ph-crse-*` IDs for the surveyed catalog courses
/// (`docs/context/PH_Golf_Venues.md`).
const _courseIds = {
  'Ayala Greenfield Golf & Leisure Club': 'ph-crse-ayala-greenfield',
  'Camp Aguinaldo Golf Club': 'ph-crse-camp-aguinaldo',
  'Cebu Country Club': 'ph-crse-cebu-cc',
  'Club Intramuros Golf Course': 'ph-crse-club-intramuros',
  'Eagle Ridge G&CC — Nick Faldo Course': 'ph-crse-eagle-ridge-faldo',
  'Hallow Ridge Filipinas Golf (KC Filipinas)': 'ph-crse-hallow-ridge',
  'Manila Golf and Country Club': 'ph-crse-manila-golf',
  'Philippine Navy Golf Club': 'ph-crse-phil-navy',
  'Sherwood Hills Golf Club': 'ph-crse-sherwood-hills',
  'Manila Southwoods — Legends Course': 'ph-crse-southwoods-legends',
  'Manila Southwoods — Masters Course': 'ph-crse-southwoods-masters',
  'Valley Golf & Country Club — North': 'ph-crse-valley-north',
  'Valley Golf & Country Club — South': 'ph-crse-valley-south',
  'Veterans Golf Club': 'ph-crse-veterans',
  'Villamor Golf Club': 'ph-crse-villamor',
  'Wack Wack Golf & Country Club — East': 'ph-crse-wack-wack-east',
  'Wack Wack Golf & Country Club — West': 'ph-crse-wack-wack-west',
};

/// Pack folder for [courseName]: the established ID, else
/// `ph-crse-<name-slug>`; null for names outside the catalog.
String? mapPackCourseId(String courseName) {
  final canonical = canonicalCourseName(courseName);
  if (canonical == null) return null;
  final known = _courseIds[canonical];
  if (known != null) return known;
  final slug = canonical
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return 'ph-crse-$slug';
}

/// Reads `course_maps/{courseId}/` from the default bucket as bytes, which
/// works on web and native alike. Session memory only; no disk cache.
class StorageHoleMapPackSource implements HoleMapPackSource {
  final _manifests = <String, Future<CourseMapManifest?>>{};
  final _images = <String, Future<Uint8List?>>{};

  static const _maxManifestBytes = 1 << 20;
  static const _maxImageBytes = 8 << 20;

  Future<CourseMapManifest?> _manifest(String courseId) {
    return _manifests.putIfAbsent(courseId, () async {
      final bytes = await _read(
          'course_maps/$courseId/manifest.json', _maxManifestBytes);
      if (bytes == null) {
        _manifests.remove(courseId);
        return null;
      }
      return CourseMapManifest.parseString(utf8.decode(bytes));
    });
  }

  Future<Uint8List?> _read(String path, int maxBytes) async {
    try {
      if (Firebase.apps.isEmpty) return null;
      await SyncIdentity.ensureSignedIn();
      return await FirebaseStorage.instance.ref(path).getData(maxBytes);
    } catch (error) {
      debugPrint('Map pack read failed for $path: $error');
      return null;
    }
  }

  @override
  Future<HoleMapPack?> loadHole(String courseName, int holeNumber) async {
    final courseId = mapPackCourseId(courseName);
    if (courseId == null) return null;
    final manifest = await _manifest(courseId);
    final entry = manifest?.hole(holeNumber);
    if (manifest == null || entry == null || entry.frame == null) return null;
    final path = 'course_maps/$courseId/${entry.imagePath}';
    final bytes = await _images.putIfAbsent(path, () async {
      final data = await _read(path, _maxImageBytes);
      if (data == null) _images.remove(path);
      return data;
    });
    if (bytes == null) return null;
    return HoleMapPack(
      entry: entry,
      imageBytes: bytes,
      attribution: manifest.attribution ?? kOsmAttribution,
    );
  }
}
