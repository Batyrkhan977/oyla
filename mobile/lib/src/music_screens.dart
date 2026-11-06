import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'app_state.dart';
import 'brand.dart';
import 'day_screens.dart';
import 'day_state.dart';
import 'media.dart';

final moduleRowsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      table,
    ) async {
      final data = await ref.watch(dayProvider.future);
      return (await ref.read(databaseProvider).dayRows(table, data.owner))
          .map((r) => Map<String, dynamic>.from(r['data']))
          .toList();
    });

class MusicScreen extends ConsumerWidget {
  const MusicScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: Text(words(ref, 'Music', 'Музыка', 'Музыка'))),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const OmirWordmark(),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: const OmirIcon(OmirDirection.piano),
            title: const Text('Piano Journey'),
            subtitle: Text(
              words(
                ref,
                'Four ways to explore keys and melodies',
                'Пернелер мен әуендерді үйренудің төрт тәсілі',
                'Четыре способа знакомиться с клавишами и мелодиями',
              ),
            ),
            onTap: () => context.push('/piano'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const OmirIcon(OmirDirection.sing),
            title: Text(words(ref, 'Sing', 'Ән салайық', 'Петь')),
            subtitle: Text(
              words(
                ref,
                'Listen, sing together, repeat a verse',
                'Тыңдау, бірге айту, шумақты қайталау',
                'Слушать, петь вместе, повторить куплет',
              ),
            ),
            onTap: () => context.push('/sing'),
          ),
        ),
        ref
            .watch(moduleRowsProvider('music_sessions'))
            .when(
              data: (rows) => Text(
                '${words(ref, 'Completed sessions', 'Аяқталған сабақтар', 'Завершённые занятия')}: ${rows.length}',
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, s) => Text(
                words(
                  ref,
                  'Progress is unavailable',
                  'Прогресс қолжетімсіз',
                  'Прогресс недоступен',
                ),
              ),
            ),
      ],
    ),
  );
}

enum PianoMode { melody, note, rhythm, learn }

class PianoScreen extends ConsumerStatefulWidget {
  const PianoScreen({super.key});
  @override
  ConsumerState<PianoScreen> createState() => _PianoState();
}

