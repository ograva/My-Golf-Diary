import '../data/ph_golf_hole_coords.dart';

/// Whether Course mode should expose pin distance, map toggle, and the pin
/// watch stream for the active hole (CRSE-034 / Architecture §5.4).
bool onCourseMappedHoleFeatures({
  required bool simulator,
  required String courseName,
  required int holeNumber,
}) {
  if (simulator) return false;
  return hasHoleCoordinates(courseName, holeNumber);
}

/// Resolved tee/green for the active hole when [onCourseMappedHoleFeatures]
/// is true; otherwise null (custom venue or unmapped hole).
HoleCoordinates? activeHoleCoordinates({
  required bool simulator,
  required String courseName,
  required int holeNumber,
}) {
  if (!onCourseMappedHoleFeatures(
    simulator: simulator,
    courseName: courseName,
    holeNumber: holeNumber,
  )) {
    return null;
  }
  return holeCoordinates(courseName, holeNumber);
}