import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:oyla/src/localization.dart';
import 'package:oyla/src/models.dart';

void main() {
  test('all locales have explicit translations and matching placeholders', () {
    const english = OylaLocalizations(AppLanguage.english);
    final placeholders = RegExp(r'\{[^}]+\}');
    for (final language in AppLanguage.values) {
      final entries = OylaLocalizations(language).translations;
      expect(
        entries.keys.toSet(),
        english.translations.keys.toSet(),
        reason: '${language.name} has missing or extra keys',
      );
      for (final entry in entries.entries) {
        expect(entry.value.trim(), isNotEmpty, reason: entry.key);
        expect(
          placeholders.allMatches(entry.value).map((m) => m[0]).toSet(),
          placeholders
              .allMatches(english.text(entry.key))
              .map((m) => m[0])
              .toSet(),
          reason: '${language.name}: ${entry.key}',
        );
        if (language != AppLanguage.english &&
            !const {'english', 'kazakh', 'russian'}.contains(entry.key)) {
          expect(
            entry.value,
            isNot(english.text(entry.key)),
            reason: '${language.name}: ${entry.key} is untranslated',
          );
        }
      }
    }
  });

  const settingsKeys = [
    'settings',
    'accessibility',
    'language',
    'largerText',
    'highContrast',
    'reduceMotion',
    'narration',
    'sounds',
    'inputMethod',
    'handwriting',
    'keypad',
    'exerciseComfort',
    'exerciseHelp',
    'keepFourEnabled',
    'reminders',
    'dailyReminder',
    'weekdayTimes',
    'off',
    'quietHours',
    'notificationsDisabled',
    'changeTime',
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
    'accountBackup',
    'cloudBackup',
    'optionalSignIn',
    'aboutOyla',
    'wellnessDisclaimer',
  ];

  test('every Settings string has Kazakh and Russian translations', () {
    const english = OylaLocalizations(AppLanguage.english);
    for (final language in [AppLanguage.kazakh, AppLanguage.russian]) {
      final localized = OylaLocalizations(language);
      for (final key in settingsKeys) {
        expect(localized.text(key), isNot(key), reason: '$key is missing');
        expect(
          localized.text(key),
          isNot(english.text(key)),
          reason: '$key falls back to English for ${language.name}',
        );
      }
    }
  });

  test('main screens and exercise status do not fall back to English', () {
    const keys = [
      'welcomeTitle',
      'paceTitle',
      'wellnessTitle',
      'goodMorning',
      'todayWorkout',
      'startWorkout',
      'yourWeek',
      'progress',
      'friends',
      'activityOf',
      'choicesSoon',
      'remaining',
      'readingAnswer',
      'couldNotRead',
      'memorizeCards',
      'pairsFound',
      'workoutComplete',
      'yourProgress',
      'daysPracticed',
      'yourTrends',
      'recentActivity',
      'trendData',
      'accountTitle',
      'backupConnected',
      'createAccount',
      'storedDevice',
      'backingUp',
      'friendsNeedAccount',
      'yourFriendCode',
      'incomingRequests',
      'friendsPrivacy',
      'activityPrivate',
    ];
    const english = OylaLocalizations(AppLanguage.english);
    for (final language in [AppLanguage.kazakh, AppLanguage.russian]) {
      final localized = OylaLocalizations(language);
      for (final key in keys) {
        expect(localized.text(key), isNot(key), reason: '$key is missing');
        expect(
          localized.text(key),
          isNot(english.text(key)),
          reason: '$key falls back to English for ${language.name}',
        );
      }
    }
  });

  testWidgets('changing the content language keeps the active route visible', (
    tester,
  ) async {
    var language = AppLanguage.english;
    late StateSetter update;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          update = setState;
          return MaterialApp(
            builder: (context, child) =>
                OylaLanguageScope(language: language, child: child!),
            home: Builder(
              builder: (context) =>
                  Scaffold(body: Text(context.strings.text('settings'))),
            ),
          );
        },
      ),
    );

    expect(find.text('Settings'), findsOneWidget);
    update(() => language = AppLanguage.russian);
    await tester.pump();

    expect(find.text('Настройки'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
