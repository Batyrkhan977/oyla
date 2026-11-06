import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oyla/src/app_state.dart';
import 'package:oyla/src/localization.dart';
import 'package:oyla/src/models.dart';
import 'package:oyla/src/sing_screen.dart';
import 'package:oyla/src/song_recordings.dart';
import 'package:oyla/src/video_source.dart';

class CatalogState extends AppState {
  CatalogState(this.language);
  final AppLanguage language;
  @override
  Future<AppData> build() async => AppData(
    settings: UserSettings(language: language),
    results: const [],
  );
}

void main() {
  test('catalog includes the requested ten songs in each language', () {
    expect(songRecordings.map((s) => s.id).toSet(), {
      'yapurai',
      'dudarai',
      'balqadisha',
      'bir-bala',
      'qamajai',
      'elim-ai',
      'bipyl',
      'guilderaiym',
      'daididau',
      'samaltau',
      'kalinka',
      'korobeiniki',
      'iz-za-ostrova',
      'troika',
      'ey-ukhnem',
      'dubinushka',
      'za-morem-sinichka',
      'svetit-mesiats',
      'vanka',
      'vo-pole-bereza',
    });
    expect(songRecordings, hasLength(20));
    for (final language in [AppLanguage.kazakh, AppLanguage.russian]) {
      expect(
        songRecordings.where((s) => s.language == language),
        hasLength(10),
      );
    }
    for (final song in songRecordings) {
      expect(normalizeYouTubeUrl(song.videoUrl), song.videoUrl);
      expect(song.matches(song.title.toUpperCase()), isTrue);
      expect(song.matches(song.transliteration), isTrue);
      expect(song.videoId, isNot(isIn(['DYqBRjA-s98', '92rINhHwfCg'])));
      for (final alternative in song.alternatives) {
        expect(normalizeYouTubeUrl(alternative.videoUrl), alternative.videoUrl);
        expect(alternative.videoId, isNot(song.videoId));
        expect(alternative.performer, isNotEmpty);
      }
    }
    expect(
      songRecordings.singleWhere((s) => s.id == 'vanka').title,
      'Ванька холостой',
    );
  });

  for (final language in AppLanguage.values) {
    testWidgets('catalog search and playback in ${language.name}', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          appStateProvider.overrideWith(() => CatalogState(language)),
        ],
      );
      addTearDown(container.dispose);
      await container.read(appStateProvider.future);
      final calls = <MethodCall>[];
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('oyla/youtube'),
        (call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('oyla/youtube'),
          null,
        ),
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            builder: (context, child) => OylaLanguageScope(
              language: language,
              child: MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.5)),
                child: child!,
              ),
            ),
            home: const SingScreen(),
          ),
        ),
      );
      final title = switch (language) {
        AppLanguage.english => 'Sing',
        AppLanguage.kazakh => 'Ән салайық',
        AppLanguage.russian => 'Петь',
      };
      expect(find.text(title), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Guilderaiym');
      await tester.pump();
      final song = find.byKey(const ValueKey('song:guilderaiym'));
      await tester.ensureVisible(song);
      await tester.tap(song);
      await tester.pumpAndSettle();
      expect(find.byType(SongRecordingScreen), findsOneWidget);
      final play = find.byType(FilledButton);
      await tester.ensureVisible(play);
      await tester.tap(play);
      await tester.pump();
      expect(calls.single.arguments['videoId'], 'e4k8HELTzx4');
      expect(calls.single.arguments['language'], switch (language) {
        AppLanguage.english => 'en',
        AppLanguage.kazakh => 'kk',
        AppLanguage.russian => 'ru',
      });
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Dudarai');
      await tester.pump();
      final dudarai = find.byKey(const ValueKey('song:dudarai'));
      await tester.ensureVisible(dudarai);
      await tester.tap(dudarai);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(calls.last.arguments['videoId'], 'Y4_UpbgH6vQ');
      expect(calls.last.arguments['alternativeVideoIds'], ['tJ6a7oMULjM']);
      expect(calls.last.arguments['songTitle'], 'Дударай');
      final alternative = find.text('Алиса Супронова');
      await tester.ensureVisible(alternative);
      await tester.tap(alternative);
      await tester.pump();
      expect(calls.last.arguments['videoId'], 'tJ6a7oMULjM');
      expect(calls.last.arguments['alternativeVideoIds'], ['Y4_UpbgH6vQ']);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'no-such-song');
      await tester.pump();
      expect(find.byKey(const ValueKey('song:guilderaiym')), findsNothing);
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      final russian = find.widgetWithText(ChoiceChip, switch (language) {
        AppLanguage.english => 'Russian',
        AppLanguage.kazakh => 'Орысша',
        AppLanguage.russian => 'Русские',
      });
      await tester.ensureVisible(russian);
      await tester.tap(russian);
      await tester.pump();
      expect(find.byKey(const ValueKey('song:yapurai')), findsNothing);
      expect(find.byKey(const ValueKey('song:kalinka')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
