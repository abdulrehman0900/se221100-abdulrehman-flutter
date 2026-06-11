import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/course_model.dart';

/// Thrown when an API call fails, carrying a user-friendly message.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

/// Service layer for all course-related REST calls.

class CourseService {
  CourseService({http.Client? client}) : _client = client ?? http.Client();

  static const String _baseUrl = 'https://jsonplaceholder.typicode.com/posts';
  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _client;

  final Map<String, String> _jsonHeaders = const {
    'Content-Type': 'application/json; charset=UTF-8',
  };

  /// READ — fetch the list of courses (GET).
  Future<List<Course>> fetchCourses() async {
    return _guard(() async {
      final res = await _client
          .get(Uri.parse('$_baseUrl?_limit=5'))
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
        return data
            .map((e) => Course.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw ApiException('Failed to load courses (${res.statusCode}).');
    });
  }

  /// CREATE — add a new course (POST). Returns the created course.
  Future<Course> addCourse(Course course) async {
    return _guard(() async {
      final res = await _client
          .post(
            Uri.parse(_baseUrl),
            headers: _jsonHeaders,
            body: jsonEncode(course.toJson()),
          )
          .timeout(_timeout);

      if (res.statusCode == 201) {
        return Course.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      }
      throw ApiException('Failed to add course (${res.statusCode}).');
    });
  }

  /// UPDATE — edit an existing course (PUT). Returns the updated course.
  Future<Course> updateCourse(Course course) async {
    return _guard(() async {
      final res = await _client
          .put(
            Uri.parse('$_baseUrl/${course.id}'),
            headers: _jsonHeaders,
            body: jsonEncode(course.toJson()),
          )
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final updated =
            Course.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
        // JSONPlaceholder echoes the payload but may drop the id; keep ours.
        return updated.copyWith(id: course.id);
      }
      throw ApiException('Failed to update course (${res.statusCode}).');
    });
  }

  /// DELETE — remove a course by id (DELETE).
  Future<void> deleteCourse(int id) async {
    return _guard(() async {
      final res =
          await _client.delete(Uri.parse('$_baseUrl/$id')).timeout(_timeout);

      if (res.statusCode != 200) {
        throw ApiException('Failed to delete course (${res.statusCode}).');
      }
    });
  }

  /// Error Handeling.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException {
      rethrow;
    } on http.ClientException {
      // Transport-level failure: connection refused/closed, DNS error, or no
      // network. On web, all browser network errors surface as ClientException;
      // on mobile/desktop, http 1.x also delivers socket failures this way.
      throw ApiException('No internet connection. Please try again.');
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again.');
    } on FormatException {
      throw ApiException('Received an invalid response from the server.');
    } catch (_) {
      throw ApiException('Something went wrong. Please try again.');
    }
  }

  void dispose() => _client.close();
}
