import 'dart:convert';
import 'dart:io';

/// Rotated image frame of a CRSE-041 pack hole: [bearingDeg] (tee→green,
/// compass degrees) points up in the image, centred on [centerLat]/[centerLon].
class HoleMapImageFrame {
  const HoleMapImageFrame({
    required this.centerLat,
    required this.centerLon,
    required this.bearingDeg,
    required this.metersPerPixel,
  });

  final double centerLat;
  final double centerLon;
  final double bearingDeg;
  final double metersPerPixel;

  static HoleMapImageFrame? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final lat = json['centerLat'] as num?;
    final lon = json['centerLon'] as num?;
    final bearing = json['bearingDeg'] as num?;
    final mpp = json['metersPerPixel'] as num?;
    if (lat == null || lon == null || bearing == null || mpp == null) {
      return null;
    }
    if (mpp <= 0) return null;
    return HoleMapImageFrame(
      centerLat: lat.toDouble(),
      centerLon: lon.toDouble(),
      bearingDeg: bearing.toDouble(),
      metersPerPixel: mpp.toDouble(),
    );
  }
}

/// Suggested aim point from the pack pipeline (`target` or `layup`).
class HoleMapMarker {
  const HoleMapMarker({
    required this.id,
    required this.kind,
    required this.lat,
    required this.lon,
    this.reason = '',
  });

  final String id;
  final String kind;
  final double lat;
  final double lon;
  final String reason;

  static HoleMapMarker? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final id = json['id'] as String?;
    final lat = json['lat'] as num?;
    final lon = json['lon'] as num?;
    if (id == null || lat == null || lon == null) return null;
    return HoleMapMarker(
      id: id,
      kind: json['kind'] as String? ?? 'target',
      lat: lat.toDouble(),
      lon: lon.toDouble(),
      reason: json['reason'] as String? ?? '',
    );
  }
}

/// Per-hole satellite frame metadata (Architecture §5.5 `manifest.json`).
class HoleMapManifestEntry {
  const HoleMapManifestEntry({
    required this.holeNumber,
    required this.imagePath,
    required this.swLat,
    required this.swLon,
    required this.neLat,
    required this.neLon,
    required this.widthPx,
    required this.heightPx,
    this.frame,
    this.markers = const [],
    this.coverage,
    this.generated = const [],
    this.lengthYds,
  });

  final int holeNumber;
  final String imagePath;
  final double swLat;
  final double swLon;
  final double neLat;
  final double neLon;
  final int widthPx;
  final int heightPx;

  /// Null for legacy north-up packs; their image must not be drawn rotated.
  final HoleMapImageFrame? frame;
  final List<HoleMapMarker> markers;

  /// `osm`, `partial`, or `generated` (CRSE-041).
  final String? coverage;
  final List<String> generated;
  final int? lengthYds;

  factory HoleMapManifestEntry.fromJson(Map<String, dynamic> json) {
    final bbox = json['bbox'] as Map<String, dynamic>?;
    final markersJson = json['markers'] as List<dynamic>? ?? const [];
    final generatedJson = json['generated'] as List<dynamic>? ?? const [];
    return HoleMapManifestEntry(
      holeNumber: json['holeNumber'] as int,
      imagePath: json['imagePath'] as String,
      swLat: (bbox?['swLat'] as num?)?.toDouble() ?? (json['swLat'] as num).toDouble(),
      swLon: (bbox?['swLon'] as num?)?.toDouble() ?? (json['swLon'] as num).toDouble(),
      neLat: (bbox?['neLat'] as num?)?.toDouble() ?? (json['neLat'] as num).toDouble(),
      neLon: (bbox?['neLon'] as num?)?.toDouble() ?? (json['neLon'] as num).toDouble(),
      widthPx: json['widthPx'] as int? ?? 1280,
      heightPx: json['heightPx'] as int? ?? 1280,
      frame: HoleMapImageFrame.fromJson(json['frame']),
      markers: markersJson
          .map(HoleMapMarker.fromJson)
          .whereType<HoleMapMarker>()
          .toList(),
      coverage: json['coverage'] as String?,
      generated: generatedJson.whereType<String>().toList(),
      lengthYds: (json['lengthYds'] as num?)?.round(),
    );
  }
}

class CourseMapManifest {
  const CourseMapManifest({
    required this.version,
    required this.courseId,
    required this.holes,
    this.attribution,
  });

  final int version;
  final String courseId;
  final List<HoleMapManifestEntry> holes;

  /// Must be shown whenever a pack image is visible (ODbL).
  final String? attribution;

  factory CourseMapManifest.fromJson(Map<String, dynamic> json) {
    final holesJson = json['holes'] as List<dynamic>? ?? const [];
    return CourseMapManifest(
      version: json['version'] as int? ?? 1,
      courseId: json['courseId'] as String,
      holes: holesJson
          .map((e) => HoleMapManifestEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      attribution: json['attribution'] as String?,
    );
  }

  static CourseMapManifest? parseFile(File file) {
    try {
      return parseString(file.readAsStringSync());
    } catch (_) {
      return null;
    }
  }

  static CourseMapManifest? parseString(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) return null;
      return CourseMapManifest.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  HoleMapManifestEntry? hole(int holeNumber) {
    for (final h in holes) {
      if (h.holeNumber == holeNumber) return h;
    }
    return null;
  }
}

/// Resolved local assets for one hole map pane.
class HoleMapFrame {
  const HoleMapFrame({
    required this.entry,
    required this.packDirectory,
    this.imageFile,
    this.imageKey,
  });

  final HoleMapManifestEntry entry;
  final String packDirectory;
  final File? imageFile;

  /// `{courseId}/v{version}/{imagePath}`; looks up the bytes held by
  /// `CourseMapCacheService`, so one image keeps one decoded cache entry.
  final String? imageKey;

  bool get hasSatelliteImage =>
      imageFile != null && imageFile!.existsSync();
}