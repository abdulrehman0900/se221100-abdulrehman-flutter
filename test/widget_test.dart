// Smoke test for the app's entry screen.

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('App launches on the Register screen', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Create Account'), findsWidgets);
    expect(find.text('Join the student portal'), findsOneWidget);
  });
}
