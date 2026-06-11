
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/models/course_model.dart';
import 'package:flutter_application_1/repositories/course_repository.dart';
import 'package:flutter_application_1/services/course_local_store.dart';
import 'package:flutter_application_1/services/course_service.dart';

CourseService _service(MockClientHandler handler) =>
    CourseService(client: MockClient(handler));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('getCourses returns live data and caches it on success', () async {
    final store = CourseLocalStore();
    final repo = CourseRepository(
      service: _service((_) async => http.Response(
            jsonEncode([
              {'id': 1, 'title': 'Live', 'body': 'B', 'userId': 1},
            ]),
            200,
          )),
      localStore: store,
    );

    final result = await repo.getCourses();

    expect(result.fromCache, isFalse);
    expect(result.courses.single.title, 'Live');
    // The successful fetch should have synchronized the local cache.
    final cached = await store.getCourses();
    expect(cached.single.title, 'Live');
  });

  test('getCourses falls back to the cache when the API fails', () async {
    final store = CourseLocalStore();
    await store.saveCourses(
      [Course(id: 7, title: 'Cached', description: 'Offline copy')],
    );

    final repo = CourseRepository(
      service: _service((_) async => http.Response('boom', 500)),
      localStore: store,
    );

    final result = await repo.getCourses();

    expect(result.fromCache, isTrue);
    expect(result.courses.single.title, 'Cached');
  });

  test('getCourses rethrows when the API fails and nothing is cached',
      () async {
    final repo = CourseRepository(
      service: _service((_) async => http.Response('boom', 500)),
      localStore: CourseLocalStore(),
    );

    expect(repo.getCourses, throwsA(isA<ApiException>()));
  });
}
