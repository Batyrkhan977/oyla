import 'dart:math';
import 'models.dart';
import 'youtube.dart';

String dayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
String clockText(int minute) =>
    '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';
DateTime atMinute(DateTime day, int minute) =>
    DateTime(day.year, day.month, day.day, minute ~/ 60, minute % 60);

enum ActivityKind {
  cognitive,
  reading,
  exercise,
  walking,
  taiChi,
  yoga,
  pilates,
  custom,
  personal,
  other,
  music,
  togyz,
  stretching,
  dance,
}

enum OccurrenceStatus { scheduled, started, completed, postponed, skipped }

bool isMovement(ActivityKind kind) => ![
  ActivityKind.cognitive,
  ActivityKind.reading,
  ActivityKind.custom,
  ActivityKind.personal,
  ActivityKind.other,
  ActivityKind.music,
  ActivityKind.togyz,
].contains(kind);

class Routine {
  const Routine({
    required this.id,
    required this.title,
    required this.kind,
    required this.weekdays,
    required this.minute,
    required this.duration,
    this.reminder = false,
    this.deleted = false,
    this.videoUrl,
    this.youtubeChannels = const [],
  });
  String label(AppLanguage language) =>
      [
            ActivityKind.custom,
            ActivityKind.personal,
            ActivityKind.other,
          ].contains(kind) &&
          !const [
            'My routine',
            'Моя рутина',
            'Менің күн тәртібім',
          ].contains(title)
      ? title
      : kindLabel(kind, language);
  final String id, title;
  final String? videoUrl;
  final List<YouTubeChannel> youtubeChannels;
  final ActivityKind kind;
  final List<int> weekdays;
  final int minute, duration;
  final bool reminder, deleted;
  Routine copyWith({
    int? minute,
    int? duration,
    bool? reminder,
    ActivityKind? kind,
    bool? deleted,
  }) => Routine(
    id: id,
    title: title,
    kind: kind ?? this.kind,
    weekdays: weekdays,
    minute: minute ?? this.minute,
    duration: duration ?? this.duration,
    reminder: reminder ?? this.reminder,
    deleted: deleted ?? this.deleted,
    videoUrl: kind != null && kind != this.kind ? null : videoUrl,
    youtubeChannels: kind != null && kind != this.kind
        ? const []
        : youtubeChannels,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'kind': kind.name,
    'weekdays': weekdays,
    'minute': minute,
    'duration': duration,
    'reminder': reminder,
    'deleted': deleted,
    if (videoUrl != null) 'videoUrl': videoUrl,
    'youtubeChannels': youtubeChannels.map((c) => c.toJson()).toList(),
  };
  factory Routine.fromJson(Map<String, dynamic> j) => Routine(
    id: j['id'],
    title: j['title'],
    kind: ActivityKind.values.byName(j['kind']),
    weekdays: List<int>.from(j['weekdays']),
    minute: j['minute'],
    duration: j['duration'],
    reminder: j['reminder'] ?? false,
    deleted: j['deleted'] ?? false,
    videoUrl: j['videoUrl'] as String?,
    youtubeChannels: (j['youtubeChannels'] as List? ?? [])
        .map(
          (c) => YouTubeChannel.fromJson(Map<String, dynamic>.from(c as Map)),
        )
        .toList(),
  );
}

