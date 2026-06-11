import 'package:flutter/foundation.dart';

import '../models/course_model.dart';
import '../repositories/course_repository.dart';
import '../services/course_service.dart';
import '../utils/enums.dart';

class CourseProvider extends ChangeNotifier {
  CourseProvider({CourseRepository? repository})
      : _repository = repository ?? CourseRepository();

  final CourseRepository _repository;

  ViewState _state = ViewState.loading;
  String? _error;
  bool _isOffline = false;
  String _query = '';
  List<Course> _courses = [];

  // ---- Public state ---------------------------------------------------------

  ViewState get state => _state;
  String? get error => _error;

  bool get isOffline => _isOffline;

  String get query => _query;

  /// True when there is no underlying data at all (regardless of any filter).
  bool get hasNoData => _courses.isEmpty;

  /// The courses to display, filtered by the active search [query].
  List<Course> get courses {
    if (_query.trim().isEmpty) return List.unmodifiable(_courses);
    final q = _query.toLowerCase();
    return _courses
        .where((c) =>
            c.title.toLowerCase().contains(q) ||
            c.description.toLowerCase().contains(q))
        .toList();
  }

  // ---- Search ---------------------------------------------------------------

  void search(String value) {
    _query = value;
    notifyListeners();
  }

  void clearSearch() {
    if (_query.isEmpty) return;
    _query = '';
    notifyListeners();
  }

  // ---- Read -----------------------------------------------------------------

  /// Loads courses from the repository (network first, cache on failure).
  Future<void> loadCourses() async {
    _state = ViewState.loading;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.getCourses();
      _courses = result.courses;
      _isOffline = result.fromCache;
      _state = _courses.isEmpty ? ViewState.empty : ViewState.success;
    } on ApiException catch (e) {
      _error = e.message;
      _state = ViewState.error;
    }
    notifyListeners();
  }

  /// Pull-to-refresh / retry entry point.
  Future<void> refresh() => loadCourses();

  // ---- Create ---------------------------------------------------------------

  /// Adds a course via the API and inserts it at the top of the list.
  ///
  /// Returns null on success, or an error message on failure. (Create is not
  /// optimistic because the server assigns the id we need to track it by.)
  Future<String?> addCourse(Course input) async {
    try {
      final created = await _repository.addCourse(input);
      _courses.insert(0, created);
      _state = ViewState.success;
      await _repository.syncCache(_courses);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  // ---- Update (optimistic) --------------------------------------------------

  /// Updates a course, applying the change immediately and rolling back if the
  /// API call fails. Returns null on success or an error message on failure.
  Future<String?> updateCourse(Course input) async {
    final index = _courses.indexWhere((c) => c.id == input.id);
    if (index == -1) {
      // Not in the list (e.g. created offline) — treat as a fresh add.
      return addCourse(input);
    }

    final previous = _courses[index];
    _courses[index] = input; // optimistic
    notifyListeners();

    try {
      final saved = await _repository.updateCourse(input);
      _courses[index] = saved;
      await _repository.syncCache(_courses);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      _courses[index] = previous; // rollback
      notifyListeners();
      return e.message;
    }
  }

  // ---- Delete (optimistic) --------------------------------------------------

  /// Removes a course immediately and restores it if the API call fails.
  /// Returns null on success or an error message on failure.
  Future<String?> deleteCourse(Course course) async {
    final index = _courses.indexWhere((c) => c.id == course.id);
    if (index == -1) return null;

    final removed = _courses[index];
    _courses.removeAt(index); // optimistic
    if (_courses.isEmpty) _state = ViewState.empty;
    notifyListeners();

    try {
      await _repository.deleteCourse(course.id);
      await _repository.syncCache(_courses);
      return null;
    } on ApiException catch (e) {
      _courses.insert(index, removed); // rollback
      _state = ViewState.success;
      notifyListeners();
      return e.message;
    }
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}
