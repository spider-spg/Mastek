// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:symptom_checker/main.dart';
import 'package:symptom_checker/services/locale_controller.dart';
import 'package:symptom_checker/services/theme_controller.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      SymptomCheckerApp(
        themeController: ThemeController(initialMode: ThemeMode.light),
        localeController: LocaleController(initialLocale: const Locale('en')),
      ),
    );

    // Verify the app builds by finding the app widget type.
    expect(find.byType(SymptomCheckerApp), findsOneWidget);
  });
}
