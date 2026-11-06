import 'youtube.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'app_state.dart';
import 'database.dart';
import 'day_models.dart';
import 'models.dart';
import 'reminders.dart';

final dayClockProvider = Provider<DateTime Function()>((_) => DateTime.now);
final dayProvider = AsyncNotifierProvider<DayController, DayData>(
  DayController.new,
);

class DayData {
  const DayData({
    required this.owner,
    required this.routines,
    required this.occurrences,
    required this.events,
    required this.recommendations,
    required this.settings,
    required this.positions,
    required this.readingSessions,
    this.conflicts = const [],
  });
  final String owner;
  final List<Routine> routines;
  final List<DayOccurrence> occurrences;
  final List<ActivityEvent> events;
  final List<DayRecommendation> recommendations;
  final Map<String, dynamic> settings;
  final List<Map<String, dynamic>> positions, readingSessions, conflicts;
  bool get setup => settings['setup'] == true;
  bool get personalization => settings['personalization'] != false;
  List<DayOccurrence> today(DateTime now) =>
      occurrences
          .where(
            (o) =>
                !o.deleted &&
                (o.date == dayKey(now) ||
                    dayKey(o.displayTime) == dayKey(now) ||
                    (o.completedAt != null && o.activityDate == dayKey(now))),
          )
          .toList()
        ..sort((a, b) => a.displayTime.compareTo(b.displayTime));
  DayRecommendation? get recommendation => personalization
      ? recommendations.where((r) => r.decision == null).firstOrNull
      : null;
}

class DayController extends AsyncNotifier<DayData> {
  late OylaDatabase db;
  late String owner;
  Future<void> _pending = Future.value();
  Timer? _syncTimer;
  bool _disposed = false;
  String? _notificationStart;
  String? takeNotificationStart() {
    final id = _notificationStart;
    _notificationStart = null;
    return id;
  }

  Future<void> _serial(
    Future<void> Function() operation, {
    bool syncAfter = true,
  }) {
    final result = _pending.then((_) async {
      await operation();
      if (syncAfter &&
          !_disposed &&
          owner != 'guest' &&
          await _hasPendingUploads()) {
        _syncTimer?.cancel();
        _syncTimer = Timer(const Duration(seconds: 3), () {
          if (!_disposed) unawaited(sync().catchError((Object _) {}));
        });
      }
    });
    _pending = result.catchError((Object _) {});
    return result;
  }

