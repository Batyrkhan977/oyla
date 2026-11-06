import 'dart:math';
import 'package:uuid/uuid.dart';

enum ExerciseType {
  quickSums,
  wordGarden,
  picturePairs,
  findTarget,
  runningTotal,
  colorWord,
}

// Archived enum values remain decodable for historical data only.
const activeExercises = [
  ExerciseType.quickSums,
  ExerciseType.wordGarden,
  ExerciseType.picturePairs,
  ExerciseType.findTarget,
];

enum AppLanguage { english, kazakh, russian }

enum AnswerInput { handwriting, keypad }

enum WorkoutLength { short, regular, extended }

extension WorkoutLengthDetails on WorkoutLength {
  String get label => switch (this) {
    WorkoutLength.short => 'Short',
    WorkoutLength.regular => 'Regular',
    WorkoutLength.extended => 'Extended',
  };

  int get activityCount => switch (this) {
    WorkoutLength.short => 2,
    WorkoutLength.regular => 3,
    WorkoutLength.extended => 4,
  };

  String get durationLabel => switch (this) {
    WorkoutLength.short => 'about 3–5 minutes',
    WorkoutLength.regular => 'about 5–10 minutes',
    WorkoutLength.extended => 'about 10–15 minutes',
  };
}

extension ExerciseTypeLabel on ExerciseType {
  String get label => switch (this) {
    ExerciseType.quickSums => 'Quick Sums',
    ExerciseType.wordGarden => 'Word Garden',
    ExerciseType.picturePairs => 'Picture Pairs',
    ExerciseType.findTarget => 'Find the Target',
    ExerciseType.runningTotal => 'Low to High',
    ExerciseType.colorWord => 'Color Word',
  };

  String get instruction => switch (this) {
    ExerciseType.quickSums => 'Write the answer to each sum.',
    ExerciseType.wordGarden => 'Remember the words, then find them again.',
    ExerciseType.picturePairs => 'Find all of the matching pairs.',
    ExerciseType.findTarget => 'Find the requested symbol.',
    ExerciseType.runningTotal =>
      'Memorize the numbers, then tap them from low to high.',
    ExerciseType.colorWord => 'Choose the ink color, not the word.',
  };
}

enum TextSize { normal, larger, largest }

class UserSettings {
  const UserSettings({
    this.onboardingComplete = false,
    bool largeText = true,
    TextSize? textSize,
    this.highContrast = false,
    this.reducedMotion = false,
    this.narration = false,
    this.sound = true,
    this.remindersEnabled = false,
    this.reminderHour = 9,
    this.workoutLength = WorkoutLength.regular,
    this.language = AppLanguage.english,
    this.answerInput = AnswerInput.handwriting,
    this.disabledExercises = const {},
    this.reminderHours = const [9, 9, 9, 9, 9, 9, 9],
    this.quietStartHour = 21,
    this.quietEndHour = 8,
  }) : textSize = textSize ?? (largeText ? TextSize.larger : TextSize.normal);

  final bool onboardingComplete;
  final TextSize textSize;
  bool get largeText => textSize != TextSize.normal;
  final bool highContrast;
  final bool reducedMotion;
  final bool narration;
  final bool sound;
  final bool remindersEnabled;
  final int reminderHour;
  final WorkoutLength workoutLength;
  final AppLanguage language;
  final AnswerInput answerInput;
  final Set<ExerciseType> disabledExercises;

  /// Monday through Sunday. A null entry disables that weekday.
  final List<int?> reminderHours;
  final int quietStartHour;
  final int quietEndHour;

  List<ExerciseType> get enabledExercises => activeExercises;

  UserSettings copyWith({
    bool? onboardingComplete,
    bool? largeText,
    TextSize? textSize,
    bool? highContrast,
    bool? reducedMotion,
    bool? narration,
    bool? sound,
    bool? remindersEnabled,
    int? reminderHour,
    WorkoutLength? workoutLength,
    AppLanguage? language,
    AnswerInput? answerInput,
    Set<ExerciseType>? disabledExercises,
    List<int?>? reminderHours,
    int? quietStartHour,
    int? quietEndHour,
  }) => UserSettings(
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    textSize:
        textSize ??
        (largeText == null
            ? this.textSize
            : (largeText ? TextSize.larger : TextSize.normal)),
    highContrast: highContrast ?? this.highContrast,
    reducedMotion: reducedMotion ?? this.reducedMotion,
    narration: narration ?? this.narration,
    sound: sound ?? this.sound,
    remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    reminderHour: reminderHour ?? this.reminderHour,
    workoutLength: workoutLength ?? this.workoutLength,
    language: language ?? this.language,
    answerInput: answerInput ?? this.answerInput,
    disabledExercises: disabledExercises ?? this.disabledExercises,
    reminderHours: reminderHours ?? this.reminderHours,
    quietStartHour: quietStartHour ?? this.quietStartHour,
    quietEndHour: quietEndHour ?? this.quietEndHour,
  );