class DayOccurrence {
  const DayOccurrence({
    required this.id,
    required this.routine,
    required this.date,
    required this.scheduledAt,
    this.status = OccurrenceStatus.scheduled,
    this.startedAt,
    this.completedAt,
    this.postponedTo,
    this.minutes = 0,
    this.source = 'manual',
    this.deleted = false,
    this.timerAcknowledged = false,
    this.sessionVideo,
  });
  final String id, date, source;
  final bool deleted, timerAcknowledged;
  int elapsedSeconds(DateTime now) => startedAt == null
      ? (status == OccurrenceStatus.completed ? minutes * 60 : 0)
      : (completedAt ?? now).difference(startedAt!).inSeconds.clamp(0, 86400);
  final YouTubeVideo? sessionVideo;
  final Routine routine;
  final DateTime scheduledAt;
  final DateTime? startedAt, completedAt, postponedTo;
  final OccurrenceStatus status;
  final int minutes;
  DateTime get displayTime => postponedTo ?? scheduledAt;
  String get activityDate => completedAt == null ? date : dayKey(completedAt!);
  bool get terminal =>
      status == OccurrenceStatus.completed ||
      status == OccurrenceStatus.skipped;
  DayOccurrence transition(
    OccurrenceStatus next,
    DateTime now, {
    int? minutes,
    DateTime? postponedTo,
    String? source,
    YouTubeVideo? sessionVideo,
  }) => DayOccurrence(
    id: id,
    routine: routine,
    date: date,
    scheduledAt: scheduledAt,
    status: next,
    startedAt: next == OccurrenceStatus.started
        ? (status == OccurrenceStatus.skipped ? now : startedAt ?? now)
        : startedAt,
    completedAt: next == OccurrenceStatus.completed ? now : completedAt,
    postponedTo: postponedTo ?? this.postponedTo,
    minutes: minutes ?? this.minutes,
    source: source ?? this.source,
    sessionVideo: sessionVideo ?? this.sessionVideo,
    deleted: deleted,
    timerAcknowledged:
        next == OccurrenceStatus.started && status == OccurrenceStatus.skipped
        ? false
        : timerAcknowledged,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'routine': routine.toJson(),
    'date': date,
    'scheduledAt': scheduledAt.toIso8601String(),
    'status': status.name,
    'startedAt': startedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'postponedTo': postponedTo?.toIso8601String(),
    'minutes': minutes,
    'source': source,
    'deleted': deleted,
    'timerAcknowledged': timerAcknowledged,
    if (sessionVideo != null) 'sessionVideo': sessionVideo!.toJson(),
  };
  factory DayOccurrence.fromJson(Map<String, dynamic> j) => DayOccurrence(
    id: j['id'],
    routine: Routine.fromJson(Map<String, dynamic>.from(j['routine'])),
    date: j['date'],
    scheduledAt: DateTime.parse(j['scheduledAt']),
    status: OccurrenceStatus.values.byName(j['status']),
    startedAt: DateTime.tryParse(j['startedAt'] ?? ''),
    completedAt: DateTime.tryParse(j['completedAt'] ?? ''),
    postponedTo: DateTime.tryParse(j['postponedTo'] ?? ''),
    minutes: j['minutes'] ?? 0,
    source: j['source'] ?? 'manual',
    deleted: j['deleted'] ?? false,
    timerAcknowledged: j['timerAcknowledged'] ?? false,
    sessionVideo: j['sessionVideo'] == null
        ? null
        : YouTubeVideo.fromJson(
            Map<String, dynamic>.from(j['sessionVideo'] as Map),
          ),
  );
}

class ActivityEvent {
  const ActivityEvent({
    required this.id,
    required this.activityId,
    required this.routineId,
    required this.kind,
    required this.type,
    required this.at,
    this.scheduledAt,
    this.startedAt,
    this.completedAt,
    this.duration = 0,
    this.postponedTo,
    this.reminderSentAt,
    this.reminderOpenedAt,
    this.recommendationId,
  });
  final String id, activityId, routineId, type;
  final ActivityKind kind;
  final DateTime at;
  final DateTime? scheduledAt,
      startedAt,
      completedAt,
      postponedTo,
      reminderSentAt,
      reminderOpenedAt;
  final int duration;
  final String? recommendationId;
  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': id,
    'activityId': activityId,
    'routineId': routineId,
    'activityType': kind.name,
    'eventType': type,
    'at': at.toIso8601String(),
    'dayOfWeek': at.weekday,
    'scheduledAt': scheduledAt?.toIso8601String(),
    'startedAt': startedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'duration': duration,
    'postponedTo': postponedTo?.toIso8601String(),
    'reminderSentAt': reminderSentAt?.toIso8601String(),
    'reminderOpenedAt': reminderOpenedAt?.toIso8601String(),
    'recommendationId': recommendationId,
  };
  factory ActivityEvent.fromJson(Map<String, dynamic> j) => ActivityEvent(
    id: j['id'],
    activityId: j['activityId'],
    routineId: j['routineId'],
    kind: ActivityKind.values.byName(j['activityType']),
    type: j['eventType'],
    at: DateTime.parse(j['at']),
    scheduledAt: DateTime.tryParse(j['scheduledAt'] ?? ''),
    startedAt: DateTime.tryParse(j['startedAt'] ?? ''),
    completedAt: DateTime.tryParse(j['completedAt'] ?? ''),
    duration: j['duration'] ?? 0,
    postponedTo: DateTime.tryParse(j['postponedTo'] ?? ''),
    reminderSentAt: DateTime.tryParse(j['reminderSentAt'] ?? ''),
    reminderOpenedAt: DateTime.tryParse(j['reminderOpenedAt'] ?? ''),
    recommendationId: j['recommendationId'],
  );
}

