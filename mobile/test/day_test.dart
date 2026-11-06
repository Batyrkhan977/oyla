import 'dart:convert';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oyla/src/api.dart';
import 'package:oyla/src/app_state.dart';
import 'package:oyla/src/database.dart';
import 'package:oyla/src/day_models.dart';
import 'package:oyla/src/day_state.dart';
import 'package:oyla/src/models.dart';
import 'package:oyla/src/reading_library.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GuestApi extends OylaApi {
  @override
  Future<bool> isSignedIn() async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 9, 12, 16);
  Routine routine({
    ActivityKind kind = ActivityKind.reading,
    int duration = 20,
    bool reminder = true,
  }) => Routine(
    id: 'routine',
    title: 'Reading',
    kind: kind,
    weekdays: [1, 2, 3, 4, 5, 6, 7],
    minute: 9 * 60,
    duration: duration,
    reminder: reminder,
  );
  ActivityEvent event(
    int i,
    String type, {
    int hour = 14,
    int minutes = 10,
    ActivityKind kind = ActivityKind.reading,
  }) => ActivityEvent(
    id: 'e$i:$type',
    activityId: 'o$i',
    routineId: 'routine',
    kind: kind,
    type: type,
    at: DateTime(2026, 9, 1 + i, hour),
    startedAt: DateTime(2026, 9, 1 + i, hour),
    scheduledAt: DateTime(2026, 9, 1 + i, 9),
    postponedTo: type == 'POSTPONED' ? DateTime(2026, 9, 1 + i, hour) : null,
    duration: minutes,
  );
  test('five explainable rules require evidence and preserve routine', () {
    final r = routine();
    final before = jsonEncode(r.toJson());
    expect(
      recommend([r], [event(0, 'POSTPONED'), event(1, 'POSTPONED')], [], now),
      isEmpty,
    );
    expect(
      recommend(
        [r],
        List.generate(3, (i) => event(i, 'POSTPONED')),
        [],
        now,
      ).first.type,
      'postponed',
    );
    final completion = List.generate(5, (i) => event(i, 'COMPLETED'));
    expect(
      recommend([r], completion, [], now).map((r) => r.type),
      containsAll(['time', 'duration']),
    );
    expect(
      recommend(
        [r],
        List.generate(5, (i) => event(i, 'REMINDER_SENT')),
        [],
        now,
      ).first.type,
      'reminder',
    );
    expect(
      recommend(
        [routine(kind: ActivityKind.yoga)],
        List.generate(
          5,
          (i) => event(i, 'COMPLETED', kind: ActivityKind.taiChi),
        ),
        [],
        now,
      ).map((r) => r.type),
      contains('movement'),
    );
    expect(jsonEncode(r.toJson()), before);
  });
  test('opened reminders do not count as ignored', () {
    final events = [
      for (var i = 0; i < 5; i++) ...[
        event(i, 'REMINDER_SENT'),
        event(i, 'REMINDER_OPENED'),
      ],
    ];
    expect(recommend([routine()], events, [], now), isEmpty);
  });
  test('recommendation rejection cooldown and 28-day window', () {
    final events = List.generate(3, (i) => event(i, 'POSTPONED'));
    final proposal = recommend([routine()], events, [], now).first;
    final rejected = DayRecommendation.fromJson({
      ...proposal.toJson(),
      'decision': 'rejected',
      'decidedAt': now.toIso8601String(),
    });
    expect(
      recommend(
        [routine()],
        events,
        [rejected],
        now.add(const Duration(days: 1)),
      ),
      isEmpty,
    );
    expect(
      recommend(
        [routine()],
        events,
        [rejected],
        now.add(const Duration(days: 14)),
      ),
      isNotEmpty,
    );
    expect(
      recommend([routine()], events, [], now.add(const Duration(days: 29))),
      isEmpty,
    );
  });
  test('twelve complete localized original materials', () {
    expect(readingLibrary.length, 12);
    expect(readingLibrary.map((b) => b.id).toSet().length, 12);
    for (final b in readingLibrary) {
      for (final l in AppLanguage.values) {
        expect(b.text(l).length, 3);
        expect(b.text(l).every((p) => p.length > 40), isTrue);
        expect(b.questions[b.index(l)].length, 2);
        expect(b.answers[b.index(l)].length, 2);
        expect(b.metadata(l)['publicationPermission'], isNotEmpty);
      }
    }
  });
  test('a postponed activity stays visible on its completion day', () {
    final tomorrow = now.add(const Duration(days: 1));
    final occurrence =
        DayOccurrence(
              id: 'o',
              routine: routine(),
              date: dayKey(now),
              scheduledAt: now,
            )
            .transition(OccurrenceStatus.postponed, now, postponedTo: tomorrow)
            .transition(OccurrenceStatus.completed, tomorrow, minutes: 10);
    final data = DayData(
      owner: 'guest',
      routines: [routine()],
      occurrences: [occurrence],
      events: [],
      recommendations: [],
      settings: {},
      positions: [],
      readingSessions: [],
    );
    expect(data.today(tomorrow), [occurrence]);
    expect(occurrence.activityDate, dayKey(tomorrow));
    expect(occurrence.date, dayKey(now));
  });
  test('daily workouts contain exactly three active unique games', () {
    for (var i = 0; i < 90; i++) {
      final d = DateTime(2026, 1, 1 + i);
      final chosen = dailyExercises(d);
      expect(chosen.length, 3);
      expect(chosen.toSet().length, 3);
      expect(chosen.every(activeExercises.contains), isTrue);
      expect(dailyExercises(d), chosen);
    }
  });
  test('v1 database upgrades without deleting archived history', () async {
    final folder = await Directory.systemTemp.createTemp('oyla-migration-');
    final file = File('${folder.path}/old.sqlite');
    final old = OylaDatabase(NativeDatabase(file));
    await old.upsertResult(
      ExerciseResult(
        id: 'archived',
        type: ExerciseType.runningTotal,
        date: now,
        correct: 3,
        attempted: 5,
        score: 60,
      ),
    );
    for (final table in OylaDatabase.dayTables) {
      await old.customStatement('DROP TABLE $table');
    }
    await old.customStatement('PRAGMA user_version = 1');
    await old.close();
    final upgraded = OylaDatabase(NativeDatabase(file));
    expect(
      (await upgraded.allResults()).single.type,
      ExerciseType.runningTotal,
    );
    await upgraded.putDayRow('routines', 'guest', routine().toJson());
    expect((await upgraded.dayRows('routines', 'guest')).length, 1);
    await upgraded.close();
    await folder.delete(recursive: true);
  });
  test(
    'recommendations are optional and only acceptance changes future schedules',
    () async {
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
          dayClockProvider.overrideWithValue(() => now),
          apiProvider.overrideWithValue(GuestApi()),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);
      await container.read(appStateProvider.future);
      await container.read(dayProvider.future);
      final controller = container.read(dayProvider.notifier);
      await controller.saveRoutine(routine());
      for (var i = 0; i < 3; i++) {
        await db.putDayRow(
          'activity_events',
          'guest',
          event(i, 'POSTPONED').toJson(),
        );
      }
      await controller.initializeDay();
      final suggestion = container
          .read(dayProvider)
          .requireValue
          .recommendation!;
      expect(
        container.read(dayProvider).requireValue.routines.single.minute,
        540,
      );
      await controller.setSettings({'personalization': false});
      expect(container.read(dayProvider).requireValue.recommendation, isNull);
      await controller.setSettings({'personalization': true});
      await controller.recommendationShown(suggestion);
      await controller.recommendationShown(suggestion);
      await controller.decide(suggestion, true);
      await controller.decide(suggestion, true);
      final data = container.read(dayProvider).requireValue;
      expect(data.routines.single.minute, 840);
      expect(data.occurrences.single.routine.minute, 840);
      expect(
        data.events.where((e) => e.type == 'RECOMMENDATION_ACCEPTED').length,
        1,
      );
      expect(
        data.events.where((e) => e.type == 'RECOMMENDATION_SHOWN').length,
        1,
      );
    },
  );
  test(
    'schema upgrade retains old results and adds durable account-owned routines',
    () async {
      final executor = NativeDatabase.memory();
      final db = OylaDatabase(executor);
      addTearDown(db.close);
      final archived = ExerciseResult(
        id: 'old',
        type: ExerciseType.colorWord,
        date: now,
        correct: 2,
        attempted: 5,
        score: 40,
      );
      await db.upsertResult(archived);
      await db.putDayRow('routines', 'guest', routine().toJson());
      await db.claimGuestDay('accountA');
      expect(await db.dayRows('routines', 'guest'), isEmpty);
      expect(await db.dayRows('routines', 'accountB'), isEmpty);
      expect((await db.dayRows('routines', 'accountA')).length, 1);
      expect((await db.allResults()).single.type, ExerciseType.colorWord);
    },
  );
  test(
    'occurrence actions and events are atomic, restart-safe and idempotent',
    () async {
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
          dayClockProvider.overrideWithValue(() => now),
          apiProvider.overrideWithValue(GuestApi()),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);
      await container.read(appStateProvider.future);
      await container.read(dayProvider.future);
      final c = container.read(dayProvider.notifier);
      await c.saveRoutine(routine(kind: ActivityKind.walking));
      await c.initializeDay();
      await c.initializeDay();
      final id = container.read(dayProvider).requireValue.occurrences.single.id;
      await c.act(id, OccurrenceStatus.skipped);
      await c.act(id, OccurrenceStatus.started);
      expect(
        container.read(dayProvider).requireValue.occurrences.single.status,
        OccurrenceStatus.skipped,
      );
      await c.act(id, OccurrenceStatus.started, source: 'restart');
      expect(
        container.read(dayProvider).requireValue.occurrences.single.status,
        OccurrenceStatus.started,
      );
      await Future.wait([
        c.act(id, OccurrenceStatus.started),
        c.act(id, OccurrenceStatus.started),
      ]);
      await c.act(id, OccurrenceStatus.completed, minutes: 7);
      await c.act(id, OccurrenceStatus.completed, minutes: 7);
      expect(
        container.read(dayProvider).requireValue.events.map((e) => e.type),
        unorderedEquals(['SCHEDULED', 'SKIPPED', 'STARTED', 'COMPLETED']),
      );
      expect((await db.dayRows('movement_sessions', 'guest')).length, 1);
      container.invalidate(dayProvider);
      await container.read(dayProvider.future);
      expect(
        container.read(dayProvider).requireValue.occurrences.single.minutes,
        7,
      );
      await container
          .read(dayProvider.notifier)
          .act(id, OccurrenceStatus.skipped);
      expect(
        (await db.dayRows('occurrences', 'guest')).single['data']['status'],
        'completed',
      );
    },
  );
}
