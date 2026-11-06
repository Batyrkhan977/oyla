import 'package:flutter_test/flutter_test.dart';
import 'package:oyla/src/models.dart';
import 'package:oyla/src/app_state.dart';

void main() {
  test('text sizes preserve legacy preferences and survive persistence', () {
    expect(
      UserSettings.fromJson({'largeText': false}).textSize,
      TextSize.normal,
    );
    expect(
      UserSettings.fromJson({'largeText': true}).textSize,
      TextSize.larger,
    );
    final settings = const UserSettings().copyWith(textSize: TextSize.largest);
    expect(UserSettings.fromJson(settings.toJson()).textSize, TextSize.largest);
    expect(settings.copyWith(sound: false).textSize, TextSize.largest);
    expect(settings.copyWith(largeText: false).textSize, TextSize.normal);
  });

  test('score prioritizes accuracy', () {
    final accurate = scoreRound(
      correct: 5,
      attempted: 5,
      elapsed: const Duration(seconds: 120),
      comfortableTime: const Duration(seconds: 60),
    );
    final fastWrong = scoreRound(
      correct: 2,
      attempted: 5,
      elapsed: const Duration(seconds: 10),
      comfortableTime: const Duration(seconds: 60),
    );
    expect(accurate, greaterThan(fastWrong));
  });

  test('daily workout contains three unique exercises', () {
    final exercises = dailyExercises(DateTime(2026, 8, 15));
    expect(exercises, hasLength(3));
    expect(exercises.toSet(), hasLength(3));
    expect(dailyExercises(DateTime(2026, 8, 15)), exercises);
  });

  test('workout lengths select two, three, or four unique activities', () {
    final date = DateTime(2026, 8, 15);
    for (final length in WorkoutLength.values) {
      final exercises = dailyExercises(date, count: length.activityCount);
      expect(exercises, hasLength(length.activityCount));
      expect(exercises.toSet(), hasLength(length.activityCount));
    }
  });

  test('workout length defaults safely for existing and unknown settings', () {
    expect(
      UserSettings.fromJson(const {}).workoutLength,
      WorkoutLength.regular,
    );
    expect(
      UserSettings.fromJson(const {
        'workoutLength': 'futureValue',
      }).workoutLength,
      WorkoutLength.regular,
    );
  });

  test('Quick Sums keeps the stable sync identifier', () {
    expect(ExerciseType.quickSums.name, 'quickSums');
    expect(ExerciseType.quickSums.label, 'Quick Sums');
    expect(ExerciseType.quickSums.instruction, 'Write the answer to each sum.');
  });

  test('renamed exercises keep their stable sync identifiers', () {
    expect(ExerciseType.runningTotal.name, 'runningTotal');
    expect(ExerciseType.runningTotal.label, 'Low to High');
    expect(ExerciseType.colorWord.name, 'colorWord');
    expect(ExerciseType.colorWord.label, 'Color Word');
  });

  test('difficulty changes by one after three rounds', () {
    ExerciseResult result(int correct, int difficulty, int day) =>
        ExerciseResult(
          type: ExerciseType.quickSums,
          date: DateTime(2026, 8, day),
          correct: correct,
          attempted: 5,
          score: correct * 20,
          difficulty: difficulty,
        );

    expect(
      nextDifficulty([
        result(5, 2, 1),
        result(5, 2, 2),
      ], ExerciseType.quickSums),
      2,
    );
    expect(
      nextDifficulty([
        result(5, 2, 1),
        result(5, 2, 2),
        result(5, 2, 3),
      ], ExerciseType.quickSums),
      3,
    );
    expect(
      nextDifficulty([
        result(1, 2, 1),
        result(2, 2, 2),
        result(1, 2, 3),
      ], ExerciseType.quickSums),
      1,
    );
  });

  test('practice results do not complete the daily workout', () {
    final now = DateTime.now();
    final results = ExerciseType.values
        .take(3)
        .map(
          (type) => ExerciseResult(
            type: type,
            date: now,
            correct: 5,
            attempted: 5,
            score: 100,
            practice: true,
          ),
        )
        .toList();
    expect(
      AppData(settings: const UserSettings(), results: results).completedToday,
      isFalse,
    );
  });

  test(
    'legacy short preference cannot complete a workout after two activities',
    () {
      final now = DateTime.now();
      final results = ExerciseType.values
          .take(2)
          .map(
            (type) => ExerciseResult(
              type: type,
              date: now,
              correct: 5,
              attempted: 5,
              score: 100,
            ),
          )
          .toList();
      expect(
        AppData(
          settings: const UserSettings(workoutLength: WorkoutLength.short),
          results: results,
        ).completedToday,
        isFalse,
      );
    },
  );

  test('Picture Pairs preview shortens as difficulty increases', () {
    expect(picturePairsPreviewDuration(1), const Duration(seconds: 5));
    expect(picturePairsPreviewDuration(3), const Duration(seconds: 4));
    expect(picturePairsPreviewDuration(5), const Duration(seconds: 3));
    expect(picturePairsPreviewDuration(7), const Duration(seconds: 2));
    expect(picturePairsPreviewDuration(10), const Duration(seconds: 2));
  });
}
