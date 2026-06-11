
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/providers/course_provider.dart';
import 'package:flutter_application_1/repositories/course_repository.dart';
import 'package:flutter_application_1/services/course_local_store.dart';
import 'package:flutter_application_1/services/course_service.dart';
import 'package:flutter_application_1/utils/enums.dart';

CourseProvider _providerWith({required bool deleteSucceeds}) {
  final client = MockClient((request) async {
    if (request.method == 'GET') {
      return http.Response(
        jsonEncode([
          {'id': 1, 'title': 'Alpha', 'body': 'a', 'userId': 1},
          {'id': 2, 'title': 'Beta', 'body': 'b', 'userId': 1},
        ]),
        200,
      );
    }
    if (request.method == 'DELETE') {
      return http.Response(deleteSucceeds ? '{}' : '', deleteSucceeds ? 200 : 404);
    }
    return http.Response('{}', 200);
  });

  return CourseProvider(
    repository: CourseRepository(
      service: CourseService(client: client),
      localStore: CourseLocalStore(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('loadCourses moves to the success state with data', () async {
    final provider = _providerWith(deleteSucceeds: true);

    await provider.loadCourses();

    expect(provider.state, ViewState.success);
    expect(provider.isOffline, isFalse);
    expect(provider.courses, hasLength(2));
  });

  test('search filters the visible courses without dropping the data',
      () async {
    final provider = _providerWith(deleteSucceeds: true);
    await provider.loadCourses();

    provider.search('beta');

    expect(provider.courses.single.title, 'Beta');
    expect(provider.hasNoData, isFalse); // underlying data is untouched
  });

  test('deleteCourse removes the course on success', () async {
    final provider = _providerWith(deleteSucceeds: true);
    await provider.loadCourses();

    final error = await provider.deleteCourse(provider.courses.first);

    expect(error, isNull);
    expect(provider.courses, hasLength(1));
    expect(provider.courses.single.title, 'Beta');
  });

  test('deleteCourse rolls back when the API rejects it', () async {
    final provider = _providerWith(deleteSucceeds: false);
    await provider.loadCourses();

    final error = await provider.deleteCourse(provider.courses.first);

    expect(error, isNotNull); // failure surfaced to the UI
    expect(provider.courses, hasLength(2)); // optimistic removal undone
    expect(provider.state, ViewState.success);
  });
}
