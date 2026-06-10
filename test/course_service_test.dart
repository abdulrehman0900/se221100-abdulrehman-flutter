// Unit tests for the CourseService API layer, using a mocked HTTP client so
// no real network calls are made.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_application_1/models/course_model.dart';
import 'package:flutter_application_1/services/course_service.dart';

void main() {
  group('CourseService', () {
    test('fetchCourses parses a successful GET response', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        return http.Response(
          jsonEncode([
            {'id': 1, 'title': 'Flutter', 'body': 'Mobile dev', 'userId': 1},
            {'id': 2, 'title': 'REST APIs', 'body': 'CRUD', 'userId': 1},
          ]),
          200,
        );
      });

      final courses = await CourseService(client: client).fetchCourses();

      expect(courses, hasLength(2));
      expect(courses.first.title, 'Flutter');
      expect(courses.first.description, 'Mobile dev');
    });

    test('fetchCourses throws ApiException on a server error', () async {
      final client = MockClient((_) async => http.Response('error', 500));

      expect(
        () => CourseService(client: client).fetchCourses(),
        throwsA(isA<ApiException>()),
      );
    });

    test('addCourse posts the payload and returns the created course', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['title'], 'New Course');
        return http.Response(
          jsonEncode({'id': 101, 'title': 'New Course', 'body': 'Desc'}),
          201,
        );
      });

      final created = await CourseService(client: client).addCourse(
        Course(id: 0, title: 'New Course', description: 'Desc'),
      );

      expect(created.id, 101);
      expect(created.title, 'New Course');
    });

    test('updateCourse keeps the original id on a successful PUT', () async {
      final client = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, endsWith('/5'));
        return http.Response(
          jsonEncode({'title': 'Updated', 'body': 'Body'}),
          200,
        );
      });

      final updated = await CourseService(client: client).updateCourse(
        Course(id: 5, title: 'Updated', description: 'Body'),
      );

      expect(updated.id, 5);
      expect(updated.title, 'Updated');
    });

    test('deleteCourse completes on a 200 response', () async {
      final client = MockClient((request) async {
        expect(request.method, 'DELETE');
        return http.Response('{}', 200);
      });

      await expectLater(
        CourseService(client: client).deleteCourse(3),
        completes,
      );
    });

    test('deleteCourse throws ApiException on failure', () async {
      final client = MockClient((_) async => http.Response('', 404));

      expect(
        () => CourseService(client: client).deleteCourse(3),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
