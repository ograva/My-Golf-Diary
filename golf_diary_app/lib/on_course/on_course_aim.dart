/// Aim wedge values stored on [ShotRecord.aimDirection] (CRSE-032).
const kOnCourseAimLeft = 'left';
const kOnCourseAimCenter = 'center';
const kOnCourseAimRight = 'right';

const kOnCourseAimChoices = [
  kOnCourseAimLeft,
  kOnCourseAimCenter,
  kOnCourseAimRight,
];

String normalizeOnCourseAim(String? value) {
  if (value == null || value.isEmpty) return kOnCourseAimCenter;
  if (kOnCourseAimChoices.contains(value)) return value;
  return kOnCourseAimCenter;
}