  Future<bool> _hasPendingUploads() async {
    for (final table in OylaDatabase.dayTables) {
      if ((await db.dayRows(
        table,
        owner,
      )).any((r) => r['dirty'] == true && r['conflict'] == null)) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<DayData> build() async {
    ref.onDispose(() {
      _disposed = true;
      _syncTimer?.cancel();
    });
    db = ref.read(databaseProvider);
    final api = ref.read(apiProvider);
    owner = await api.isSignedIn()
        ? (await api.currentUserId() ?? 'guest')
        : 'guest';
    final data = await _read();
    return data;
  }

  Future<DayData> _read() async {
    final rows = <String, List<Map<String, dynamic>>>{};
    for (final table in OylaDatabase.dayTables) {
      rows[table] = await db.dayRows(table, owner);
    }
    List<Map<String, dynamic>> values(String table) =>
        rows[table]!.map((r) => Map<String, dynamic>.from(r['data'])).toList();
    return DayData(
      owner: owner,
      routines: values('routines').map(Routine.fromJson).toList(),
      occurrences: values('occurrences').map(DayOccurrence.fromJson).toList(),
      events: values('activity_events').map(ActivityEvent.fromJson).toList()
        ..sort((a, b) => a.at.compareTo(b.at)),
      recommendations: values(
        'recommendations',
      ).map(DayRecommendation.fromJson).toList(),
      settings: values('day_settings').firstOrNull ?? {'id': 'settings'},
      positions: values('reading_positions'),
      readingSessions: values('reading_sessions'),
      conflicts: [
        for (final entry in rows.entries)
          for (final row in entry.value)
            if (row['conflict'] != null) {...row, 'table': entry.key},
      ],
    );
  }

  Future<void> _refresh() async {
    state = AsyncData(await _read());
  }

  Future<void> _event(
    DayOccurrence o,
    String type, {
    String? id,
    DateTime? at,
    String? recommendationId,
  }) async {
    final now = at ?? ref.read(dayClockProvider)();
    await db.putDayRow(
      'activity_events',
      owner,
      ActivityEvent(
        id: id ?? const Uuid().v4(),
        activityId: o.id,
        routineId: o.routine.id,
        kind: o.routine.kind,
        type: type,
        at: now,
        scheduledAt: o.scheduledAt,
        startedAt: o.startedAt,
        completedAt: o.completedAt,
        duration: o.minutes,
        postponedTo: o.postponedTo,
        reminderSentAt: type == 'REMINDER_SENT' ? now : null,
        reminderOpenedAt: type == 'REMINDER_OPENED' ? now : null,
        recommendationId: recommendationId,
      ).toJson(),
    );
  }

  Future<void> initializeDay() => _serial(() async {
    var data = await _read();
    final now = ref.read(dayClockProvider)();
    final ids = data.occurrences.map((o) => o.id).toSet();
    await db.transaction(() async {
      for (final r in data.routines.where(
        (r) => !r.deleted && r.weekdays.contains(now.weekday),
      )) {
        final id = '${r.id}:${dayKey(now)}';
        if (ids.contains(id)) continue;
        final o = DayOccurrence(
          id: id,
          routine: r,
          date: dayKey(now),
          scheduledAt: atMinute(now, r.minute),
        );
        await db.putDayRow('occurrences', owner, o.toJson());
        await _event(o, 'SCHEDULED', id: '$id:SCHEDULED');
      }
    });
    await _refresh();
    await _importNotifications();
    data = await _read();
    // A stale proposal is retired, never applied silently.
    for (final r in data.recommendations.where((r) => r.decision == null)) {
      final routine = data.routines
          .where((v) => v.id == r.routineId && !v.deleted)
          .firstOrNull;
      if (routine == null ||
          jsonEncode(routine.toJson()) != jsonEncode(r.basis)) {
        await db.putDayRow('recommendations', owner, {
          ...r.toJson(),
          'decision': 'expired',
          'decidedAt': now.toIso8601String(),
        });
      }
    }
    data = await _read();
    if (data.personalization && data.recommendation == null) {
      final suggestion = recommend(
        data.routines,
        data.events,
        data.recommendations,
        now,
      ).firstOrNull;
      if (suggestion != null) {
        await db.putDayRow('recommendations', owner, suggestion.toJson());
      }
    }
    await _refresh();
    await _schedule();
  });
  Future<void> setSettings(Map<String, dynamic> updates) => _serial(() async {
    final data = await _read();
    await db.putDayRow('day_settings', owner, {
      ...data.settings,
      ...updates,
      'id': 'settings',
    });
    await _refresh();
  });
  Future<void> saveRoutine(Routine routine) => _serial(() async {
    await _saveRoutine(routine);
    if (isMovement(routine.kind)) {
      final data = await _read();
      await db.putDayRow('day_settings', owner, {
        ...data.settings,
        'id': 'settings',
        'movementPreferences': {
          'kinds': data.routines
              .where((r) => !r.deleted && isMovement(r.kind))
              .map((r) => r.kind.name)
              .toSet()
              .toList(),
          'duration': routine.duration,
          'preferredMinute': routine.minute,
        },
      });
    }
    await _refresh();
    await _schedule();
  });
  void _validateRoutine(Routine routine, DayData data) {
    if (routine.deleted) return;
    if (data.routines.any(
      (r) => r.id != routine.id && !r.deleted && routinesOverlap(routine, r),
    )) {
      throw const ActivityScheduleException(
        'Activities cannot overlap. Choose another time.',
        'Әрекеттер қабаттаспау керек. Басқа уақыт таңдаңыз.',
        'Занятия не должны пересекаться. Выберите другое время.',
      );
    }
  }

  Future<void> _saveRoutine(Routine routine) async {
    final data = await _read();
    _validateRoutine(routine, data);
    if (!routine.deleted) {
      final now = ref.read(dayClockProvider)();
      for (var offset = 0; offset < 7; offset++) {
        final date = DateTime(now.year, now.month, now.day + offset);
        if (!routine.weekdays.contains(date.weekday)) continue;
        final candidate = DayOccurrence(
          id: '${routine.id}:${dayKey(date)}',
          routine: routine,
          date: dayKey(date),
          scheduledAt: atMinute(date, routine.minute),
        );
        // Validate actual postponed occurrences as well as the repeating schedule.
        final actual = data.occurrences.where(
          (o) => o.routine.id != routine.id && !o.deleted && !o.terminal,
        );
        if (actual.any(
          (o) =>
              candidate.scheduledAt.isBefore(
                o.displayTime.add(Duration(minutes: o.routine.duration)),
              ) &&
              o.displayTime.isBefore(
                candidate.scheduledAt.add(Duration(minutes: routine.duration)),
              ),
        )) {
          throw const ActivityScheduleException(
            'Activities cannot overlap. Choose another time.',
            'Әрекеттер қабаттаспау керек. Басқа уақыт таңдаңыз.',
            'Занятия не должны пересекаться. Выберите другое время.',
          );
        }
      }
    }
    await db.transaction(() async {
      await db.putDayRow('routines', owner, routine.toJson());
      final today = dayKey(ref.read(dayClockProvider)());
      for (final o in data.occurrences.where(
        (o) =>
            o.routine.id == routine.id &&
            !o.deleted &&
            !o.terminal &&
            o.status != OccurrenceStatus.started &&
            o.date.compareTo(today) >= 0,
      )) {
        final date = DateTime.parse(o.date);
        await db.putDayRow('occurrences', owner, {
          ...o.toJson(),
          'routine': routine.toJson(),
          'scheduledAt': atMinute(date, routine.minute).toIso8601String(),
          'postponedTo': null,
          'status': 'scheduled',
          'sessionVideo': null,
          'deleted':
              routine.deleted || !routine.weekdays.contains(date.weekday),
        });
      }
    });
  }

  Future<void> deleteOccurrence(String id) => _serial(() async {
    final o = (await _read()).occurrences.where((o) => o.id == id).firstOrNull;
    if (o == null || o.deleted) return;
    await db.putDayRow('occurrences', owner, {...o.toJson(), 'deleted': true});
    await _refresh();
    await _schedule();
  });

  Future<void> acknowledgeTimer(String id) => _serial(() async {
    final o = (await _read()).occurrences.where((o) => o.id == id).firstOrNull;
    if (o == null || o.deleted || o.terminal) return;
    await db.putDayRow('occurrences', owner, {
      ...o.toJson(),
      'timerAcknowledged': true,
    });
    await _refresh();
    await _schedule();
  });

  void _checkStart(DayOccurrence o, DayData data, DateTime now) {
    if (now.isBefore(o.displayTime)) {
      throw const ActivityScheduleException(
        'This activity has not started yet.',
        'Бұл әрекеттің уақыты әлі келген жоқ.',
        'Время этого занятия ещё не наступило.',
      );
    }
    if (data.occurrences.any(
      (v) => v.id != o.id && !v.deleted && v.status == OccurrenceStatus.started,
    )) {
      throw const ActivityScheduleException(
        'Finish the current activity first.',
        'Алдымен ағымдағы әрекетті аяқтаңыз.',
        'Сначала завершите текущее занятие.',
      );
    }
  }

  void _checkPostpone(DayOccurrence o, DayData data, DateTime time) {
    final end = time.add(Duration(minutes: o.routine.duration));
    final candidates = [
      ...data.occurrences.where(
        (v) => v.id != o.id && !v.deleted && !v.terminal,
      ),
    ];
    for (var offset = -1; offset <= 1; offset++) {
      final date = DateTime(time.year, time.month, time.day + offset);
      for (final r in data.routines.where(
        (r) => !r.deleted && r.weekdays.contains(date.weekday),
      )) {
        final id = '${r.id}:${dayKey(date)}';
        if (id == o.id || data.occurrences.any((v) => v.id == id)) continue;
        candidates.add(
          DayOccurrence(
            id: id,
            routine: r,
            date: dayKey(date),
            scheduledAt: atMinute(date, r.minute),
          ),
        );
      }
    }
    if (candidates.any(
      (v) =>
          time.isBefore(
            v.displayTime.add(Duration(minutes: v.routine.duration)),
          ) &&
          v.displayTime.isBefore(end),
    )) {
      throw const ActivityScheduleException(
        'Activities cannot overlap. Choose another time.',
        'Әрекеттер қабаттаспау керек. Басқа уақыт таңдаңыз.',
        'Занятия не должны пересекаться. Выберите другое время.',
      );
    }
  }

  Future<void> saveSessionVideo(String id, YouTubeVideo video) =>
      _serial(() async {
        final data = await _read();
        final o = data.occurrences.where((v) => v.id == id).firstOrNull;
        if (o == null || o.deleted || o.terminal) return;
        if (!o.routine.youtubeChannels.any((c) => c.id == video.channelId) ||
            video.seconds < o.routine.duration * 60) {
          throw ArgumentError('Video does not match this activity');
        }
        await db.putDayRow(
          'occurrences',
          owner,
          o
              .transition(
                o.status,
                ref.read(dayClockProvider)(),
                sessionVideo: video,
              )
              .toJson(),
        );
        await _refresh();
      });

  Future<void> act(
    String id,
    OccurrenceStatus next, {
    int? minutes,
    DateTime? postponedTo,
    String source = 'manual',
    String? eventId,
  }) => _serial(() async {
    final data = await _read();
    final o = data.occurrences.where((o) => o.id == id).firstOrNull;
    if (o == null ||
        o.deleted ||
        (o.terminal &&
            !(o.status == OccurrenceStatus.skipped &&
                next == OccurrenceStatus.started &&
                source == 'restart')) ||
        (o.status == next && next != OccurrenceStatus.postponed)) {
      return;
    }
    final requestedMinutes = minutes;
    if (requestedMinutes != null &&
        (requestedMinutes < 0 || requestedMinutes > 1440)) {
      throw ArgumentError('Invalid duration');
    }
    if (next == OccurrenceStatus.postponed &&
        (postponedTo == null ||
            !postponedTo.isAfter(ref.read(dayClockProvider)()))) {
      return;
    }
    final now = ref.read(dayClockProvider)();
    if (next == OccurrenceStatus.started) _checkStart(o, data, now);
    if (next == OccurrenceStatus.postponed) {
      _checkPostpone(o, data, postponedTo!);
    }
    if (next == OccurrenceStatus.completed && minutes == null) {
      minutes = o.elapsedSeconds(now) ~/ 60;
    }
    final changed = o.transition(
      next,
      ref.read(dayClockProvider)(),
      minutes: minutes,
      postponedTo: postponedTo,
      source: source,
    );
    await db.transaction(() async {
      await db.putDayRow('occurrences', owner, changed.toJson());
      await _event(changed, next.name.toUpperCase(), id: eventId);
      if (next == OccurrenceStatus.completed && isMovement(o.routine.kind)) {
        await db.putDayRow('movement_sessions', owner, {
          'id': o.id,
          'occurrenceId': o.id,
          'kind': o.routine.kind.name,
          'minutes': minutes ?? 0,
          'completedAt': changed.completedAt!.toIso8601String(),
          'source': source,
        });
      }
    });
    await _refresh();
    await _schedule();
  });
  Future<void> recordExercise(ExerciseResult result) => _serial(() async {
    final id = 'exercise:${result.id}';
    final existing = (await _read()).events.map((e) => e.id).toSet();
    await db.transaction(() async {
      for (final type in ['STARTED', 'COMPLETED']) {
        if (existing.contains('$id:$type')) continue;
        await db.putDayRow(
          'activity_events',
          owner,
          ActivityEvent(
            id: '$id:$type',
            activityId: id,
            routineId: 'practice:${result.type.name}',
            kind: ActivityKind.cognitive,
            type: type,
            at: type == 'STARTED'
                ? result.startedAt ?? result.date
                : result.date,
            startedAt: result.startedAt,
            completedAt: type == 'COMPLETED' ? result.date : null,
            duration: result.startedAt == null
                ? 0
                : result.date
                      .difference(result.startedAt!)
                      .inMinutes
                      .clamp(0, 1440),
          ).toJson(),
        );
      }
    });
    await _refresh();
  });
  Future<void> recordReading({
    required String sessionId,
    required String bookId,
    required int position,
    required int total,
    required int seconds,
    required String mode,
    bool finished = false,
  }) => _serial(() async {
    if (seconds < 0 || position < 0 || total <= 0) return;
    final events = (await _read()).events.map((e) => e.id).toSet();
    await db.transaction(() async {
      for (final type in ['STARTED', if (finished) 'COMPLETED']) {
        final id = '$sessionId:$type';
        if (!events.contains(id)) {
          await db.putDayRow(
            'activity_events',
            owner,
            ActivityEvent(
              id: id,
              activityId: sessionId,
              routineId: 'reading:$bookId',
              kind: ActivityKind.reading,
              type: type,
              at: ref.read(dayClockProvider)(),
              startedAt: ref
                  .read(dayClockProvider)()
                  .subtract(Duration(seconds: seconds)),
              completedAt: type == 'COMPLETED'
                  ? ref.read(dayClockProvider)()
                  : null,
              duration: seconds ~/ 60,
            ).toJson(),
          );
        }
      }
      await db.putDayRow('reading_positions', owner, {
        'id': bookId,
        'bookId': bookId,
        'chapter': 1,
        'position': position,
        'progress': (position / total).clamp(0, 1),
        'updatedAt': ref.read(dayClockProvider)().toIso8601String(),
      });
      await db.putDayRow('reading_sessions', owner, {
        'id': sessionId,
        'bookId': bookId,
        'seconds': seconds,
        'mode': mode,
        'completionPercent': (position / total * 100).clamp(0, 100),
        'date': dayKey(ref.read(dayClockProvider)()),
      });
    });
    await _refresh();
  });
  Future<void> saveModule(String table, Map<String, dynamic> value) =>
      _serial(() async {
        await db.transaction(() async {
          if (table == 'togyz_progress') {
            final previous = (await db.dayRows(
              table,
              owner,
            )).where((r) => r['id'] == value['id']).firstOrNull?['data'];
            final oldLesson = previous?['lesson'] as int? ?? 0;
            final oldPuzzles = (previous?['puzzles'] as List? ?? []).length;
            if ((value['lesson'] as int? ?? 0) > oldLesson ||
                (value['puzzles'] as List? ?? []).length > oldPuzzles) {
              await db.putDayRow(
                'activity_events',
                owner,
                ActivityEvent(
                  id: const Uuid().v4(),
                  activityId: const Uuid().v4(),
                  routineId: 'togyz',
                  kind: ActivityKind.togyz,
                  type: 'COMPLETED',
                  at: ref.read(dayClockProvider)(),
                ).toJson(),
              );
            }
          }
          await db.putDayRow(table, owner, value);
        });
        await _refresh();
      });

  Future<void> recordModuleSession(String mode, int seconds, int level) =>
      _serial(() async {
        final now = ref.read(dayClockProvider)();
        final id = const Uuid().v4();
        final active = (await _read()).occurrences
            .where(
              (o) =>
                  !o.deleted &&
                  o.activityDate == dayKey(now) &&
                  o.routine.kind == ActivityKind.music &&
                  o.status == OccurrenceStatus.started,
            )
            .firstOrNull;
        await db.transaction(() async {
          await db.putDayRow('music_sessions', owner, {
            'id': id,
            'mode': mode,
            'seconds': seconds,
            'level': level,
            'completedAt': now.toIso8601String(),
            'date': dayKey(now),
          });
          await db.putDayRow(
            'activity_events',
            owner,
            ActivityEvent(
              id: const Uuid().v4(),
              activityId: id,
              routineId: active?.routine.id ?? mode,
              startedAt: now.subtract(Duration(seconds: seconds)),
              kind: ActivityKind.music,
              type: 'COMPLETED',
              at: now,
              completedAt: now,
              duration: seconds ~/ 60,
            ).toJson(),
          );
        });
        await _refresh();
      });

  Future<void> recommendationShown(DayRecommendation recommendation) =>
      _serial(() async {
        final data = await _read();
        final id = '${recommendation.id}:shown';
        if (data.events.any((e) => e.id == id)) return;
        final routine = data.routines.firstWhere(
          (r) => r.id == recommendation.routineId,
        );
        final o = DayOccurrence(
          id: recommendation.routineId,
          routine: routine,
          date: dayKey(ref.read(dayClockProvider)()),
          scheduledAt: atMinute(ref.read(dayClockProvider)(), routine.minute),
        );
        await _event(
          o,
          'RECOMMENDATION_SHOWN',
          id: id,
          recommendationId: recommendation.id,
        );
        await _refresh();
      });
  Future<void> decide(DayRecommendation recommendation, bool accept) => _serial(
    () async {
      final data = await _read();
      final stored = data.recommendations
          .where((r) => r.id == recommendation.id && r.decision == null)
          .firstOrNull;
      final routine = data.routines
          .where((r) => r.id == recommendation.routineId && !r.deleted)
          .firstOrNull;
      if (stored == null || routine == null) return;
      final valid = jsonEncode(routine.toJson()) == jsonEncode(stored.basis);
      await db.transaction(() async {
        await db.putDayRow('recommendations', owner, {
          ...stored.toJson(),
          'decision': !valid
              ? 'expired'
              : accept
              ? 'accepted'
              : 'rejected',
          'decidedAt': ref.read(dayClockProvider)().toIso8601String(),
        });
        if (!valid) return;
        if (accept) {
          final changed = switch (stored.type) {
            'postponed' ||
            'time' => routine.copyWith(minute: stored.value as int),
            'duration' => routine.copyWith(duration: stored.value as int),
            'reminder' => routine.copyWith(reminder: false),
            'movement' => routine.copyWith(
              kind: ActivityKind.values.byName(stored.value as String),
            ),
            _ => routine,
          };
          await _saveRoutine(changed);
        }
        await _event(
          DayOccurrence(
            id: routine.id,
            routine: routine,
            date: dayKey(ref.read(dayClockProvider)()),
            scheduledAt: atMinute(ref.read(dayClockProvider)(), routine.minute),
          ),
          accept ? 'RECOMMENDATION_ACCEPTED' : 'RECOMMENDATION_REJECTED',
          recommendationId: stored.id,
        );
      });
      await _refresh();
      await _schedule();
    },
  );
  Future<void> _schedule() async {
    final data = await _read();
    final settings = ref.read(appStateProvider).requireValue.settings;
    if (!settings.remindersEnabled) {
      await ReminderService().cancelActivities();
      return;
    }
    final now = ref.read(dayClockProvider)();
    final items = <Map<String, dynamic>>[];
    final candidates = [...data.occurrences];
    for (var offset = 0; offset < 7; offset++) {
      final date = DateTime(now.year, now.month, now.day + offset);
      for (final r in data.routines.where(
        (r) => !r.deleted && r.weekdays.contains(date.weekday),
      )) {
        final id = '${r.id}:${dayKey(date)}';
        if (candidates.any((o) => o.id == id)) continue;
        candidates.add(
          DayOccurrence(
            id: id,
            routine: r,
            date: dayKey(date),
            scheduledAt: atMinute(date, r.minute),
          ),
        );
      }
    }
    for (final o in candidates.where(
      (o) =>
          !o.deleted &&
          !o.terminal &&
          o.status != OccurrenceStatus.started &&
          o.routine.reminder,
    )) {
      final time = o.displayTime;
      if (!time.isAfter(now) &&
          (now.difference(time).inHours >= 24 ||
              data.events.any(
                (e) =>
                    e.activityId == o.id &&
                    e.type == 'REMINDER_SENT' &&
                    !e.at.isBefore(time),
              ))) {
        continue;
      }
      final h = time.hour,
          start = settings.quietStartHour,
          end = settings.quietEndHour;
      if (start != end &&
          (start > end ? h >= start || h < end : h >= start && h < end)) {
        continue;
      }
      items.add({
        'id': o.id,
        'owner': owner,
        'title': o.routine.label(settings.language),
        'at': time.millisecondsSinceEpoch,
        'language': settings.language.name,
        'quietStart': start,
        'quietEnd': end,
      });
    }
    for (final o in data.occurrences.where(
      (o) =>
          !o.deleted &&
          o.status == OccurrenceStatus.started &&
          !o.timerAcknowledged &&
          o.startedAt != null,
    )) {
      final deadline = o.startedAt!.add(Duration(minutes: o.routine.duration));

      items.add({
        'id': o.id,
        'owner': owner,
        'title': o.routine.label(settings.language),
        'at': deadline.millisecondsSinceEpoch,
        'language': settings.language.name,
        'completion': true,
      });
    }
    await ReminderService().scheduleActivities(items);
  }

  Future<void> _importNotifications() async {
    final notifications = await ReminderService().pendingActions();
    for (final action in notifications) {
      if (action['owner'] != owner) continue;
      final data = await _read();
      final id = action['eventId'] as String;
      if (data.events.any((e) => e.id == id)) {
        await ReminderService().acknowledge(id);
        continue;
      }
      final occurrenceId = action['id'] as String;
      var o = data.occurrences.where((o) => o.id == occurrenceId).firstOrNull;
      if (o == null) {
        final split = occurrenceId.lastIndexOf(':');
        if (split < 0) continue;
        final routine = data.routines
            .where((r) => r.id == occurrenceId.substring(0, split))
            .firstOrNull;
        final date = DateTime.tryParse(occurrenceId.substring(split + 1));
        if (routine == null || date == null) continue;
        o = DayOccurrence(
          id: occurrenceId,
          routine: routine,
          date: dayKey(date),
          scheduledAt: atMinute(date, routine.minute),
        );
        await db.putDayRow('occurrences', owner, o.toJson());
        await _event(o, 'SCHEDULED', id: '$occurrenceId:SCHEDULED');
      }
      final type = action['type'] as String;
      if (o.deleted) {
        await ReminderService().acknowledge(id);
        continue;
      }
      if (type == 'REMINDER_OPENED') _notificationStart = occurrenceId;
      final at = DateTime.fromMillisecondsSinceEpoch(action['at'] as int);
      final next = switch (type) {
        'STARTED' => OccurrenceStatus.started,
        'SKIPPED' => OccurrenceStatus.skipped,
        'POSTPONED' => OccurrenceStatus.postponed,
        _ => null,
      };
      if (next != null && !o.terminal) {
        try {
          if (next == OccurrenceStatus.started) _checkStart(o, data, at);
          if (next == OccurrenceStatus.postponed) {
            _checkPostpone(o, data, at.add(const Duration(minutes: 30)));
          }
        } on ActivityScheduleException {
          await ReminderService().acknowledge(id);
          continue;
        }
        if (next == OccurrenceStatus.started) _notificationStart = occurrenceId;
        o = o.transition(
          next,
          at,
          postponedTo: next == OccurrenceStatus.postponed
              ? at.add(const Duration(minutes: 30))
              : null,
          source: 'notification',
        );
      }
      final changed = o;
      await db.transaction(() async {
        await db.putDayRow('occurrences', owner, changed.toJson());
        await _event(changed, type, id: id, at: at);
      });
      await ReminderService().acknowledge(id);
    }
  }

  Future<void> sync() => _serial(() async {
    if (owner == 'guest') return;
    final api = ref.read(apiProvider);
    final uploads = <Map<String, dynamic>>[];
    for (final table in OylaDatabase.dayTables) {
      for (final row in await db.dayRows(table, owner)) {
        if (row['dirty'] == true && row['conflict'] == null) {
          uploads.add({
            'kind': table,
            'id': row['id'],
            'revision': row['revision'],
            'payload': jsonEncode(row['data']),
          });
        }
      }
    }
    final response = await api.syncDayRecords(uploads);
    await db.transaction(() async {
      for (final raw in response['records'] as List<dynamic>) {
        final r = Map<String, dynamic>.from(raw);
        final table = r['kind'] as String;
        if (!OylaDatabase.dayTables.contains(table)) continue;
        final local = (await db.dayRows(
          table,
          owner,
        )).where((v) => v['id'] == r['id']).firstOrNull;
        final conflict = (response['conflicts'] as List<dynamic>).any(
          (c) => c['kind'] == table && c['id'] == r['id'],
        );
        if (conflict && local != null) {
          await db.customStatement(
            'UPDATE $table SET conflict=? WHERE owner=? AND id=?',
            [jsonEncode(r), owner, r['id']],
          );
        } else {
          await db.customStatement(
            'INSERT INTO $table (owner,id,payload,revision,dirty) VALUES (?,?,?,?,0) ON CONFLICT(owner,id) DO UPDATE SET payload=excluded.payload,revision=excluded.revision,dirty=0,conflict=NULL',
            [owner, r['id'], r['payload'], r['revision']],
          );
        }
      }
    });
    await _refresh();
    await _schedule();
  }, syncAfter: false);
  Future<void> resolveConflict(
    Map<String, dynamic> row,
    bool keepLocal,
  ) => _serial(() async {
    final table = row['table'] as String;
    if (!OylaDatabase.dayTables.contains(table)) return;
    final remote =
        jsonDecode(row['conflict'] as String) as Map<String, dynamic>;
    await db.customStatement(
      'UPDATE $table SET payload=?,revision=?,dirty=?,conflict=NULL WHERE owner=? AND id=?',
      [
        keepLocal ? jsonEncode(row['data']) : remote['payload'],
        remote['revision'],
        keepLocal ? 1 : 0,
        owner,
        row['id'],
      ],
    );
    await _refresh();
  });
}