class _PianoState extends ConsumerState<PianoScreen>
    with WidgetsBindingObserver {
  PianoMode mode = PianoMode.melody;
  int level = 1, completed = 0, cursor = 0, highlighted = -1, generation = 0;
  bool playing = false, ready = false, saving = false;
  int fragment = 2;
  List<int> melody = [0, 1, 2];
  List<int> get sequence =>
      mode == PianoMode.learn ? melody.take(fragment).toList() : melody;
  final watch = Stopwatch();
  final rhythmWatch = Stopwatch();
  final taps = <int>[];
  String? message;
  static const names = ['C', 'D', 'E', 'F', 'G', 'A', 'B', 'C↑'];
  static const midi = [60, 62, 64, 65, 67, 69, 71, 72];
  int get keyCount => min(8, level + 2);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(load());
  }

  Future<void> load() async {
    final rows = await ref.read(moduleRowsProvider('music_progress').future);
    if (!mounted) return;
    final p = rows.where((r) => r['id'] == 'piano').firstOrNull;
    setState(() {
      level = (p?['level'] as int? ?? 1).clamp(1, 8);
      completed = p?['completed'] as int? ?? 0;
      ready = true;
    });
    watch.start();
    newRound();
  }

  @override
  void dispose() {
    generation++;
    watch.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      watch.start();
    } else {
      watch.stop();
      generation++;
      playing = false;
    }
  }

  void newRound() {
    generation++;
    setState(() {
      cursor = 0;
      fragment = 2;
      highlighted = -1;
      taps.clear();
      rhythmWatch.reset();
      playing = false;
      melody = List.generate(
        mode == PianoMode.note ? 1 : min(6, level + 2),
        (i) => (i + completed) % keyCount,
      );
      message = null;
    });
  }

  Future<void> sound(int key) async {
    try {
      await OmirMedia.note(midi[key]);
    } catch (_) {
      if (mounted) {
        setState(
          () => message = words(
            ref,
            'Sound is unavailable on this device. Visual keys remain available.',
            'Бұл құрылғыда дыбыс қолжетімсіз. Пернелер қолжетімді.',
            'Звук на этом устройстве недоступен. Клавиши остаются доступны.',
          ),
        );
      }
    }
  }

  Future<void> demonstrate() async {
    final token = ++generation;
    setState(() {
      playing = true;
      cursor = 0;
      taps.clear();
      message = null;
    });
    for (final key in mode == PianoMode.rhythm ? [0, 0, 0, 0] : sequence) {
      if (!mounted || token != generation) return;
      setState(() => highlighted = key);
      await sound(key);
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    if (mounted && token == generation) {
      setState(() {
        playing = false;
        highlighted = -1;
      });
    }
  }

  Future<void> press(int key) async {
    if (playing || saving || !ready) return;
    unawaited(sound(key));
    if (mode == PianoMode.rhythm) {
      if (taps.isEmpty) {
        rhythmWatch
          ..reset()
          ..start();
      }
      taps.add(rhythmWatch.elapsedMilliseconds);
      setState(() => highlighted = key);
      if (taps.length == 4) {
        final close = List.generate(
          3,
          (i) => (taps[i + 1] - taps[i] - 600).abs(),
        ).every((v) => v <= 240);
        if (close) {
          await finish();
        } else {
          setState(
            () => message = words(
              ref,
              'Listen and try the rhythm again',
              'Ырғақты тыңдап, қайталап көріңіз',
              'Послушайте и повторите ритм ещё раз',
            ),
          );
          taps.clear();
        }
      }
      return;
    }
    if (key != melody[cursor]) {
      setState(
        () => message = words(
          ref,
          'Try the highlighted note',
          'Белгіленген нотаны басыңыз',
          'Попробуйте выделенную ноту',
        ),
      );
      setState(() => highlighted = melody[cursor]);
      return;
    }
    setState(() {
      highlighted = key;
      cursor++;
      message = null;
    });
    if (cursor == sequence.length) {
      if (mode == PianoMode.learn && fragment < melody.length) {
        setState(() {
          fragment = min(melody.length, fragment + 2);
          cursor = 0;
          highlighted = melody[0];
          message = words(
            ref,
            'Now join the next fragment.',
            'Келесі бөлікті қосыңыз.',
            'Теперь добавьте следующий фрагмент.',
          );
        });
      } else {
        await finish();
      }
    }
  }

  Future<void> finish() async {
    setState(() => saving = true);
    try {
      final next = completed + 1;
      final nextLevel = min(8, 1 + next ~/ 4);
      await ref.read(dayProvider.notifier).saveModule('music_progress', {
        'id': 'piano',
        'level': nextLevel,
        'completed': next,
        'lessonId': mode.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      await ref
          .read(dayProvider.notifier)
          .recordModuleSession(
            'piano:${mode.name}',
            watch.elapsed.inSeconds,
            level,
          );
      if (!mounted) return;
      setState(() {
        completed = next;
        level = nextLevel;
      });
      watch
        ..reset()
        ..start();
      newRound();
      setState(
        () => message = words(
          ref,
          'Lesson saved. Continue when you wish.',
          'Сабақ сақталды. Қалаған кезде жалғастырыңыз.',
          'Урок сохранён. Продолжайте, когда захотите.',
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          cursor = 0;
          message = words(
            ref,
            'Could not save this lesson. Try again.',
            'Сабақ сақталмады. Қайталап көріңіз.',
            'Не удалось сохранить урок. Попробуйте ещё раз.',
          );
        });
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  String label(PianoMode m) => switch (m) {
    PianoMode.melody => words(
      ref,
      'Repeat a melody',
      'Әуенді қайталау',
      'Повтори мелодию',
    ),
    PianoMode.note => words(ref, 'Find the note', 'Нотаны табу', 'Найди ноту'),
    PianoMode.rhythm => words(
      ref,
      'Repeat a rhythm',
      'Ырғақты қайталау',
      'Повтори ритм',
    ),
    PianoMode.learn => words(
      ref,
      'Learn a melody',
      'Әуенді үйрену',
      'Разучи мелодию',
    ),
  };
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Piano Journey')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          '${words(ref, 'Level', 'Деңгей', 'Уровень')} $level · $completed ${words(ref, 'lessons', 'сабақ', 'уроков')}',
        ),
        for (final m in PianoMode.values)
          ListTile(
            title: Text(label(m)),
            selected: mode == m,
            leading: Icon(
              mode == m ? Icons.radio_button_checked : Icons.radio_button_off,
            ),
            onTap: playing || saving
                ? null
                : () {
                    mode = m;
                    newRound();
                  },
          ),
        Text(
          mode == PianoMode.rhythm
              ? words(
                  ref,
                  'Listen, then tap four steady beats.',
                  'Тыңдап, төрт рет біркелкі басыңыз.',
                  'Послушайте, затем отбейте четыре ровных удара.',
                )
              : mode == PianoMode.learn || mode == PianoMode.note
              ? sequence.map((i) => names[i]).join(' → ')
              : words(
                  ref,
                  'Listen, then repeat the sequence.',
                  'Тыңдап, реттілікті қайталаңыз.',
                  'Послушайте и повторите последовательность.',
                ),
        ),
        FilledButton(
          onPressed: playing || saving ? null : demonstrate,
          child: Text(
            words(
              ref,
              'Listen and watch',
              'Тыңдап, қарау',
              'Слушать и смотреть',
            ),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < keyCount; i++)
              Semantics(
                selected: highlighted == i,
                label: '${words(ref, 'Key', 'Перне', 'Клавиша')} ${names[i]}',
                child: SizedBox(
                  width: 76,
                  height: 140,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: highlighted == i
                          ? Theme.of(context).colorScheme.secondaryContainer
                          : null,
                      side: BorderSide(
                        width: highlighted == i ? 4 : 1,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    onPressed: playing || saving ? null : () => press(i),
                    child: Text(names[i]),
                  ),
                ),
              ),
          ],
        ),
        if (message != null) Semantics(liveRegion: true, child: Text(message!)),
        Text(
          words(
            ref,
            'Original ÖmirAI practice melodies. No musical ability score.',
            'ÖmirAI жаттығу әуендері. Музыкалық қабілет бағаланбайды.',
            'Учебные мелодии ÖmirAI. Без оценки музыкальных способностей.',
          ),
        ),
      ],
    ),
  );
}
