import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:oyla/src/app_state.dart';
import 'package:oyla/src/models.dart';
import 'package:oyla/src/screens.dart';
import 'package:oyla/src/database.dart';
import 'package:oyla/src/handwriting.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Word Garden offers only one of the shown words as an answer', () {
    final selectedPositions = <int>{};

    for (var seed = 0; seed < 100; seed++) {
      final challenge = Challenge.generate(
        ExerciseType.wordGarden,
        Random(seed),
      );
      final shownOptions = challenge.options
          .where((word) => challenge.preview!.contains(word))
          .toList();

      expect(shownOptions, [challenge.answer]);
      selectedPositions.add(challenge.options.indexOf(challenge.answer));
    }

    expect(selectedPositions.length, greaterThan(1));
  });

  test('challenge generators provide multiple variants', () {
    for (final entry in <ExerciseType, Set<String>>{
      ExerciseType.quickSums: {'addition', 'subtraction'},
      ExerciseType.wordGarden: {'word list'},
      ExerciseType.findTarget: {'requested symbol'},
    }.entries) {
      final variants = {
        for (var seed = 0; seed < 100; seed++)
          Challenge.generate(entry.key, Random(seed), 5).variant,
      };
      expect(variants, containsAll(entry.value));
    }
  });

  test('archived exercises cannot generate playable challenges', () {
    for (final type in [ExerciseType.runningTotal, ExerciseType.colorWord]) {
      expect(() => Challenge.generate(type, Random(7)), throwsUnsupportedError);
    }
  });

  testWidgets('daily workout starts each exercise with fresh state', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final container = _newContainer();
    addTearDown(container.dispose);
    await container.read(appStateProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: WorkoutScreen(
            practice: true,
            exerciseSequence: [
              ExerciseType.quickSums,
              ExerciseType.wordGarden,
              ExerciseType.picturePairs,
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Activity 1 of 3'), findsOneWidget);

    await tester.ensureVisible(find.text('Type instead'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Type instead'));
    await tester.pump();
    for (var question = 0; question < 5; question++) {
      await tester.enterText(find.byType(TextField), '0');
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Check answer'),
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Check answer'));
      await tester.pump(const Duration(milliseconds: 800));
    }
    await tester.pumpAndSettle();

    expect(find.text('Activity 2 of 3'), findsOneWidget);
    expect(
      find.text('5 questions remaining').evaluate().isNotEmpty ||
          find.text('0 of 4 pairs found').evaluate().isNotEmpty,
      isTrue,
    );
  });

  testWidgets('Word Garden hides words before showing answer choices', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final container = _newContainer();
    addTearDown(container.dispose);
    await container.read(appStateProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: ExerciseScreen(
            type: ExerciseType.wordGarden,
            practice: true,
            position: 1,
            total: 1,
            onDone: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    final preview = find.textContaining(RegExp(r'^Remember .*\n\n'));
    expect(preview, findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);

    await tester.pump(const Duration(seconds: 4));

    expect(preview, findsNothing);
    expect(find.textContaining('Which word was'), findsOneWidget);
    expect(find.byType(FilledButton), findsNWidgets(4));
  });

  testWidgets('Find the Target shows a 3 by 3 choice grid', (tester) async {
    final container = await _initializedContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _exercise(container: container, type: ExerciseType.findTarget),
    );
    await tester.pump();

    expect(find.byType(FilledButton), findsNWidgets(9));
  });

  testWidgets('Quick Sums uses handwriting instead of answer choices', (
    tester,
  ) async {
    final container = await _initializedContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _exercise(container: container, type: ExerciseType.quickSums),
    );
    await tester.pump();

    expect(find.text('Quick Sums'), findsOneWidget);
    expect(find.byType(HandwritingPad), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
    expect(find.text('Check answer'), findsOneWidget);
    expect(find.text('Type instead'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('Quick Sums typed input is reachable on a small phone at 200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = await _initializedContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: ExerciseScreen(
            type: ExerciseType.quickSums,
            practice: true,
            position: 1,
            total: 1,
            onDone: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    final typeInstead = find.widgetWithText(TextButton, 'Type instead');
    await tester.scrollUntilVisible(
      typeInstead,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(typeInstead);
    await tester.pump();
    await tester.tap(typeInstead);
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Check answer'),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  for (final type in [
    ExerciseType.wordGarden,
    ExerciseType.picturePairs,
    ExerciseType.findTarget,
  ]) {
    testWidgets('${type.label} remains scrollable on a small phone at 200%', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = await _initializedContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: ExerciseScreen(
              type: type,
              practice: true,
              position: 1,
              total: 1,
              onDone: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      if (type == ExerciseType.wordGarden) {
        await tester.pump(const Duration(seconds: 5));
      }
      if (type == ExerciseType.picturePairs) {
        await tester.pump(const Duration(seconds: 5));
        await tester.scrollUntilVisible(
          find.widgetWithText(FilledButton, 'Done'),
          120,
          scrollable: find.byType(Scrollable).first,
        );
      } else {
        await tester.scrollUntilVisible(
          find.text('5 questions remaining'),
          120,
          scrollable: find.byType(Scrollable).first,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Picture Pairs previews four pairs and one unmatched symbol', (
    tester,
  ) async {
    final container = await _initializedContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _exercise(container: container, type: ExerciseType.picturePairs),
    );
    await tester.pump();

    expect(
      find.text('Memorize the cards. They will close shortly.'),
      findsOneWidget,
    );
    expect(find.text('?'), findsNothing);
    final previewTiles = tester.widgetList<FilledButton>(
      find.byType(FilledButton),
    );
    expect(
      previewTiles.where((button) => button.onPressed == null),
      hasLength(10),
    );

    await tester.pump(const Duration(seconds: 5));

    expect(find.text('?'), findsNWidgets(9));
    expect(find.text('0 of 4 pairs found'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Done'), findsOneWidget);
    final done = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Done'),
    );
    expect(done.onPressed, isNull);
  });

  testWidgets(
    'Picture Pairs completes after four pairs without selecting the unmatched symbol',
    (tester) async {
      final container = await _initializedContainer();
      addTearDown(container.dispose);
      await container
          .read(appStateProvider.notifier)
          .updateSettings(
            container
                .read(appStateProvider)
                .requireValue
                .settings
                .copyWith(sound: false, reducedMotion: true),
          );
      var completions = 0;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: ExerciseScreen(
              type: ExerciseType.picturePairs,
              practice: true,
              position: 1,
              total: 1,
              onDone: () => completions++,
            ),
          ),
        ),
      );
      await tester.pump();
      final cards = find.descendant(
        of: find.byType(GridView),
        matching: find.byType(FilledButton),
      );
      final symbols = tester
          .widgetList<FilledButton>(cards)
          .map((button) => (button.child as Text).data!)
          .toList();
      expect(symbols.length, 9);
      expect(symbols.toSet(), hasLength(5));
      await tester.pump(const Duration(seconds: 5));
      for (final symbol in symbols.toSet()) {
        if (symbols.where((s) => s == symbol).length != 2) continue;
        for (var i = 0; i < symbols.length; i++) {
          if (symbols[i] != symbol) continue;
          await tester.ensureVisible(cards.at(i));
          await tester.pump();
          await tester.tap(cards.at(i));
          await tester.pump();
        }
        await tester.pump(const Duration(seconds: 1));
      }
      final done = find.widgetWithText(FilledButton, 'Done');
      await tester.ensureVisible(done);
      await tester.pump();
      expect(tester.widget<FilledButton>(done).onPressed, isNotNull);
      await tester.tap(done);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(completions, 1);
      expect(
        container.read(appStateProvider).requireValue.results.single.correct,
        4,
      );
    },
  );

  testWidgets('an exercise can only complete once after rapid final taps', (
    tester,
  ) async {
    final container = await _initializedContainer();
    addTearDown(container.dispose);
    var completions = 0;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: ExerciseScreen(
            type: ExerciseType.quickSums,
            practice: true,
            position: 1,
            total: 1,
            onDone: () => completions++,
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Type instead'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Type instead'));
    await tester.pump();
    for (var question = 0; question < 4; question++) {
      await tester.enterText(find.byType(TextField), '0');
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Check answer'),
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Check answer'));
      await tester.pump(const Duration(milliseconds: 800));
    }
    await tester.enterText(find.byType(TextField), '0');
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Check answer'),
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Check answer'));
    await tester.tap(find.widgetWithText(FilledButton, 'Check answer'));
    await tester.pump(const Duration(milliseconds: 800));

    expect(completions, 1);
  });
}

Future<ProviderContainer> _initializedContainer() async {
  SharedPreferences.setMockInitialValues({});
  final container = _newContainer();
  await container.read(appStateProvider.future);
  return container;
}

ProviderContainer _newContainer() {
  const channel = MethodChannel('oyla/reminders');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(channel, (_) async => null);
  addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
  final database = OylaDatabase(NativeDatabase.memory());
  addTearDown(database.close);
  return ProviderContainer(
    overrides: [databaseProvider.overrideWithValue(database)],
  );
}

Widget _exercise({
  required ProviderContainer container,
  required ExerciseType type,
}) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp(
    home: ExerciseScreen(
      type: type,
      practice: true,
      position: 1,
      total: 1,
      onDone: () {},
    ),
  ),
);
