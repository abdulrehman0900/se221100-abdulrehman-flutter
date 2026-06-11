import '../models/course_model.dart';
import '../services/course_local_store.dart';
import '../services/course_service.dart';

class CourseResult {
  final List<Course> courses;
  final bool fromCache;

  const CourseResult(this.courses, {this.fromCache = false});
}

class CourseRepository {
  CourseRepository({CourseService? service, CourseLocalStore? localStore})
      : _service = service ?? CourseService(),
        _localStore = localStore ?? CourseLocalStore();

  final CourseService _service;
  final CourseLocalStore _localStore;


  Future<CourseResult> getCourses() async {
    try {
      final remote = await _service.fetchCourses();
      await _localStore.saveCourses(remote); // keep local copy in sync
      return CourseResult(remote, fromCache: false);
    } on ApiException {
      final cached = await _localStore.getCourses();
      if (cached.isNotEmpty) {
        return CourseResult(cached, fromCache: true);
      }
      rethrow; // nothing cached — surface the error to the UI
    }
  }

  /// Reads only the locally cached courses (no network).
  Future<List<Course>> getCachedCourses() => _localStore.getCourses();

  /// Creates a course via the API and returns the server's version.
  Future<Course> addCourse(Course course) => _service.addCourse(course);

  /// Updates a course via the API and returns the server's version.
  Future<Course> updateCourse(Course course) => _service.updateCourse(course);

  /// Deletes a course via the API.
  Future<void> deleteCourse(int id) => _service.deleteCourse(id);

  Future<void> syncCache(List<Course> courses) =>
      _localStore.saveCourses(courses);

  /// When the cache was last refreshed from the API, if ever.
  Future<DateTime?> lastSyncedAt() => _localStore.lastSyncedAt();

  void dispose() => _service.dispose();
}
