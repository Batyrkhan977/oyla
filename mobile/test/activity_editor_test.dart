import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oyla/src/activity_editor.dart';
import 'package:oyla/src/api.dart';
import 'package:oyla/src/app_state.dart';
import 'package:oyla/src/database.dart';
import 'package:oyla/src/day_models.dart';
import 'package:oyla/src/day_state.dart';
import 'package:oyla/src/video_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Guest extends OylaApi {
  @override
  Future<bool> isSignedIn() async => false;
}

void main() {
  testWidgets(
    'add video activity, cancel picker, edit back to timer, update today snapshot',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('oyla/reminders'),
            (call) async => call.method == 'pendingActions' ? [] : null,
          );
      final db = OylaDatabase(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          apiProvider.overrideWithValue(_Guest()),
        ],
      );
      await tester.runAsync(() async {
        await container.read(appStateProvider.future);
        await container.read(dayProvider.future);
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  child: const Text('Open editor'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ActivityEditorScreen(
                        kind: ActivityKind.walking,
                        routine: container
                            .read(dayProvider)
                            .requireValue
                            .routines
                            .firstOrNull,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      Future<void> tapText(String label) async {
        final finder = find.text(label);
        if (finder.hitTestable().evaluate().isEmpty) {
          await tester.scrollUntilVisible(
            finder,
            180,
            scrollable: find.byType(Scrollable).first,
          );
        }
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      await tapText('Open editor');
      expect(find.byType(AlertDialog), findsNothing);
      await tapText('With video');
      await tapText('Choose video source');
      expect(find.byType(VideoSourcePicker), findsOneWidget);
      await tester.enterText(
        find.byType(TextField),
        'https://example.com/video',
      );
      await tapText('Use this video');
      expect(
        find.text('Enter a valid link to a YouTube video.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byType(TextField),
        'https://youtu.be/abcdefghI_1?si=track',
      );
      await tapText('Use this video');
      await tapText('Change video source');
      await tester.enterText(
        find.byType(TextField),
        'https://youtu.be/12345678901',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        find.text('https://www.youtube.com/watch?v=abcdefghI_1'),
        findsOneWidget,
      );
      await tapText('Save activity');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pumpAndSettle();
      final saved = container.read(dayProvider).requireValue.routines.single;
      expect(saved.videoUrl, 'https://www.youtube.com/watch?v=abcdefghI_1');
      expect(
        container
            .read(dayProvider)
            .requireValue
            .occurrences
            .single
            .routine
            .videoUrl,
        saved.videoUrl,
      );
      await tapText('Open editor');
      await tapText('Timer only');
      await tapText('Save activity');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pumpAndSettle();
      expect(
        container.read(dayProvider).requireValue.routines.single.videoUrl,
        isNull,
      );
      expect(
        container.read(dayProvider).requireValue.routines.single.id,
        saved.id,
      );
      expect(
        container
            .read(dayProvider)
            .requireValue
            .occurrences
            .single
            .routine
            .videoUrl,
        isNull,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await tester.runAsync(db.close);
    },
  );
}