class DayRecommendation {
  const DayRecommendation({
    required this.id,
    required this.routineId,
    required this.type,
    required this.value,
    required this.createdAt,
    required this.basis,
    this.decision,
    this.decidedAt,
  });
  final String id, routineId, type;
  final Object value;
  final Map<String, dynamic> basis;
  final DateTime createdAt;
  final String? decision;
  final DateTime? decidedAt;
  Map<String, dynamic> toJson() => {
    'id': id,
    'routineId': routineId,
    'type': type,
    'value': value,
    'createdAt': createdAt.toIso8601String(),
    'basis': basis,
    'decision': decision,
    'decidedAt': decidedAt?.toIso8601String(),
  };
  factory DayRecommendation.fromJson(Map<String, dynamic> j) =>
      DayRecommendation(
        id: j['id'],
        routineId: j['routineId'],
        type: j['type'],
        value: j['value'],
        createdAt: DateTime.parse(j['createdAt']),
        basis: Map<String, dynamic>.from(j['basis']),
        decision: j['decision'],
        decidedAt: DateTime.tryParse(j['decidedAt'] ?? ''),
      );
}

/// Local, deterministic suggestions. No rule mutates routines.
List<DayRecommendation> recommend(
  List<Routine> routines,
  List<ActivityEvent> events,
  List<DayRecommendation> history,
  DateTime now,
) {
  final recent = events
      .where(
        (e) =>
            !e.at.isBefore(now.subtract(const Duration(days: 28))) &&
            !e.at.isAfter(now),
      )
      .toList();
  final proposals = <DayRecommendation>[];
  void add(Routine r, String type, Object value) {
    final id = '${r.id}:$type:$value';
    if (history.any(
      (h) =>
          h.id.startsWith('$id:') &&
          (h.decision == null ||
              (h.decidedAt ?? h.createdAt).isAfter(
                now.subtract(const Duration(days: 14)),
              )),
    )) {
      return;
    }
    proposals.add(
      DayRecommendation(
        id: '$id:${now.millisecondsSinceEpoch}',
        routineId: r.id,
        type: type,
        value: value,
        createdAt: now,
        basis: r.toJson(),
      ),
    );
  }

  int? cluster(List<DateTime> dates, int minimum) {
    if (dates.length < minimum) return null;
    final minutes = dates.map((d) => d.hour * 60 + d.minute).toList()..sort();
    List<int> best = [];
    for (final start in minutes) {
      final group = minutes
          .where((v) => v >= start && v <= start + 60)
          .toList();
      if (group.length > best.length) best = group;
    }
    if (best.length < (minimum == 3 ? 3 : 1) ||
        best.length / dates.length < .7) {
      return null;
    }
    return (best[best.length ~/ 2] / 15).round() * 15 % 1440;
  }

  for (final r in routines.where((r) => !r.deleted)) {
    final own = recent.where((e) => e.routineId == r.id).toList();
    final postponed = cluster(
      own
          .where((e) => e.type == 'POSTPONED' && e.postponedTo != null)
          .map((e) => e.postponedTo!)
          .toList(),
      3,
    );
    if (postponed != null && (postponed - r.minute).abs() >= 30) {
      add(r, 'postponed', postponed);
    }
    final completions = own.where((e) => e.type == 'COMPLETED').toList();
    final preferred = cluster(
      completions
          .where((e) => e.startedAt != null)
          .map((e) => e.startedAt!)
          .toList(),
      5,
    );
    if (preferred != null && (preferred - r.minute).abs() >= 30) {
      add(r, 'time', preferred);
    }
    final partial =
        completions
            .where((e) => e.duration > 0 && e.duration < r.duration * .75)
            .map((e) => e.duration)
            .toList()
          ..sort();
    if (partial.length >= 3 &&
        partial.length / max(1, completions.length) >= .7) {
      add(r, 'duration', max(1, partial[partial.length ~/ 2]));
    }
    final sent = own.where(
      (e) =>
          e.type == 'REMINDER_SENT' &&
          e.at.isBefore(now.subtract(const Duration(hours: 2))),
    );
    final ignored = sent.where(
      (e) => !own.any(
        (o) =>
            o.activityId == e.activityId &&
            ['REMINDER_OPENED', 'STARTED'].contains(o.type) &&
            !o.at.isBefore(e.at) &&
            o.at.isBefore(e.at.add(const Duration(hours: 2))),
      ),
    );
    if (r.reminder &&
        ignored.length >= 5 &&
        ignored.length / max(1, sent.length) >= .7) {
      add(r, 'reminder', false);
    }
    if (isMovement(r.kind)) {
      final movement = recent
          .where((e) => e.type == 'COMPLETED' && isMovement(e.kind))
          .toList();
      for (final kind in ActivityKind.values.where(isMovement)) {
        if (kind != r.kind &&
            movement.length >= 5 &&
            movement.where((e) => e.kind == kind).length / movement.length >=
                .7) {
          add(r, 'movement', kind.name);
        }
      }
    }
  }
  const priority = ['postponed', 'time', 'duration', 'reminder', 'movement'];
  proposals.sort((a, b) {
    final p = priority.indexOf(a.type).compareTo(priority.indexOf(b.type));
    return p != 0 ? p : a.routineId.compareTo(b.routineId);
  });
  return proposals;
}

