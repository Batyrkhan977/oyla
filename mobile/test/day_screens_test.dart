import 'package:oyla/src/music_screens.dart';
import 'package:oyla/src/sing_screen.dart';
import 'package:oyla/src/togyz_screen.dart';
import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oyla/src/api.dart';
import 'package:oyla/src/router.dart';
import 'package:oyla/src/models.dart';
import 'package:oyla/src/activity_editor.dart';
import 'package:oyla/src/video_source.dart';
import 'package:oyla/src/app_state.dart';
import 'package:oyla/src/database.dart';
import 'package:oyla/src/day_models.dart';
import 'package:oyla/src/day_state.dart';
import 'package:oyla/src/day_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Guest extends OylaApi {
  @override
  Future<bool> isSignedIn() async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final screen in <String, Widget>{
    'Navigation': const SizedBox.shrink(),
    'My Day': const MyDayScreen(),
    'Activity editor': const ActivityEditorScreen(kind: ActivityKind.walking),
    'Video source': const VideoSourcePicker(),
    'Routines': const RoutinesScreen(),
    'Library': const LibraryScreen(),
    'Music': const MusicScreen(),
    'Piano': const PianoScreen(),
    'Sing': const SingScreen(),
    'Togyz': const TogyzScreen(),
    'Progress': const DayProgressScreen(),
  }.entries) {
    testWidgets('${screen.key} works on a small display at 200% text size', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        'settings.v1': jsonEncode(
          const UserSettings(onboardingComplete: true).toJson(),
        ),
      });
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
        await container
            .read(dayProvider.notifier)
            .saveRoutine(
              const Routine(
                id: 'walk',
                title: 'An afternoon walk through the neighbourhood',
                kind: ActivityKind.walking,
                weekdays: [1, 2, 3, 4, 5, 6, 7],
                minute: 840,
                duration: 20,
              ),
            );
        await container.read(dayProvider.notifier).initializeDay();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: screen.key == 'Navigation'
              ? MaterialApp.router(
                  routerConfig: container.read(routerProvider),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: const TextScaler.linear(2)),
                    child: child!,
                  ),
                )
              : MaterialApp(
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: const TextScaler.linear(2)),
                    child: child!,
                  ),
                  home: screen.value,
                ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      if (screen.key == 'Navigation') {
        for (var index = 1; index < 4; index++) {
          await tester.tap(find.byType(NavigationDestination).at(index));
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<NavigationBar>(find.byType(NavigationBar))
                .selectedIndex,
            index,
          );
          expect(tester.takeException(), isNull);
        }
        await tester.tap(find.byType(NavigationDestination).first);
        await tester.pumpAndSettle();
      }
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      container.dispose();
      await tester.runAsync(db.close);
    });
  }
}
