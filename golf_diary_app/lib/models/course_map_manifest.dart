import 'dart:convert';
import 'dart:io';

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
  });

  final int holeNumber;
  final String imagePath;
  final double swLat;
  final double swLon;
  final double neLat;
  final double neLon;
  final int widthPx;
  final int heightPx;

  factory HoleMapManifestEntry.fromJson(Map<String, dynamic> json) {
    final bbox = json['bbox'] as Map<String, dynamic>?;
    return HoleMapManifestEntry(
      holeNumber: json['holeNumber'] as int,
      imagePath: json['imagePath'] as String,
      swLat: (bbox?['swLat'] as num?)?.toDouble() ?? (json['swLat'] as num).toDouble(),
      swLon: (bbox?['swLon'] as num?)?.toDouble() ?? (json['swLon'] as num).toDouble(),
      neLat: (bbox?['neLat'] as num?)?.toDouble() ?? (json['neLat'] as num).toDouble(),
      neLon: (bbox?['neLon'] as num?)?.toDouble() ?? (json['neLon'] as num).toDouble(),
      widthPx: json['widthPx'] as int? ?? 1280,
      heightPx: json['heightPx'] as int? ?? 1280,
    );
  }
}

class CourseMapManifest {
  const CourseMapManifest({
    required this.version,
    required this.courseId,
    required this.holes,
  });

  final int version;
  final String courseId;
  final List<HoleMapManifestEntry> holes;

  factory CourseMapManifest.fromJson(Map<String, dynamic> json) {
    final holesJson = json['holes'] as List<dynamic>? ?? const [];
    return CourseMapManifest(
      version: json['version'] as int? ?? 1,
      courseId: json['courseId'] as String,
      holes: holesJson
          .map((e) => HoleMapManifestEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static CourseMapManifest? parseFile(File file) {
    try {
      final decoded = jsonDecode(file.readAsStringSync());
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
  });

  final HoleMapManifestEntry entry;
  final String packDirectory;
  final File? imageFile;

  bool get hasSatelliteImage =>
      imageFile != null && imageFile!.existsSync();
}