import 'dart:math';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oyla/src/database.dart';
import 'package:oyla/src/togyz.dart';
import 'package:oyla/src/media.dart';

void main() {
  test('Daily Togyz puzzles are deterministic legal capture positions', () {
    for (var d = 1; d <= 31; d++) {
      final a = dailyTogyzPuzzle(DateTime(2026, 10, d));
      final b = dailyTogyzPuzzle(DateTime(2026, 10, d));
      expect(a.pits, b.pits);
      expect(a.turn, 0);
      expect(
        a.legal.any((m) => (a.copy()..move(m)).kazan[0] > a.kazan[0]),
        isTrue,
      );
    }
  });
  test('Sowing keeps one stone, single stone advances and captures', () {
    final board = TogyzBoard();
    board.move(0);
    expect(board.pits.take(9).toList(), [1, 10, 10, 10, 10, 10, 10, 10, 10]);
    expect(board.turn, 1);
    final single = TogyzBoard(
      pits: [9, 9, 9, 9, 9, 9, 9, 9, 1, 1, 9, 9, 9, 9, 9, 9, 9, 9],
      kazan: [16, 0],
    );
    single.move(8);
    expect(single.kazan[0], 18);
    expect(single.pits[9], 0);
  });
  test('Tuzdyk captures future stones and cannot occupy ninth pit', () {
    final board = TogyzBoard(
      pits: [9, 9, 9, 9, 9, 9, 9, 9, 1, 2, 9, 9, 9, 9, 9, 9, 9, 9],
      kazan: [15, 0],
    );
    board.move(8);
    expect(board.tuzdyk, [9, -1]);
    expect(board.kazan[0], 18);
    final ninth = TogyzBoard(
      pits: [9, 9, 9, 9, 9, 9, 9, 9, 10, 9, 9, 9, 9, 9, 9, 9, 9, 2],
    );
    ninth.move(8);
    expect(ninth.tuzdyk[0], -1);
  });
  test(
    'Full legal games conserve all 162 stones including tuzdyk and endgame',
    () {
      final random = Random(27);
      for (var game = 0; game < 30; game++) {
        final board = TogyzBoard();
        for (var n = 0; n < 2000 && !board.finished; n++) {
          final moves = board.legal;
          expect(moves, isNotEmpty);
          board.move(moves[random.nextInt(moves.length)]);
          expect(
            board.pits.fold<int>(0, (a, b) => a + b) +
                board.kazan[0] +
                board.kazan[1],
            162,
          );
          expect(board.pits.every((p) => p >= 0), isTrue);
          for (final p in board.tuzdyk.where((p) => p >= 0)) {
            expect(board.pits[p], 0);
            expect(p % 9, isNot(8));
          }
        }
        expect(board.finished, isTrue);
      }
    },
  );
  test('AI always chooses legal moves without mutating source board', () {
    for (var level = 0; level < 3; level++) {
      final b = TogyzBoard();
      final before = b.pits.toList();
      expect(b.legal, contains(b.hint(level)));
      expect(b.pits, before);
    }
  });
  test(
    'Voice progress requires a consecutive match and never moves backwards',
    () {
      const text = 'A quiet morning brings a fresh start.';
      expect(spokenPosition(text, 'quiet morning', 0), 15);
      expect(spokenPosition(text, 'completely unrelated speech', 15), 15);
      expect(spokenPosition(text, 'A quiet', 15), 15);
      expect(spokenPosition('Таңғы самал ашық аспан', 'самал ашық', 0), 16);
    },
  );
  test(
    'Module data persists, is account isolated, and retries preserve row UUID',
    () async {
      final db = OylaDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final game = TogyzBoard()..move(0);
      final data = game.toJson('current');
      await db.putDayRow('togyz_games', 'guest', data);
      await db.putDayRow('togyz_games', 'guest', data);
      expect(await db.dayRows('togyz_games', 'guest'), hasLength(1));
      await db.claimGuestDay('a');
      expect(await db.dayRows('togyz_games', 'guest'), isEmpty);
      expect(await db.dayRows('togyz_games', 'b'), isEmpty);
      final restored = TogyzBoard.fromJson(
        (await db.dayRows('togyz_games', 'a')).single['data'],
      );
      expect(restored.pits, game.pits);
      expect(restored.turn, 1);
    },
  );
}
