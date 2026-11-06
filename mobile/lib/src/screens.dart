import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'day_state.dart';
import 'day_models.dart';
import 'day_screens.dart';
import 'models.dart';
import 'api.dart';
import 'handwriting.dart';
import 'localization.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int page = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      (
        context.strings.text('welcomeTitle'),
        context.strings.text('welcomeBody'),
      ),
      (context.strings.text('paceTitle'), context.strings.text('paceBody')),
      (
        context.strings.text('wellnessTitle'),
        context.strings.text('wellnessBody'),
      ),
    ];
    final content = pages[page];
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      Icon(
                        Icons.spa_outlined,
                        size: 88,
                        color: Theme.of(context).colorScheme.primary,
                        semanticLabel: context.strings.text('oylaLeaf'),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        content.$1,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        content.$2,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      Semantics(
                        label: context.strings.format('pageOf', {
                          'page': page + 1,
                          'total': pages.length,
                        }),
                        child: LinearProgressIndicator(
                          value: (page + 1) / pages.length,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () async {
                          if (page < pages.length - 1) {
                            setState(() => page++);
                          } else {
                            if (context.mounted) {
                              context.go('/accessibility-setup');
                            }
                          }
                        },
                        child: Text(
                          page == pages.length - 1
                              ? context.strings.text('startGuest')
                              : context.strings.text('continue'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends MyDayScreen {
  const HomeScreen({super.key});
}

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({
    super.key,
    required this.practice,
    this.exerciseSequence,
    this.occurrenceId,
  });
  final String? occurrenceId;
  final bool practice;
  final List<ExerciseType>? exerciseSequence;
  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  int index = 0;
  bool completed = false;
  DateTime? repeatStartedAt;
  late final List<ExerciseType> exercises =
      widget.exerciseSequence ??
      dailyExercises(DateTime.now(), count: 3, available: activeExercises);

  @override
  void initState() {
    super.initState();
    if (widget.practice) return;
    final now = DateTime.now();
    final completedTypes = ref
        .read(appStateProvider)
        .requireValue
        .results
        .where(
          (result) =>
              !result.practice &&
              _belongsToSession(result) &&
              result.date.year == now.year &&
              result.date.month == now.month &&
              result.date.day == now.day,
        )
        .map((result) => result.type)
        .toSet();
    index = exercises.indexWhere((type) => !completedTypes.contains(type));
    if (index < 0) {
      index = 0;
      repeatStartedAt = now;
    }
  }

  bool _belongsToSession(ExerciseResult result) {
    if (widget.occurrenceId == null) {
      return repeatStartedAt == null || !result.date.isBefore(repeatStartedAt!);
    }
    final o = ref
        .read(dayProvider)
        .valueOrNull
        ?.occurrences
        .where((o) => o.id == widget.occurrenceId)
        .firstOrNull;
    return o?.startedAt != null && !result.date.isBefore(o!.startedAt!);
  }

  void _advance() {
    if (completed || !mounted) return;
    setState(() {
      if (index < exercises.length) index++;
      if (!widget.practice) {
        final now = DateTime.now();
        final completedTypes = ref
            .read(appStateProvider)
            .requireValue
            .results
            .where(
              (result) =>
                  !result.practice &&
                  _belongsToSession(result) &&
                  result.date.year == now.year &&
                  result.date.month == now.month &&
                  result.date.day == now.day,
            )
            .map((result) => result.type)
            .toSet();
        while (index < exercises.length &&
            completedTypes.contains(exercises[index])) {
          index++;
        }
      }
      completed = index >= exercises.length;
      if (completed && widget.occurrenceId != null) {
        unawaited(
          runDayAction(
            context,
            () => ref
                .read(dayProvider.notifier)
                .act(
                  widget.occurrenceId!,
                  OccurrenceStatus.completed,
                  source: 'workout',
                ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.occurrenceId != null) {
      final o = ref
          .watch(dayProvider)
          .valueOrNull
          ?.occurrences
          .where((o) => o.id == widget.occurrenceId)
          .firstOrNull;
      if (o?.status == OccurrenceStatus.completed) {
        return _WorkoutComplete(practice: widget.practice);
      }
      if (o == null || o.deleted || o.status != OccurrenceStatus.started) {
        return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
      }
    }
    if (index >= exercises.length) {
      return _WorkoutComplete(practice: widget.practice);
    }
    return ExerciseScreen(
      key: ValueKey(index),
      type: exercises[index],
      practice: widget.practice,
      position: index + 1,
      total: exercises.length,
      onDone: _advance,
    );
  }
}

class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appStateProvider).requireValue.settings;
    return Scaffold(
      appBar: AppBar(title: Text(context.strings.text('freePractice'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: settings.enabledExercises
            .map(
              (type) => Card(
                child: ListTile(
                  minTileHeight: 72,
                  title: Text(context.strings.exerciseLabel(type)),
                  subtitle: Text(context.strings.exerciseInstruction(type)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/practice/${type.name}'),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class ExerciseScreen extends ConsumerStatefulWidget {
  const ExerciseScreen({
    super.key,
    required this.type,
    required this.practice,
    required this.position,
    required this.total,
    required this.onDone,
  });
  final ExerciseType type;
  final bool practice;
  final int position;
  final int total;
  final VoidCallback onDone;
  @override
  ConsumerState<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends ConsumerState<ExerciseScreen> {
  int attempted = 0;
  int correct = 0;
  late final int difficulty;
  late DateTime started;
  late Challenge challenge;
  Timer? wordPreviewTimer;
  Timer? pairPreviewTimer;
  bool showingWordPreview = false;
  bool showingPairPreview = false;
  late final List<String> pairTiles;
  final Set<int> revealedPairTiles = {};
  final Set<int> matchedPairTiles = {};
  bool resolvingPair = false;
  bool completionInProgress = false;
  final handwritingController = HandwritingController();
  final typedAnswerController = TextEditingController();
  final handwritingRecognizer = HandwritingRecognizer();
  bool typingQuickCountAnswer = false;
  bool recognizingHandwriting = false;
  String? handwritingMessage;

  @override
  void initState() {
    super.initState();
    started = DateTime.now();
    difficulty = nextDifficulty(
      ref.read(appStateProvider).requireValue.results,
      widget.type,
    );
    typingQuickCountAnswer =
        ref.read(appStateProvider).requireValue.settings.answerInput ==
        AnswerInput.keypad;
    challenge = Challenge.generate(
      widget.type,
      Random(),
      difficulty,
      ref.read(appStateProvider).requireValue.settings.language,
    );
    pairTiles = _generatePairTiles(Random());
    _startWordPreview();
    _startPairPreview();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref
          .read(appStateProvider.notifier)
          .speak(
            OylaLocalizations(
              ref.read(appStateProvider).requireValue.settings.language,
            ).exerciseInstruction(widget.type),
          ),
    );
  }

  @override
  void dispose() {
    wordPreviewTimer?.cancel();
    pairPreviewTimer?.cancel();
    handwritingController.dispose();
    typedAnswerController.dispose();
    super.dispose();
  }

  void _startWordPreview() {
    wordPreviewTimer?.cancel();
    showingWordPreview = challenge.preview != null;
    if (!showingWordPreview) return;
    final previewDuration = Duration(
      seconds: max(2, 4 - (difficulty - 1) ~/ 3),
    );
    wordPreviewTimer = Timer(previewDuration, () {
      if (mounted) setState(() => showingWordPreview = false);
    });
  }

  void _startPairPreview() {
    if (widget.type != ExerciseType.picturePairs) return;
    showingPairPreview = true;
    pairPreviewTimer = Timer(picturePairsPreviewDuration(difficulty), () {
      if (!mounted) return;
      setState(() {
        showingPairPreview = false;
        started = DateTime.now();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == ExerciseType.picturePairs) {
      return _buildPicturePairs(context);
    }
    if (widget.type == ExerciseType.quickSums) {
      return _buildQuickCount(context);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(context.strings.exerciseLabel(widget.type)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(8),
          child: LinearProgressIndicator(value: attempted / 5),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              context.strings.format('activityOf', {
                'position': widget.position,
                'total': widget.total,
              }),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 12),
            Text(
              context.strings.exerciseInstruction(widget.type),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 28),
            Text(
              showingWordPreview ? challenge.preview! : challenge.prompt,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 28),
            if (showingWordPreview)
              Text(
                context.strings.text('choicesSoon'),
                textAlign: TextAlign.center,
              )
            else if (challenge.options.length == 9)
              SizedBox(height: 330, child: _answerChoices())
            else
              _answerChoices(),
            const SizedBox(height: 24),
            Text(
              context.strings.format('remaining', {'count': 5 - attempted}),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCount(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.strings.exerciseLabel(widget.type)),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(8),
        child: LinearProgressIndicator(value: attempted / 5),
      ),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            context.strings.format('activityOf', {
              'position': widget.position,
              'total': widget.total,
            }),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 12),
          Text(
            context.strings.exerciseInstruction(widget.type),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 28),
          Text(
            challenge.prompt,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: recognizingHandwriting
                ? null
                : () => setState(() {
                    typingQuickCountAnswer = !typingQuickCountAnswer;
                    handwritingMessage = null;
                    typedAnswerController.clear();
                    handwritingController.clear();
                  }),
            child: Text(
              typingQuickCountAnswer
                  ? context.strings.text('writeInstead')
                  : context.strings.text('typeInstead'),
            ),
          ),
          const SizedBox(height: 8),
          if (typingQuickCountAnswer)
            TextField(
              controller: typedAnswerController,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: context.strings.text('yourAnswer'),
              ),
              onSubmitted: (_) => _submitQuickCountAnswer(),
            )
          else
            HandwritingPad(controller: handwritingController),
          if (handwritingMessage != null) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(handwritingMessage!, textAlign: TextAlign.center),
            ),
          ],
          const SizedBox(height: 16),
          if (!typingQuickCountAnswer)
            OutlinedButton.icon(
              onPressed: recognizingHandwriting
                  ? null
                  : () {
                      handwritingController.clear();
                      setState(() => handwritingMessage = null);
                    },
              icon: const Icon(Icons.refresh),
              label: Text(context.strings.text('clear')),
            ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: recognizingHandwriting || completionInProgress
                ? null
                : _submitQuickCountAnswer,
            child: recognizingHandwriting
                ? const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : Text(context.strings.text('checkAnswer')),
          ),
          const SizedBox(height: 12),
          Text(
            context.strings.format('remaining', {'count': 5 - attempted}),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Future<void> _submitQuickCountAnswer() async {
    if (recognizingHandwriting || completionInProgress) return;
    String? answer;
    if (typingQuickCountAnswer) {
      answer = typedAnswerController.text.trim();
      if (answer.isEmpty) {
        setState(
          () => handwritingMessage = context.strings.text('enterAnswerFirst'),
        );
        return;
      }
    } else {
      if (!handwritingController.hasInk) {
        setState(
          () => handwritingMessage = context.strings.text('writeAnswerFirst'),
        );
        return;
      }
      setState(() {
        recognizingHandwriting = true;
        handwritingMessage = context.strings.text('readingAnswer');
      });
      answer = await handwritingRecognizer.recognize(
        handwritingController.strokes,
        handwritingController.size,
      );
      if (!mounted) return;
      setState(() => recognizingHandwriting = false);
      if (answer == null) {
        setState(
          () => handwritingMessage = context.strings.text('couldNotRead'),
        );
        return;
      }
    }

    handwritingController.clear();
    typedAnswerController.clear();
    setState(() => handwritingMessage = null);
    await _answer(answer);
  }

  Widget _answerChoices() {
    if (challenge.options.length == 9) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final tileWidth = (constraints.maxWidth - 24) / 3;
          final tileHeight = (constraints.maxHeight - 24) / 3;
          return GridView.count(
            crossAxisCount: 3,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: tileWidth / tileHeight,
            children: challenge.options
                .map(
                  (answer) => FilledButton.tonal(
                    onPressed: completionInProgress
                        ? null
                        : () => _answer(answer),
                    child: Text(answer, style: const TextStyle(fontSize: 24)),
                  ),
                )
                .toList(),
          );
        },
      );
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: challenge.options
          .map(
            (answer) => SizedBox(
              width: 140,
              height: 64,
              child: FilledButton.tonal(
                onPressed: completionInProgress ? null : () => _answer(answer),
                child: Text(
                  answer,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  List<String> _generatePairTiles(Random random) {
    const themes = [
      ['★', '●', '▲', '■', '◆', '☀', '☂', '♥', '☁', '♫'],
      ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'J', 'K'],
      ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
    ];
    final shuffled = [...themes[random.nextInt(themes.length)]]
      ..shuffle(random);
    final tiles = [
      for (final symbol in shuffled.take(4)) ...[symbol, symbol],
      shuffled[4],
    ]..shuffle(random);
    return tiles;
  }

  Widget _buildPicturePairs(BuildContext context) {
    final pairsFound = matchedPairTiles.length ~/ 2;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.strings.exerciseLabel(widget.type)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(8),
          child: LinearProgressIndicator(value: pairsFound / 4),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              context.strings.format('activityOf', {
                'position': widget.position,
                'total': widget.total,
              }),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 12),
            Text(
              context.strings.exerciseInstruction(widget.type),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Text(
              showingPairPreview
                  ? context.strings.text('memorizeCards')
                  : context.strings.format('pairsFound', {'count': pairsFound}),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 330,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tileWidth = (constraints.maxWidth - 24) / 3;
                  final tileHeight = (constraints.maxHeight - 24) / 3;
                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: tileWidth / tileHeight,
                    ),
                    itemCount: pairTiles.length,
                    itemBuilder: (context, index) {
                      final visible =
                          showingPairPreview ||
                          revealedPairTiles.contains(index) ||
                          matchedPairTiles.contains(index);
                      final enabled =
                          !showingPairPreview &&
                          !resolvingPair &&
                          !completionInProgress &&
                          !matchedPairTiles.contains(index);
                      final onPressed = enabled
                          ? () => _revealPairTile(index)
                          : null;
                      final label = matchedPairTiles.contains(index)
                          ? '${_symbolName(pairTiles[index])}, pair found'
                          : showingPairPreview
                          ? '${_symbolName(pairTiles[index])}, shown for memorizing'
                          : visible
                          ? '${_symbolName(pairTiles[index])}, revealed'
                          : context.strings.format('hiddenTile', {
                              'number': index + 1,
                            });
                      return Semantics(
                        label: label,
                        button: true,
                        enabled: enabled,
                        onTap: onPressed,
                        child: ExcludeSemantics(
                          child: FilledButton.tonal(
                            onPressed:
                                showingPairPreview ||
                                    resolvingPair ||
                                    completionInProgress ||
                                    matchedPairTiles.contains(index)
                                ? null
                                : () => _revealPairTile(index),
                            child: Text(
                              visible ? pairTiles[index] : '?',
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: matchedPairTiles.length == 8 && !completionInProgress
                  ? _completePicturePairs
                  : null,
              child: Text(context.strings.text('done')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _revealPairTile(int index) async {
    if (showingPairPreview || revealedPairTiles.contains(index)) return;
    setState(() => revealedPairTiles.add(index));
    if (revealedPairTiles.length < 2) return;

    attempted++;
    resolvingPair = true;
    final selected = revealedPairTiles.toList();
    final isMatch = pairTiles[selected[0]] == pairTiles[selected[1]];
    final settings = ref.read(appStateProvider).requireValue.settings;
    if (settings.sound && isMatch) {
      await SystemSound.play(SystemSoundType.click);
    }
    await Future<void>.delayed(
      settings.reducedMotion
          ? Duration.zero
          : Duration(milliseconds: isMatch ? 300 : 700),
    );
    if (!mounted) return;
    setState(() {
      if (isMatch) {
        matchedPairTiles.addAll(selected);
        correct++;
      }
      revealedPairTiles.clear();
      resolvingPair = false;
    });
  }

  String _symbolName(String symbol) => switch (symbol) {
    '★' => 'star',
    '●' => 'circle',
    '▲' => 'triangle',
    '■' => 'square',
    '◆' => 'diamond',
    '☀' => 'sun',
    '☂' => 'umbrella',
    '♥' => 'heart',
    '☁' => 'cloud',
    '♫' => 'music note',
    _ => symbol,
  };

  Future<void> _completePicturePairs() async {
    if (completionInProgress) return;
    setState(() => completionInProgress = true);
    final result = ExerciseResult(
      type: widget.type,
      date: DateTime.now(),
      correct: correct,
      attempted: max(attempted, 1),
      score: scoreRound(
        correct: correct,
        attempted: max(attempted, 1),
        elapsed: DateTime.now().difference(started),
        comfortableTime: const Duration(seconds: 90),
      ),
      practice: widget.practice,
      difficulty: difficulty,
      startedAt: started,
    );
    await ref.read(appStateProvider.notifier).addResult(result);
    widget.onDone();
  }

  Future<void> _answer(String answer) async {
    if (completionInProgress) return;
    final wasCorrect = answer == challenge.answer;
    final settings = ref.read(appStateProvider).requireValue.settings;
    if (settings.sound) {
      unawaited(SystemSound.play(SystemSoundType.click));
    }
    attempted++;
    if (wasCorrect) correct++;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 650),
          content: Text(
            wasCorrect
                ? context.strings.text('niceWork')
                : context.strings.format('answerWas', {
                    'answer': challenge.answer,
                  }),
          ),
        ),
      );
    }
    if (attempted >= 5) {
      setState(() => completionInProgress = true);
      final result = ExerciseResult(
        type: widget.type,
        date: DateTime.now(),
        correct: correct,
        attempted: attempted,
        score: scoreRound(
          correct: correct,
          attempted: attempted,
          elapsed: DateTime.now().difference(started),
          comfortableTime: const Duration(seconds: 75),
        ),
        practice: widget.practice,
        difficulty: difficulty,
        startedAt: started,
      );
      await ref.read(appStateProvider.notifier).addResult(result);
      await Future<void>.delayed(const Duration(milliseconds: 700));
      widget.onDone();
    } else {
      setState(() {
        challenge = Challenge.generate(
          widget.type,
          Random(),
          difficulty,
          ref.read(appStateProvider).requireValue.settings.language,
        );
        _startWordPreview();
      });
    }
  }
}

class Challenge {
  const Challenge(
    this.prompt,
    this.options,
    this.answer, {
    this.preview,
    required this.variant,
  });
  final String prompt;
  final List<String> options;
  final String answer;
  final String? preview;
  final String variant;
  static const _englishWords = [
    'apple',
    'chair',
    'river',
    'garden',
    'window',
    'pencil',
    'cloud',
    'bread',
    'music',
    'train',
  ];
  static const _kazakhWords = [
    'алма',
    'орындық',
    'өзен',
    'бақ',
    'терезе',
    'қарындаш',
    'бұлт',
    'нан',
    'әуен',
    'пойыз',
  ];
  static const _russianWords = [
    'яблоко',
    'стул',
    'река',
    'сад',
    'окно',
    'карандаш',
    'облако',
    'хлеб',
    'музыка',
    'поезд',
  ];
  static const _symbols = ['★', '●', '▲', '■', '◆', '☀', '☂', '♥', '☁', '♫'];
  factory Challenge.generate(
    ExerciseType type,
    Random random, [
    int difficulty = 1,
    AppLanguage language = AppLanguage.english,
  ]) {
    switch (type) {
      case ExerciseType.quickSums:
        final variant = random.nextInt(difficulty >= 4 ? 3 : 2);
        if (variant == 1) {
          final smaller = random.nextInt(12 + difficulty) + 1;
          final answer = random.nextInt(18 + difficulty * 2) + 1;
          final larger = smaller + answer;
          return Challenge(
            '$larger − $smaller = ?',
            const [],
            '$answer',
            variant: 'subtraction',
          );
        }
        final a = random.nextInt(20 + difficulty * 3) + 2;
        final b = random.nextInt(15 + difficulty * 2) + 1;
        if (variant == 2) {
          final c = random.nextInt(10 + difficulty) + 1;
          return Challenge(
            '$a + $b + $c = ?',
            const [],
            '${a + b + c}',
            variant: 'three-number addition',
          );
        }
        return Challenge(
          '$a + $b = ?',
          const [],
          '${a + b}',
          variant: 'addition',
        );
      case ExerciseType.wordGarden:
        final words = switch (language) {
          AppLanguage.kazakh => _kazakhWords,
          AppLanguage.russian => _russianWords,
          AppLanguage.english => _englishWords,
        };
        final shownWords = List<String>.of(words)..shuffle(random);
        shownWords.removeRange(3, shownWords.length);
        final answer = shownWords[random.nextInt(shownWords.length)];
        final distractors =
            words.where((word) => !shownWords.contains(word)).toList()
              ..shuffle(random);
        final options = <String>[answer, ...distractors.take(3)]
          ..shuffle(random);
        final shown = shownWords.join(' · ');
        final preview = switch (language) {
          AppLanguage.kazakh => 'Мына сөздерді есте сақтаңыз:\n\n$shown',
          AppLanguage.russian => 'Запомните слова:\n\n$shown',
          AppLanguage.english => 'Remember these words:\n\n$shown',
        };
        final prompt = switch (language) {
          AppLanguage.kazakh => 'Қай сөз көрсетілді?',
          AppLanguage.russian => 'Какое слово было показано?',
          AppLanguage.english => 'Which word was shown?',
        };
        return Challenge(
          prompt,
          options,
          answer,
          preview: preview,
          variant: 'word list',
        );
      case ExerciseType.picturePairs:
        final answer = _symbols[random.nextInt(_symbols.length)];
        final options = <String>{answer};
        while (options.length < 4) {
          options.add(_symbols[random.nextInt(_symbols.length)]);
        }
        final shuffled = options.toList()..shuffle(random);
        return Challenge(
          'Match this symbol: $answer',
          shuffled,
          answer,
          variant: 'symbol match',
        );
      case ExerciseType.findTarget:
        final answer = _symbols[random.nextInt(_symbols.length)];
        final options = <String>{answer};
        while (options.length < 9) {
          options.add(_symbols[random.nextInt(_symbols.length)]);
        }
        final shuffled = options.toList()..shuffle(random);
        return Challenge(
          switch (language) {
            AppLanguage.kazakh => '$answer таңбасын табыңыз',
            AppLanguage.russian => 'Найдите $answer',
            AppLanguage.english => 'Find $answer',
          },
          shuffled,
          answer,
          variant: 'requested symbol',
        );
      case ExerciseType.runningTotal:
      case ExerciseType.colorWord:
        throw UnsupportedError('Archived exercise');
    }
  }
}

class _WorkoutComplete extends StatelessWidget {
  const _WorkoutComplete({required this.practice});
  final bool practice;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.check_circle_outline, size: 96),
            const SizedBox(height: 24),
            Text(
              practice
                  ? context.strings.text('practiceComplete')
                  : context.strings.text('workoutComplete'),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              context.strings.text('completionMessage'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => context.go('/'),
              child: Text(context.strings.text('backHome')),
            ),
          ],
        ),
      ),
    ),
  );
}

class ProgressScreen extends DayProgressScreen {
  const ProgressScreen({super.key});
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appStateProvider).requireValue.settings;
    final notifier = ref.read(appStateProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(context.strings.text('settings'))),
      body: ListView(
        children: [
          ListTile(
            title: Text(
              context.strings.text('language'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: DropdownButton<AppLanguage>(
              value: settings.language,
              items: AppLanguage.values
                  .map(
                    (language) => DropdownMenuItem(
                      value: language,
                      child: Text(context.strings.text(language.name)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  notifier.updateSettings(settings.copyWith(language: value));
                }
              },
            ),
          ),
          ListTile(
            title: Text(
              context.strings.text('accessibility'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(words(ref, 'Text size', 'Мәтін өлшемі', 'Размер текста')),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final size in TextSize.values)
                      ChoiceChip(
                        label: Text(switch (size) {
                          TextSize.normal => words(
                            ref,
                            'Normal',
                            'Қалыпты',
                            'Обычный',
                          ),
                          TextSize.larger => words(
                            ref,
                            'Larger',
                            'Үлкен',
                            'Крупный',
                          ),
                          TextSize.largest => words(
                            ref,
                            'Largest',
                            'Өте үлкен',
                            'Самый крупный',
                          ),
                        }),
                        selected: settings.textSize == size,
                        onSelected: (_) => notifier.updateSettings(
                          settings.copyWith(textSize: size),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          SwitchListTile(
            title: Text(context.strings.text('highContrast')),
            value: settings.highContrast,
            onChanged: (v) =>
                notifier.updateSettings(settings.copyWith(highContrast: v)),
          ),
          SwitchListTile(
            title: Text(context.strings.text('reduceMotion')),
            value: settings.reducedMotion,
            onChanged: (v) =>
                notifier.updateSettings(settings.copyWith(reducedMotion: v)),
          ),
          ListTile(
            title: Text(
              words(ref, 'Voice & sound', 'Дауыс пен дыбыс', 'Голос и звук'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: Text(context.strings.text('narration')),
            value: settings.narration,
            onChanged: (v) =>
                notifier.updateSettings(settings.copyWith(narration: v)),
          ),
          SwitchListTile(
            title: Text(context.strings.text('sounds')),
            value: settings.sound,
            onChanged: (v) =>
                notifier.updateSettings(settings.copyWith(sound: v)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButtonFormField<AnswerInput>(
              initialValue: settings.answerInput,
              isExpanded: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: context.strings.text('inputMethod'),
              ),
              items: AnswerInput.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(context.strings.text(value.name)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  notifier.updateSettings(
                    settings.copyWith(answerInput: value),
                  );
                }
              },
            ),
          ),
          ListTile(
            title: Text(
              context.strings.text('reminders'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: Text(context.strings.text('dailyReminder')),
            subtitle: Text(
              settings.remindersEnabled
                  ? words(
                      ref,
                      'Set times in “New routine”',
                      'Уақытты «Жаңа әрекет» бөлімінде таңдаңыз',
                      'Настройте время в «Новое занятие»',
                    )
                  : context.strings.text('off'),
            ),
            value: settings.remindersEnabled,
            onChanged: (v) async {
              final applied = await notifier.updateSettings(
                settings.copyWith(remindersEnabled: v),
              );
              if (v && !applied && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.strings.text('notificationsDisabled'),
                    ),
                  ),
                );
              }
            },
          ),
          if (settings.remindersEnabled) ...[
            ListTile(
              title: Text(context.strings.text('quietHours')),
              subtitle: Text(
                '${_hour(settings.quietStartHour)} – ${_hour(settings.quietEndHour)}',
              ),
              onTap: () async {
                final start = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: settings.quietStartHour,
                    minute: 0,
                  ),
                );
                if (!context.mounted || start == null) return;
                final end = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: settings.quietEndHour,
                    minute: 0,
                  ),
                );
                if (end != null) {
                  await notifier.updateSettings(
                    settings.copyWith(
                      quietStartHour: start.hour,
                      quietEndHour: end.hour,
                    ),
                  );
                }
              },
            ),
          ],
          const Divider(),
          ListTile(
            title: Text(
              context.strings.text('accountBackup'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: Text(context.strings.text('cloudBackup')),
            subtitle: Text(context.strings.text('optionalSignIn')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/account'),
          ),
          const Divider(),
          ListTile(
            title: Text(context.strings.text('aboutOyla')),
            subtitle: Text(context.strings.text('wellnessDisclaimer')),
          ),
        ],
      ),
    );
  }

  static String _hour(int hour) => '${hour.toString().padLeft(2, '0')}:00';
}

class AccessibilitySetupScreen extends ConsumerWidget {
  const AccessibilitySetupScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appStateProvider).requireValue.settings;
    final notifier = ref.read(appStateProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(context.strings.text('accessibilitySetup'))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          DropdownButtonFormField<AppLanguage>(
            initialValue: settings.language,
            decoration: InputDecoration(
              labelText: context.strings.text('language'),
              border: const OutlineInputBorder(),
            ),
            items: AppLanguage.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(context.strings.text(value.name)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                notifier.updateSettings(settings.copyWith(language: value));
              }
            },
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                context.strings.text('previewText'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          SwitchListTile(
            title: Text(context.strings.text('largerText')),
            value: settings.largeText,
            onChanged: (v) =>
                notifier.updateSettings(settings.copyWith(largeText: v)),
          ),
          SwitchListTile(
            title: Text(context.strings.text('highContrast')),
            value: settings.highContrast,
            onChanged: (v) =>
                notifier.updateSettings(settings.copyWith(highContrast: v)),
          ),
          SwitchListTile(
            title: Text(context.strings.text('reduceMotion')),
            value: settings.reducedMotion,
            onChanged: (v) =>
                notifier.updateSettings(settings.copyWith(reducedMotion: v)),
          ),
          SwitchListTile(
            title: Text(context.strings.text('narration')),
            value: settings.narration,
            onChanged: (v) =>
                notifier.updateSettings(settings.copyWith(narration: v)),
          ),
          OutlinedButton.icon(
            onPressed: () =>
                notifier.speak(context.strings.text('previewText')),
            icon: const Icon(Icons.volume_up_outlined),
            label: Text(context.strings.text('testNarration')),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () async {
              await notifier.updateSettings(
                settings.copyWith(onboardingComplete: true),
              );
              if (context.mounted) context.go('/');
            },
            child: Text(context.strings.text('finishSetup')),
          ),
        ],
      ),
    );
  }
}

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key, this.api});
  final OylaApi? api;
  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final email = TextEditingController();
  final code = TextEditingController();
  final nickname = TextEditingController();
  late final OylaApi api;
  bool codeSent = false, busy = false, signedIn = false;
  String? signedInEmail;
  String? message;
  @override
  void initState() {
    super.initState();
    api = widget.api ?? OylaApi();
    api.isSignedIn().then((value) async {
      if (!mounted) return;
      if (value) {
        await ref
            .read(appStateProvider.notifier)
            .markSignedIn(await api.currentUserId());
        if (!mounted) return;
      }
      setState(() => signedIn = value);
      if (value) _loadProfile();
    });
  }

  @override
  void dispose() {
    email.dispose();
    code.dispose();
    nickname.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sync = ref.watch(appStateProvider).requireValue.sync;
    return Scaffold(
      appBar: AppBar(title: Text(context.strings.text('accountTitle'))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (signedIn) ...[
            const Icon(Icons.cloud_done_outlined, size: 72),
            const SizedBox(height: 16),
            Text(
              context.strings.text('backupConnected'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            _SyncStatusCard(
              sync: sync,
              onRetry: busy
                  ? null
                  : () => ref.read(appStateProvider.notifier).syncNow(),
            ),
            if (signedInEmail != null) ...[
              const SizedBox(height: 8),
              Text(signedInEmail!, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: nickname,
              maxLength: 80,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: context.strings.text('nickname'),
              ),
            ),
            FilledButton.tonal(
              onPressed: busy ? null : _saveProfile,
              child: Text(context.strings.text('saveProfile')),
            ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(message!, textAlign: TextAlign.center),
              ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: busy
                  ? null
                  : () async {
                      await api.logout();
                      ref.read(appStateProvider.notifier).markSignedOut();
                      if (mounted) setState(() => signedIn = false);
                    },
              child: Text(context.strings.text('signOut')),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: busy ? null : _confirmDeleteAccount,
              child: Text(context.strings.text('deleteAccountActivity')),
            ),
          ] else ...[
            const _SyncStatusCard(sync: SyncInfo()),
            const SizedBox(height: 24),
            Text(
              context.strings.text('createAccount'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(context.strings.text('accountIntro')),
            const SizedBox(height: 24),
            TextField(
              controller: email,
              enabled: !codeSent,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: context.strings.text('emailAddress'),
              ),
            ),
            if (codeSent) ...[
              const SizedBox(height: 16),
              TextField(
                controller: code,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofillHints: const [AutofillHints.oneTimeCode],
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: context.strings.text('sixDigitCode'),
                ),
              ),
            ],
            if (message != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(message!),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: busy ? null : _submit,
              child: Text(
                codeSent
                    ? context.strings.text('verifyBackup')
                    : context.strings.text('sendCode'),
              ),
            ),
            if (codeSent) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: busy ? null : _resendCode,
                child: Text(context.strings.text('sendNewCode')),
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () => setState(() {
                        codeSent = false;
                        code.clear();
                        message = null;
                      }),
                child: Text(context.strings.text('differentEmail')),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String? _emailError() {
    final value = email.text.trim();
    final parts = value.split('@');
    if (parts.length != 2 ||
        parts.first.isEmpty ||
        !parts.last.contains('.') ||
        parts.last.startsWith('.') ||
        parts.last.endsWith('.')) {
      return context.strings.text('validEmail');
    }
    return null;
  }

  Future<void> _submit() async {
    final emailError = _emailError();
    if (emailError != null) {
      setState(() => message = emailError);
      return;
    }
    if (codeSent && !RegExp(r'^\d{6}$').hasMatch(code.text.trim())) {
      setState(() => message = context.strings.text('enterCode'));
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    try {
      if (!codeSent) {
        final developmentCode = await api.requestCode(email.text.trim());
        if (!mounted) return;
        setState(() {
          codeSent = true;
          message = developmentCode == null
              ? context.strings.text('checkEmail')
              : context.strings.format('developmentCode', {
                  'code': developmentCode,
                });
        });
      } else {
        await api.verifyCode(email.text.trim(), code.text.trim());
        await ref
            .read(appStateProvider.notifier)
            .markSignedIn(await api.currentUserId());
        await ref.read(appStateProvider.notifier).syncProfile();
        await ref.read(appStateProvider.notifier).syncNow();
        if (!mounted) return;
        setState(() {
          signedIn = true;
          message = null;
        });
        _loadProfile();
      }
    } catch (_) {
      if (mounted) {
        setState(() => message = context.strings.text('connectError'));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      busy = true;
      message = null;
      code.clear();
    });
    try {
      final developmentCode = await api.requestCode(email.text.trim());
      if (!mounted) return;
      setState(
        () => message = developmentCode == null
            ? context.strings.text('newCodeSent')
            : context.strings.format('developmentCode', {
                'code': developmentCode,
              }),
      );
    } catch (_) {
      if (mounted) {
        setState(() => message = context.strings.text('newCodeError'));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await api.profile();
      if (!mounted || profile == null) return;
      setState(() {
        signedInEmail = profile['email'] as String?;
        nickname.text = profile['nickname'] as String? ?? '';
      });
    } catch (_) {
      // Local activity remains available when the profile is offline.
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await api.updateProfile(nickname: nickname.text.trim());
      if (mounted) {
        setState(() => message = context.strings.text('profileSaved'));
      }
    } catch (_) {
      if (mounted) {
        setState(() => message = context.strings.text('profileSaveError'));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.strings.text('deleteAccountQuestion')),
            content: Text(context.strings.text('deleteAccountWarning')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.strings.text('cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.strings.text('delete')),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    setState(() => busy = true);
    try {
      final ownerId = await api.currentUserId();
      await api.deleteAccount();
      ref.read(appStateProvider.notifier).markSignedOut();
      if (ownerId != null) {
        await ref.read(databaseProvider).clearSocialCache(ownerId);
        await ref.read(databaseProvider).clearDayOwner(ownerId);
        ref.invalidate(dayProvider);
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('friendCode.$ownerId');
      }
      await ref.read(appStateProvider.notifier).clearResults();
      if (mounted) setState(() => signedIn = false);
    } catch (_) {
      if (mounted) {
        setState(() => message = context.strings.text('deleteAccountError'));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

class _SyncStatusCard extends StatelessWidget {
  const _SyncStatusCard({required this.sync, this.onRetry});
  final SyncInfo sync;
  final Future<bool> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final (icon, title, detail) = switch (sync.phase) {
      SyncPhase.deviceOnly => (
        Icons.phone_android_outlined,
        context.strings.text('storedDevice'),
        context.strings.text('signInBackup'),
      ),
      SyncPhase.syncing => (
        Icons.sync,
        context.strings.text('backingUp'),
        context.strings.text('localAvailable'),
      ),
      SyncPhase.synced => (
        Icons.cloud_done_outlined,
        context.strings.text('backedUp'),
        _lastSyncText(context, sync.lastSuccessfulAt),
      ),
      SyncPhase.pending => (
        Icons.cloud_off_outlined,
        context.strings.text('offlineSafe'),
        sync.lastSuccessfulAt == null
            ? context.strings.text('retryConnection')
            : context.strings.format('willTryAgain', {
                'last': _lastSyncText(context, sync.lastSuccessfulAt),
              }),
      ),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: sync.phase == SyncPhase.syncing
                  ? const SizedBox.square(
                      dimension: 28,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : Icon(icon),
              title: Text(title),
              subtitle: Text(detail),
            ),
            if (sync.phase == SyncPhase.pending && onRetry != null)
              OutlinedButton(
                onPressed: () => onRetry!(),
                child: Text(context.strings.text('tryBackupAgain')),
              ),
          ],
        ),
      ),
    );
  }

  static String _lastSyncText(BuildContext context, DateTime? value) {
    if (value == null) return context.strings.text('backupCompleted');
    final local = value.toLocal();
    return context.strings.format('lastBackup', {
      'date': '${local.day}/${local.month}/${local.year}',
      'time':
          '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}',
    });
  }
}
