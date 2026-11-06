import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'day_screens.dart';
import 'day_state.dart';
import 'day_models.dart';
import 'music_screens.dart';
import 'togyz.dart';

class TogyzScreen extends ConsumerStatefulWidget {
  const TogyzScreen({super.key});
  @override
  ConsumerState<TogyzScreen> createState() => _TogyzState();
}

class _TogyzState extends ConsumerState<TogyzScreen> {
  TogyzBoard board = TogyzBoard();
  int difficulty = 0, lesson = 0;
  bool ready = false, busy = false, puzzle = false, training = false;
  int? selected;
  String? message;
  List<String> puzzles = [];
  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  Future<void> load() async {
    final games = await ref.read(moduleRowsProvider('togyz_games').future);
    final progress = await ref.read(
      moduleRowsProvider('togyz_progress').future,
    );
    if (!mounted) return;
    final game = games.where((g) => g['id'] == 'current').firstOrNull;
    final p = progress.where((g) => g['id'] == 'academy').firstOrNull;
    setState(() {
      if (game != null) board = TogyzBoard.fromJson(game);
      difficulty = p?['difficulty'] ?? 0;
      lesson = p?['lesson'] ?? 0;
      puzzles = List<String>.from(p?['puzzles'] ?? []);
      ready = true;
    });
    if (board.turn == 1 && !board.finished) await computer();
  }

  Future<void> save() async {
    if (!puzzle && !training) {
      await ref
          .read(dayProvider.notifier)
          .saveModule('togyz_games', board.toJson('current'));
    }
    await ref.read(dayProvider.notifier).saveModule('togyz_progress', {
      'id': 'academy',
      'lesson': lesson,
      'difficulty': difficulty,
      'puzzles': puzzles,
    });
  }

  Future<void> computer() async {
    setState(() => busy = true);
    // Yield once so the accessible status can paint before bounded search.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    board.move(board.hint(difficulty));
    await save();
    if (mounted) setState(() => busy = false);
  }

