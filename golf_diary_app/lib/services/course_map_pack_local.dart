import '../data/ph_golf_hole_coords.dart';

/// Local course map pack presence (CRSE-006 cache tier). v1 reads only from
/// device storage; CRSE-022 will populate packs under the app documents dir.
class CourseMapPackLocal {
  CourseMapPackLocal._();

  static final CourseMapPackLocal instance = CourseMapPackLocal._();

  /// When non-null, widget tests force pack availability without disk I/O.
  bool? debugHasPack;

  Future<bool> hasPackForCourse(String courseName) async {
    if (debugHasPack != null) return debugHasPack!;
    final canonical = canonicalCourseName(courseName);
    if (canonical == null) return false;
    // No packs shipped yet — satellite cache arrives with CRSE-022.
    return false;
  }
}