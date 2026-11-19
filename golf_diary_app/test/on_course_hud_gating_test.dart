import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/data/ph_golf_hole_coords.dart';
import 'package:golf_diary_app/on_course/on_course_hud_gating.dart';

void main() {
  test('simulator mode never shows mapped hole features', () {
    expect(
      onCourseMappedHoleFeatures(
        simulator: true,
        courseName: 'Villamor Golf Club',
        holeNumber: 1,
      ),
      isFalse,
    );
  });

  test('custom course name is not mapped', () {
    expect(
      onCourseMappedHoleFeatures(
        simulator: false,
        courseName: 'My Backyard',
        holeNumber: 1,
      ),
      isFalse,
    );
    expect(
        activeHoleCoordinates(
          simulator: false,
          courseName: 'My Backyard',
          holeNumber: 1,
        ),
        isNull);
  });

  test('partial Sherwood layout maps only surveyed holes', () {
    const course = 'Sherwood Hills Golf Club';
    expect(hasHoleCoordinates(course, 1), isTrue);
    expect(hasHoleCoordinates(course, 3), isFalse);
    expect(hasHoleCoordinates(course, 8), isTrue);
  });
}