  Future<void> move(int pit) async {
    if (busy || !ready || board.turn != 0 || !board.legal.contains(pit)) return;
    final trial = board.copy()..move(pit);
    final requiredCapture = puzzle || (training && [2, 5].contains(lesson));
    if ((requiredCapture && trial.kazan[0] <= board.kazan[0]) ||
        (training && lesson == 3 && trial.tuzdyk[0] < 0) ||
        (training && lesson == 4 && !trial.finished)) {
      setState(
        () => message = words(
          ref,
          'Try a move that captures stones.',
          'Құмалақ ұтатын жүрісті байқап көріңіз.',
          'Попробуйте ход с захватом камней.',
        ),
      );
      return;
    }
    setState(() {
      board.move(pit);
      selected = pit;
      busy = true;
    });
    try {
      if (puzzle) {
        final date = dayKey(DateTime.now());
        if (!puzzles.contains(date)) puzzles.add(date);
        message = words(
          ref,
          'Daily puzzle completed',
          'Күн тапсырмасы аяқталды',
          'Задача дня решена',
        );
      }
      if (training) {
        lesson = (lesson + 1).clamp(0, 7);
        message = words(
          ref,
          'Lesson completed',
          'Сабақ аяқталды',
          'Урок пройден',
        );
      }
      await save();
      if (!training && !puzzle && !board.finished) await computer();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String get lessonText => [
    words(
      ref,
      'Board: your nine otau are below. Choose a pit to sow its stones.',
      'Тақта: тоғыз отауыңыз төменде. Жүріс үшін отауды таңдаңыз.',
      'Доска: ваши девять отау внизу. Выберите отау для хода.',
    ),
    words(
      ref,
      'Sowing: with several stones, leave the first in the starting pit. A single stone moves to the next pit.',
      'Тарату: бірнеше құмалақ болса, бірін бастапқы отауда қалдырыңыз.',
      'Распределение: при нескольких камнях первый остаётся в исходном отау; одиночный идёт в следующий.',
    ),
    words(
      ref,
      'Capture: end on an opponent pit with an even number of stones. Try pit 9.',
      'Ұту: соңғы құмалақ қарсыластың отауын жұп етсін. 9-отауды таңдаңыз.',
      'Захват: завершите ход в отау соперника с чётным числом камней. Попробуйте отау 9.',
    ),
    words(
      ref,
      'Tuzdyk: end with three in an opponent pit, except pit 9 or the same number as their tuzdyk. Try pit 9.',
      'Тұздық: қарсылас отауында үш құмалақ қалсын. 9-отау мен аттас тұздық болмайды.',
      'Туздык: завершите ход тремя камнями в отау соперника. Нельзя взять девятый или одноимённый туздык. Попробуйте отау 9.',
    ),
    words(
      ref,
      'End: 82 stones win. If the next player has no move, remaining stones go to their owners.',
      'Соңы: 82 құмалақ — жеңіс. Жүріс қалмаса, қалған құмалақ өз қазанына түседі.',
      'Конец: 82 камня приносят победу. Если нет хода, остатки переходят в казаны владельцев.',
    ),
    words(
      ref,
      'Practice: use Hint to explore a capture.',
      'Жаттығу: ұту жүрісін көру үшін кеңесті қолданыңыз.',
      'Учебная позиция: используйте подсказку для захвата.',
    ),
    words(
      ref,
      'First game: choose your opening move.',
      'Алғашқы партия: бірінші жүрісті таңдаңыз.',
      'Первая партия: выберите первый ход.',
    ),
    words(
      ref,
      'Lessons completed. Play at your own pace.',
      'Сабақтар аяқталды. Асықпай ойнаңыз.',
      'Уроки пройдены. Играйте в своём темпе.',
    ),
  ][lesson];
  void setup({required bool daily}) {
    puzzle = daily;
    training = !daily;
    selected = null;
    message = null;
    board = TogyzBoard();
    if (daily) {
      board = dailyTogyzPuzzle(DateTime.now());
      setState(() {});
      return;
    }
    if (daily || lesson == 2 || lesson == 3 || lesson == 5) {
      board = TogyzBoard(
        pits: [
          9,
          9,
          9,
          9,
          9,
          9,
          9,
          9,
          1,
          lesson == 3 && !daily ? 2 : 1,
          9,
          9,
          9,
          9,
          9,
          9,
          9,
          9,
        ],
        kazan: [lesson == 3 && !daily ? 15 : 16, 0],
      );
    }
    if (lesson == 4 && !daily) {
      board = TogyzBoard(
        pits: [0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
        kazan: [80, 80],
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Тоғызқұмалақ Academy')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(lessonText),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: busy || lesson >= 7 ? null : () => setup(daily: false),
              child: Text(
                words(
                  ref,
                  'Try lesson on board',
                  'Тақтада үйрену',
                  'Урок на доске',
                ),
              ),
            ),
            OutlinedButton(
              onPressed: busy ? null : () => setup(daily: true),
              child: Text(
                words(ref, 'Daily puzzle', 'Күн тапсырмасы', 'Задача дня'),
              ),
            ),
            OutlinedButton(
              onPressed: busy
                  ? null
                  : () async {
                      puzzle = false;
                      training = false;
                      await load();
                    },
              child: Text(
                words(ref, 'Resume game', 'Жалғастыру', 'Продолжить партию'),
              ),
            ),
            OutlinedButton(
              onPressed: busy
                  ? null
                  : () async {
                      setState(() {
                        board = TogyzBoard();
                        training = false;
                        puzzle = false;
                        selected = null;
                      });
                      await save();
                    },
              child: Text(words(ref, 'New game', 'Жаңа ойын', 'Новая партия')),
            ),
          ],
        ),
        DropdownButton<int>(
          value: difficulty,
          isExpanded: true,
          items: [
            for (var i = 0; i < 3; i++)
              DropdownMenuItem(
                value: i,
                child: Text(
                  [
                    words(ref, 'Beginner', 'Бастаушы', 'Начинающий'),
                    words(ref, 'Regular', 'Қалыпты', 'Обычный'),
                    words(ref, 'Experienced', 'Тәжірибелі', 'Опытный'),
                  ][i],
                ),
              ),
          ],
          onChanged: busy
              ? null
              : (v) async {
                  setState(() => difficulty = v!);
                  await save();
                },
        ),
        Text(
          '${words(ref, 'Computer kazan', 'Компьютер қазаны', 'Казан компьютера')}: ${board.kazan[1]}',
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (var i = 17; i >= 9; i--) pit(i)],
        ),
        const Divider(height: 32),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (var i = 0; i < 9; i++) pit(i)],
        ),
        Text(
          '${words(ref, 'Your kazan', 'Сіздің қазаныңыз', 'Ваш казан')}: ${board.kazan[0]}',
        ),
        if (board.finished)
          Text(
            board.kazan[0] == board.kazan[1]
                ? words(ref, 'Draw', 'Тең', 'Ничья')
                : words(
                    ref,
                    'Game finished',
                    'Ойын аяқталды',
                    'Партия завершена',
                  ),
          ),
        if (busy)
          Text(
            words(
              ref,
              'Computer is thinking',
              'Компьютер ойлануда',
              'Компьютер думает',
            ),
          ),
        OutlinedButton(
          onPressed: busy || board.finished
              ? null
              : () {
                  setState(() {
                    selected = board.hint(1);
                    message =
                        '${words(ref, 'Suggested pit', 'Ұсынылған отау', 'Предлагаемый отау')}: ${selected! % 9 + 1}. ${words(ref, 'This considers captures and the next reply.', 'Ұту мен келесі жауап ескерілген.', 'Учтены захваты и следующий ответ.')}';
                  });
                },
          child: Text(words(ref, 'Hint', 'Кеңес', 'Подсказка')),
        ),
        if (message != null) Semantics(liveRegion: true, child: Text(message!)),
        Text(
          '${words(ref, 'Completed puzzles', 'Шешілген тапсырмалар', 'Решённые задачи')}: ${puzzles.length}',
        ),
      ],
    ),
  );
  Widget pit(int i) => Semantics(
    label:
        '${i < 9 ? words(ref, 'Your', 'Сіздің', 'Ваш') : words(ref, 'Computer', 'Компьютер', 'Компьютер')} ${words(ref, 'pit', 'отау', 'лунка')} ${i % 9 + 1}, ${board.pits[i]} ${words(ref, 'stones', 'құмалақ', 'камней')}${board.tuzdyk.contains(i) ? ', ${words(ref, 'tuzdyk', 'тұздық', 'туздык')}' : ''}',
    selected: selected == i,
    child: SizedBox(
      width: 92,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(92, 72),
          side: BorderSide(
            width: selected == i ? 4 : 1,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        onPressed: i < 9 && !busy && !board.finished && board.pits[i] > 0
            ? () => move(i)
            : null,
        child: Text(
          '${i % 9 + 1}\n${board.tuzdyk.contains(i) ? 'T' : board.pits[i]}',
        ),
      ),
    ),
  );
}