String localized(AppLanguage language, String en, String kk, String ru) =>
    switch (language) {
      AppLanguage.english => en,
      AppLanguage.kazakh => kk,
      AppLanguage.russian => ru,
    };
String kindLabel(ActivityKind kind, AppLanguage l) => switch (kind) {
  ActivityKind.cognitive => localized(
    l,
    'Cognitive workout',
    'Ақыл-ой жаттығуы',
    'Умственная тренировка',
  ),
  ActivityKind.reading => localized(l, 'Reading', 'Оқу', 'Чтение'),
  ActivityKind.exercise => localized(l, 'Exercise', 'Жаттығу', 'Зарядка'),
  ActivityKind.walking => localized(l, 'Walking', 'Серуен', 'Прогулка'),
  ActivityKind.taiChi => localized(l, 'Tai chi', 'Тай-чи', 'Тай-чи'),
  ActivityKind.yoga => localized(l, 'Yoga', 'Йога', 'Йога'),
  ActivityKind.pilates => localized(l, 'Pilates', 'Пилатес', 'Пилатес'),
  ActivityKind.personal => localized(l, 'Personal', 'Жеке', 'Личное'),
  ActivityKind.other => localized(l, 'Other', 'Басқа', 'Другое'),
  ActivityKind.music => localized(l, 'Music', 'Музыка', 'Музыка'),
  ActivityKind.togyz => localized(l, 'Togyz', 'Тоғызқұмалақ', 'Тогызкумалак'),
  ActivityKind.stretching => localized(l, 'Stretching', 'Созылу', 'Растяжка'),
  ActivityKind.dance => localized(l, 'Dance', 'Би', 'Танцы'),
  ActivityKind.custom => localized(
    l,
    'New routine',
    'Жаңа әрекет',
    'Новое занятие',
  ),
};

class ActivityScheduleException implements Exception {
  const ActivityScheduleException(this.en, this.kk, this.ru);
  final String en, kk, ru;
  String label(AppLanguage language) => localized(language, en, kk, ru);
}

bool routinesOverlap(Routine a, Routine b) {
  const week = 7 * 1440;
  for (final ad in a.weekdays) {
    for (final bd in b.weekdays) {
      final start = (ad - 1) * 1440 + a.minute;
      final other = (bd - 1) * 1440 + b.minute;
      for (final shift in [-week, 0, week]) {
        if (start < other + shift + b.duration &&
            other + shift < start + a.duration) {
          return true;
        }
      }
    }
  }
  return false;
}
