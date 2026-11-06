import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oyla/src/app_state.dart';
import 'package:oyla/src/database.dart';
import 'package:oyla/src/localization.dart';
import 'package:oyla/src/models.dart';
import 'package:oyla/src/screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final language in AppLanguage.values) {
    testWidgets('Settings renders in ${language.name} with larger text', (
      tester,
    ) async {
      const reminderChannel = MethodChannel('oyla/reminders');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(reminderChannel, (_) async => null);
      addTearDown(
        () => messenger.setMockMethodCallHandler(reminderChannel, null),
      );
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({
        'settings.v1': jsonEncode(
          UserSettings(
            onboardingComplete: true,
            largeText: true,
            language: language,
          ).toJson(),
        ),
      });
      final database = OylaDatabase(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(database)],
      );
      await container.read(appStateProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            builder: (context, child) => OylaLanguageScope(
              language: language,
              child: MediaQuery.withClampedTextScaling(
                minScaleFactor: 1.18,
                child: child!,
              ),
            ),
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text(OylaLocalizations(language).text('settings')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      addTearDown(container.dispose);
      addTearDown(database.close);
    });
  }
}
