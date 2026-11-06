import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oyla/src/api.dart';
import 'package:oyla/src/app_state.dart';
import 'package:oyla/src/database.dart';
import 'package:oyla/src/day_state.dart';
import 'package:oyla/src/music_screens.dart';

class Guest extends OylaApi {
  @override
  Future<bool> isSignedIn() async => false;
}

void main() {
  testWidgets(
    'Learn melody waits for the correct key, joins fragments and saves progress',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        const MethodChannel('oyla/reminders'),
        (call) async => call.method == 'pendingActions' ? [] : null,
      );
      messenger.setMockMethodCallHandler(
        const MethodChannel('omirai/media'),
        (call) async => null,
      );
      final db = OylaDatabase(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          apiProvider.overrideWithValue(Guest()),
        ],
      );
      await tester.runAsync(() async {
        await container.read(appStateProvider.future);
        await container.read(dayProvider.future);
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: PianoScreen()),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.tap(find.text('Learn a melody'));
      await tester.pump();
      Future<void> key(String name) async {
        final target = find.widgetWithText(OutlinedButton, name);
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }

      await key('E'); // Wrong key does not advance or complete.
      await key('C');
      await key('D');
      await tester.runAsync(() async {
        expect(await db.dayRows('music_sessions', 'guest'), isEmpty);
      });
      await key('C');
      await key('D');
      await key('E');
      await tester.runAsync(() async {
        expect(await db.dayRows('music_sessions', 'guest'), hasLength(1));
        expect(
          (await db.dayRows(
            'music_progress',
            'guest',
          )).single['data']['completed'],
          1,
        );
      });
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await tester.runAsync(db.close);
    },
  );
}
