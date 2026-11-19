import 'course_map_cache_service.dart';

/// Back-compat alias for pack presence checks used by [FairwayTrackerScreen].
class CourseMapPackLocal {
  CourseMapPackLocal._();

  static final CourseMapPackLocal instance = CourseMapPackLocal._();

  Future<bool> hasPackForCourse(String courseName) =>
      CourseMapCacheService.instance.hasPackForCourse(courseName);
}