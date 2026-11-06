import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oyla/src/database.dart';
import 'package:oyla/src/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('legacy results import once and preserve UUIDs', () async {
    final result = ExerciseResult(
      id: 'result-1',
      type: ExerciseType.quickSums,
      date: DateTime(2026, 8, 18),
      correct: 4,
      attempted: 5,
      score: 70,
    );
    SharedPreferences.setMockInitialValues({
      'results.v1': [jsonEncode(result.toJson())],
    });
    final prefs = await SharedPreferences.getInstance();
    final database = OylaDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await database.importLegacyResults(prefs);
    await database.importLegacyResults(prefs);

    final imported = await database.allResults();
    expect(imported, hasLength(1));
    expect(imported.single.id, 'result-1');
    expect(prefs.containsKey('results.v1'), isFalse);
  });

  test('friend cache is isolated by signed-in account', () async {
    final database = OylaDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await database.replaceFriends('owner-a', [
      {
        'account': {'id': 'friend-1', 'nickname': 'A friend'},
      },
    ]);
    expect(await database.readFriends('owner-a'), hasLength(1));
    expect(await database.readFriends('owner-b'), isEmpty);
  });
}
