import 'dart:math';

/// Rules: Kazakhstan federation, 9kumalak.com, and the official MSO rulebook.
/// Pits 0..8 belong to South; 9..17 to North. Sowing follows increasing index.
class TogyzBoard {
  TogyzBoard({
    List<int>? pits,
    List<int>? kazan,
    List<int>? tuzdyk,
    this.turn = 0,
    this.finished = false,
  }) : pits = List.of(pits ?? List.filled(18, 9)),
       kazan = List.of(kazan ?? [0, 0]),
       tuzdyk = List.of(tuzdyk ?? [-1, -1]);
  final List<int> pits, kazan, tuzdyk;
  int turn;
  bool finished;
  List<int> get legal => finished
      ? []
      : [
          for (var i = turn * 9; i < turn * 9 + 9; i++)
            if (pits[i] > 0 && !tuzdyk.contains(i)) i,
        ];
  TogyzBoard copy() => TogyzBoard(
    pits: pits,
    kazan: kazan,
    tuzdyk: tuzdyk,
    turn: turn,
    finished: finished,
  );
  void move(int pit) {
    if (!legal.contains(pit)) throw ArgumentError('Illegal move');
    final player = turn;
    var stones = pits[pit];
    pits[pit] = 0;
    var last = stones == 1 ? (pit + 1) % 18 : pit;
    while (stones > 0) {
      final owner = tuzdyk.indexOf(last);
      if (owner >= 0) {
        kazan[owner]++;
      } else {
        pits[last]++;
      }
      stones--;
      if (stones > 0) last = (last + 1) % 18;
    }
    if (last ~/ 9 != player && !tuzdyk.contains(last)) {
      if (pits[last] % 2 == 0) {
        kazan[player] += pits[last];
        pits[last] = 0;
      } else if (pits[last] == 3 &&
          tuzdyk[player] < 0 &&
          last % 9 != 8 &&
          (tuzdyk[1 - player] < 0 || tuzdyk[1 - player] % 9 != last % 9)) {
        tuzdyk[player] = last;
        kazan[player] += 3;
        pits[last] = 0;
      }
    }
    turn = 1 - player;
    if (kazan.any((v) => v >= 82)) {
      finished = true;
      return;
    }
    if (legal.isEmpty) {
      for (var i = 0; i < 18; i++) {
        kazan[i ~/ 9] += pits[i];
        pits[i] = 0;
      }
      finished = true;
    }
  }

  Map<String, dynamic> toJson(String id) => {
    'id': id,
    'pits': pits,
    'kazan': kazan,
    'tuzdyk': tuzdyk,
    'turn': turn,
    'finished': finished,
    'updatedAt': DateTime.now().toIso8601String(),
  };
  factory TogyzBoard.fromJson(Map<String, dynamic> j) => TogyzBoard(
    pits: List<int>.from(j['pits']),
    kazan: List<int>.from(j['kazan']),
    tuzdyk: List<int>.from(j['tuzdyk']),
    turn: j['turn'],
    finished: j['finished'],
  );
  int hint(int difficulty) {
    final moves = legal;
    if (moves.isEmpty) throw StateError('Finished');
    final player = turn;
    int evaluate(TogyzBoard b, int depth) {
      if (depth == 0 || b.finished) {
        return (b.kazan[player] - b.kazan[1 - player]) * 10 +
            (b.tuzdyk[player] >= 0 ? 8 : 0) -
            (b.tuzdyk[1 - player] >= 0 ? 8 : 0);
      }
      final scores = b.legal.map((m) {
        final next = b.copy()..move(m);
        return evaluate(next, depth - 1);
      });
      return scores.reduce(
        (a, c) => b.turn == player ? (a > c ? a : c) : (a < c ? a : c),
      );
    }

    var best = moves.first, score = -100000;
    for (final m in moves) {
      final b = copy()..move(m);
      final value = evaluate(b, difficulty.clamp(0, 2));
      if (value > score) {
        score = value;
        best = m;
      }
    }
    return best;
  }
}

/// A date selects a reproducible legal capture position, independently of locale.
TogyzBoard dailyTogyzPuzzle(DateTime date) {
  final random = Random(date.year * 10000 + date.month * 100 + date.day);
  for (var attempt = 0; attempt < 8; attempt++) {
    final board = TogyzBoard();
    for (var n = 0; n < 80 && !board.finished; n++) {
      if (n > 3 &&
          board.turn == 0 &&
          board.legal.any(
            (m) => (board.copy()..move(m)).kazan[0] > board.kazan[0],
          )) {
        return board;
      }
      final moves = board.legal;
      board.move(moves[random.nextInt(moves.length)]);
    }
  }
  return TogyzBoard(
    pits: [9, 9, 9, 9, 9, 9, 9, 9, 1, 1, 9, 9, 9, 9, 9, 9, 9, 9],
    kazan: [16, 0],
  );
}