  Map<String, Object> toJson() => {
    'onboardingComplete': onboardingComplete,
    'largeText': largeText,
    'textSize': textSize.name,
    'highContrast': highContrast,
    'reducedMotion': reducedMotion,
    'narration': narration,
    'sound': sound,
    'remindersEnabled': remindersEnabled,
    'reminderHour': reminderHour,
    'workoutLength': workoutLength.name,
    'language': language.name,
    'answerInput': answerInput.name,
    'disabledExercises': disabledExercises.map((type) => type.name).toList(),
    'reminderHours': reminderHours,
    'quietStartHour': quietStartHour,
    'quietEndHour': quietEndHour,
  };

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
    onboardingComplete: json['onboardingComplete'] as bool? ?? false,
    largeText: json['largeText'] as bool? ?? true,
    textSize: TextSize.values
        .where((s) => s.name == json['textSize'])
        .firstOrNull,
    highContrast: json['highContrast'] as bool? ?? false,
    reducedMotion: json['reducedMotion'] as bool? ?? false,
    narration: json['narration'] as bool? ?? false,
    sound: json['sound'] as bool? ?? true,
    remindersEnabled: json['remindersEnabled'] as bool? ?? false,
    reminderHour: json['reminderHour'] as int? ?? 9,
    workoutLength: WorkoutLength.values.firstWhere(
      (value) => value.name == json['workoutLength'],
      orElse: () => WorkoutLength.regular,
    ),
    language: AppLanguage.values.firstWhere(
      (value) => value.name == json['language'],
      orElse: () => AppLanguage.english,
    ),
    answerInput: AnswerInput.values.firstWhere(
      (value) => value.name == json['answerInput'],
      orElse: () => AnswerInput.handwriting,
    ),
    disabledExercises: (json['disabledExercises'] as List<dynamic>? ?? const [])
        .map(
          (value) => ExerciseType.values
              .where((type) => type.name == value)
              .firstOrNull,
        )
        .whereType<ExerciseType>()
        .toSet(),
    reminderHours: _reminderHours(json),
    quietStartHour: json['quietStartHour'] as int? ?? 21,
    quietEndHour: json['quietEndHour'] as int? ?? 8,
  );

  static List<int?> _reminderHours(Map<String, dynamic> json) {
    final raw = json['reminderHours'] as List<dynamic>?;
    if (raw == null || raw.length != 7) {
      final legacy = json['reminderHour'] as int? ?? 9;
      return List<int?>.filled(7, legacy);
    }
    return raw.map((value) => value as int?).toList(growable: false);
  }
}

class ExerciseResult {
  ExerciseResult({
    String? id,
    required this.type,
    required this.date,
    required this.correct,
    required this.attempted,
    required this.score,
    this.practice = false,
    this.difficulty = 1,
    this.algorithmVersion = 1,
    this.startedAt,
    this.workoutId,
  }) : id = id ?? const Uuid().v4();
  final String id;
  final ExerciseType type;
  final DateTime date;
  final int correct;
  final int attempted;
  final int score;
  final bool practice;
  final int difficulty;
  final int algorithmVersion;
  final DateTime? startedAt;
  final String? workoutId;
  double get accuracy => attempted == 0 ? 0 : correct / attempted;

  Map<String, Object?> toJson() => {
    'id': id,
    'type': type.name,
    'date': date.toIso8601String(),
    'correct': correct,
    'attempted': attempted,
    'score': score,
    'practice': practice,
    'difficulty': difficulty,
    'algorithmVersion': algorithmVersion,
    'startedAt': startedAt?.toIso8601String(),
    'workoutId': workoutId,
  };
  factory ExerciseResult.fromJson(Map<String, dynamic> json) => ExerciseResult(
    id: json['id'] as String?,
    type: ExerciseType.values.byName(json['type'] as String),
    date: DateTime.parse(json['date'] as String),
    correct: json['correct'] as int,
    attempted: json['attempted'] as int,
    score: json['score'] as int,
    practice: json['practice'] as bool? ?? false,
    difficulty: json['difficulty'] as int? ?? 1,
    algorithmVersion: json['algorithmVersion'] as int? ?? 1,
    startedAt: json['startedAt'] == null
        ? null
        : DateTime.parse(json['startedAt'] as String),
    workoutId: json['workoutId'] as String?,
  );
}

int nextDifficulty(Iterable<ExerciseResult> history, ExerciseType type) {
  final rounds = history.where((result) => result.type == type).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  if (rounds.isEmpty) return 1;
  final current = rounds.first.difficulty;
  if (rounds.length < 3 || rounds.length % 3 != 0) return current;
  final recent = rounds.take(3);
  final accuracy =
      recent.map((result) => result.accuracy).reduce((a, b) => a + b) / 3;
  if (accuracy >= 0.85) return min(10, current + 1);
  if (accuracy < 0.55) return max(1, current - 1);
  return current;
}

int scoreRound({
  required int correct,
  required int attempted,
  required Duration elapsed,
  required Duration comfortableTime,
}) {
  if (attempted <= 0) return 0;
  final accuracy = correct / attempted;
  final pace = min(
    1.0,
    comfortableTime.inMilliseconds / max(1, elapsed.inMilliseconds),
  );
  return ((accuracy * 80) + (pace * 20)).round().clamp(0, 100);
}

List<ExerciseType> dailyExercises(
  DateTime date, {
  int count = 3,
  Iterable<ExerciseType>? available,
}) {
  final days =
      DateTime(date.year, date.month, date.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
  final all = [
    ...(available ?? activeExercises).where(activeExercises.contains),
  ];
  if (all.isEmpty) return const [];
  all.shuffle(Random(days));
  return all.take(count.clamp(1, all.length)).toList(growable: false);
}

Duration picturePairsPreviewDuration(int difficulty) =>
    Duration(seconds: max(2, 5 - (max(1, difficulty) - 1) ~/ 2));
