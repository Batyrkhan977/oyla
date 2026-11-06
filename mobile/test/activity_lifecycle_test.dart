import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oyla/src/api.dart';
import 'package:oyla/src/app_state.dart';
import 'package:oyla/src/database.dart';
import 'package:oyla/src/day_models.dart';
import 'package:oyla/src/day_screens.dart';
import 'package:oyla/src/day_state.dart';
import 'package:oyla/src/models.dart';
import 'package:oyla/src/screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Guest extends OylaApi {
  @override
  Future<bool> isSignedIn() async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DateTime now;
  late OylaDatabase db;
  late ProviderContainer container;
  late DayController controller;
  final calls = <MethodCall>[];
  Routine routine(
    String id,
    int minute, {
    int duration = 10,
    ActivityKind kind = ActivityKind.walking,
    List<int> days = const [1, 2, 3, 4, 5, 6, 7],
  }) => Routine(
    id: id,
    title: 'Old name',
    kind: kind,
    weekdays: days,
    minute: minute,
    duration: duration,
    reminder: true,
  );
  DayOccurrence occurrence(String id) => container
      .read(dayProvider)
      .requireValue
      .occurrences
      .firstWhere((o) => o.routine.id == id);
  Future<void> setup() async {
    now = DateTime(2026, 9, 13, 9);
    SharedPreferences.setMockInitialValues({});
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('oyla/reminders'), (
          call,
        ) async {
          calls.add(call);
          return call.method == 'pendingActions' ? [] : null;
        });
    db = OylaDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        apiProvider.overrideWithValue(Guest()),
        dayClockProvider.overrideWithValue(() => now),
      ],
    );
    await container.read(appStateProvider.future);
    await container.read(dayProvider.future);
    controller = container.read(dayProvider.notifier);
  }

  Future<void> close() async {
    container.dispose();
    await db.close();
  }

  test(
    'overlaps include midnight and weekly boundary; touching endpoints are allowed',
    () async {
      await setup();
      addTearDown(close);
      await controller.saveRoutine(routine('a', 540));
      await expectLater(
        controller.saveRoutine(routine('b', 545)),
        throwsA(isA<ActivityScheduleException>()),
      );
      await controller.saveRoutine(routine('b', 550));
      expect(
        routinesOverlap(
          routine('sun', 1435, days: [7]),
          routine('mon', 0, days: [1]),
        ),
        isTrue,
      );
      expect(
        routinesOverlap(
          routine('sun', 1430, days: [7]),
          routine('mon', 0, days: [1]),
        ),
        isFalse,
      );
    },
  );
  test(
    'editing updates today and reminder time; early and concurrent starts fail',
    () async {
      await setup();
      addTearDown(close);
      await controller.saveRoutine(routine('a', 540));
      await controller.saveRoutine(routine('b', 600));
      await controller.initializeDay();
      await controller.saveRoutine(routine('a', 570));
      expect(occurrence('a').displayTime, DateTime(2026, 9, 13, 9, 30));
      await expectLater(
        controller.act(occurrence('a').id, OccurrenceStatus.started),
        throwsA(isA<ActivityScheduleException>()),
      );
      now = DateTime(2026, 9, 13, 10);
      await controller.act(occurrence('a').id, OccurrenceStatus.started);
      await expectLater(
        controller.act(occurrence('b').id, OccurrenceStatus.started),
        throwsA(isA<ActivityScheduleException>()),
      );
      await controller.act(occurrence('a').id, OccurrenceStatus.completed);
      await controller.act(occurrence('b').id, OccurrenceStatus.started);
      expect(occurrence('b').status, OccurrenceStatus.started);
    },
  );
  test(
    'postponing into another activity fails without changing its time',
    () async {
      await setup();
      addTearDown(close);
      await controller.saveRoutine(routine('a', 540));
      await controller.saveRoutine(routine('b', 600));
      await controller.initializeDay();
      await expectLater(
        controller.act(
          occurrence('a').id,
          OccurrenceStatus.postponed,
          postponedTo: DateTime(2026, 9, 13, 10, 5),
        ),
        throwsA(isA<ActivityScheduleException>()),
      );
      expect(occurrence('a').displayTime, now);
    },
  );
  for (final status in OccurrenceStatus.values) {
    test('delete $status survives initialization and reload', () async {
      await setup();
      addTearDown(close);
      await controller.saveRoutine(routine('a', 540));
      await controller.initializeDay();
      if (status != OccurrenceStatus.scheduled) {
        await controller.act(
          occurrence('a').id,
          status,
          postponedTo: status == OccurrenceStatus.postponed
              ? now.add(const Duration(hours: 1))
              : null,
        );
      }
      await controller.deleteOccurrence(occurrence('a').id);
      await controller.initializeDay();
      container.invalidate(dayProvider);
      await container.read(dayProvider.future);
      expect(container.read(dayProvider).requireValue.today(now), isEmpty);
      expect(occurrence('a').deleted, isTrue);
    });
  }
  test(
    'timer counts from actual start, persists continuation and records actual minutes',
    () async {
      await setup();
      addTearDown(close);
      await controller.saveRoutine(routine('a', 480));
      await controller.initializeDay();
      expect(occurrence('a').elapsedSeconds(now), 0);
      await controller.act(occurrence('a').id, OccurrenceStatus.started);
      now = now.add(const Duration(minutes: 12));
      await controller.acknowledgeTimer(occurrence('a').id);
      container.invalidate(dayProvider);
      await container.read(dayProvider.future);
      expect(occurrence('a').timerAcknowledged, isTrue);
      now = now.add(const Duration(minutes: 3));
      await container
          .read(dayProvider.notifier)
          .act(occurrence('a').id, OccurrenceStatus.completed);
      expect(occurrence('a').minutes, 15);
      now = now.add(const Duration(hours: 2));
      expect(occurrence('a').elapsedSeconds(now), 900);
    },
  );
  test(
    'reminders follow edits and postponed dates, and timer alarm follows actual Start',
    () async {
      await setup();
      addTearDown(close);
      final app = container.read(appStateProvider.notifier);
      await app.updateSettings(
        container
            .read(appStateProvider)
            .requireValue
            .settings
            .copyWith(remindersEnabled: true),
      );
      await controller.saveRoutine(routine('a', 600, days: [7]));
      await controller.initializeDay();
      List<dynamic> items() =>
          (calls.lastWhere((c) => c.method == 'scheduleActivities').arguments
                  as Map)['items']
              as List;
      expect(
        items().single['at'],
        DateTime(2026, 9, 13, 10).millisecondsSinceEpoch,
      );
      await controller.saveRoutine(routine('a', 630, days: [7]));
      expect(
        items().single['at'],
        DateTime(2026, 9, 13, 10, 30).millisecondsSinceEpoch,
      );
      expect(items().single['title'], 'Walking');
      final tomorrow = DateTime(2026, 9, 14, 10);
      await controller.act(
        occurrence('a').id,
        OccurrenceStatus.postponed,
        postponedTo: tomorrow,
      );
      now = DateTime(2026, 9, 14, 9);
      await controller.initializeDay();
      expect(
        items().any(
          (i) =>
              i['id'] == occurrence('a').id &&
              i['at'] == tomorrow.millisecondsSinceEpoch,
        ),
        isTrue,
      );
      now = tomorrow.add(const Duration(minutes: 5));
      await controller.act(occurrence('a').id, OccurrenceStatus.started);
      expect(
        items().singleWhere((i) => i['id'] == occurrence('a').id)['at'],
        now.add(const Duration(minutes: 10)).millisecondsSinceEpoch,
      );
      expect(
        items().singleWhere((i) => i['id'] == occurrence('a').id)['completion'],
        isTrue,
      );
      await controller.deleteOccurrence(occurrence('a').id);
      expect(items().any((i) => i['id'] == occurrence('a').id), isFalse);
    },
  );
  testWidgets(
    'preview stays at zero; Start enables timer and deadline offers continue or stop',
    (tester) async {
      await tester.runAsync(() async {
        await setup();
        await controller.saveRoutine(routine('a', 540, duration: 1));
        await controller.initializeDay();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: ActivityReminderMonitor(
              child: MovementScreen(occurrenceId: occurrence('a').id),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('0:00'), findsOneWidget);
      expect(occurrence('a').startedAt, isNull);
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Start'));
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(FilledButton, 'Start'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      expect(occurrence('a').startedAt, now);
      now = now.add(const Duration(minutes: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.text('Planned time completed'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.text('Continue exercise'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      expect(occurrence('a').status, OccurrenceStatus.started);
      expect(occurrence('a').timerAcknowledged, isTrue);
      now = now.add(const Duration(minutes: 2));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('3:00'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(close);
    },
  );
  testWidgets('deadline Stop completes and freezes actual minutes', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await setup();
      await controller.saveRoutine(routine('a', 540, duration: 1));
      await controller.initializeDay();
      await controller.act(occurrence('a').id, OccurrenceStatus.started);
    });
    now = now.add(const Duration(minutes: 1));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: ActivityReminderMonitor(
            child: MovementScreen(occurrenceId: occurrence('a').id),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Stop and complete'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    expect(occurrence('a').status, OccurrenceStatus.completed);
    expect(occurrence('a').minutes, 1);
    now = now.add(const Duration(minutes: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1:00'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(close);
  });
  testWidgets('new cognitive occurrence ignores earlier workout results', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await setup();
      // Workouts normally use the real clock for their day selection.
      now = DateTime.now();
      for (final type in activeExercises) {
        await db.upsertResult(
          ExerciseResult(
            id: type.name,
            type: type,
            date: now.subtract(const Duration(minutes: 30)),
            correct: 1,
            attempted: 1,
            score: 100,
          ),
        );
      }
      container.invalidate(appStateProvider);
      await container.read(appStateProvider.future);
      await controller.saveRoutine(
        routine('mind', 0, kind: ActivityKind.cognitive),
      );
      await controller.initializeDay();
      await controller.act(occurrence('mind').id, OccurrenceStatus.started);
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: WorkoutScreen(
            practice: false,
            occurrenceId: occurrence('mind').id,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Activity 1 of 3'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(close);
  });
}
