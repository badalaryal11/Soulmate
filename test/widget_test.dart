import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soulmate/main.dart';

void main() {
  testWidgets('App compiles and runs smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SoulmateApp());

    // Verify that the title contains 'Soulmate' (in AppBar) or similar.
    // Note: Data fetching is async, so we might just see loading or empty state.
    // Ensure we don't crash.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
