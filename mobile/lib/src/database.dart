import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

part 'database.g.dart';

class StoredResults extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  DateTimeColumn get completedAt => dateTime()();
  IntColumn get correct => integer()();
  IntColumn get attempted => integer()();
  IntColumn get score => integer()();
  BoolColumn get practice => boolean()();
  IntColumn get difficulty => integer()();
  IntColumn get algorithmVersion => integer()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  TextColumn get workoutId => text().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedFriends extends Table {
  TextColumn get ownerId => text()();
  TextColumn get friendId => text()();
  TextColumn get nickname => text()();
  DateTimeColumn get fetchedAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {ownerId, friendId};
}

class CachedFriendActivities extends Table {
  TextColumn get ownerId => text()();
  TextColumn get friendId => text()();
  IntColumn get practicedDays => integer()();
  IntColumn get activitiesCompleted => integer()();
  TextColumn get exerciseCountsJson => text()();
  TextColumn get recentActivityJson => text()();
  DateTimeColumn get fetchedAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {ownerId, friendId};
}

class CachedFriendRequests extends Table {
  TextColumn get ownerId => text()();
  TextColumn get requestId => text()();
  TextColumn get accountId => text()();
  TextColumn get nickname => text()();
  TextColumn get direction => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get fetchedAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {ownerId, requestId};
}

@DriftDatabase(
  tables: [
    StoredResults,
    CachedFriends,
    CachedFriendActivities,
    CachedFriendRequests,
  ],
)
class OylaDatabase extends _$OylaDatabase {
  OylaDatabase(super.executor);
  OylaDatabase.defaults() : super(driftDatabase(name: 'oyla'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createDayTables();
    },
    onUpgrade: (m, from, to) async {
      if (from < 3) await _createDayTables();
    },
  );

  static const dayTables = [
    'routines',
    'occurrences',
    'activity_events',
    'reading_positions',
    'reading_sessions',
    'movement_sessions',
    'recommendations',
    'day_settings',
    'music_sessions',
    'music_progress',
    'togyz_games',
    'togyz_progress',
  ];
  Future<void> _createDayTables() async {
    for (final name in dayTables) {
      await customStatement(
        'CREATE TABLE IF NOT EXISTS $name (owner TEXT NOT NULL, id TEXT NOT NULL, payload TEXT NOT NULL, revision INTEGER NOT NULL DEFAULT 0, dirty INTEGER NOT NULL DEFAULT 1, conflict TEXT, PRIMARY KEY (owner, id))',
      );
    }
  }

  Future<List<Map<String, dynamic>>> dayRows(String table, String owner) async {
    if (!dayTables.contains(table)) throw ArgumentError('Unknown day table');
    final rows = await customSelect(
      'SELECT id, payload, revision, dirty, conflict FROM $table WHERE owner = ?',
      variables: [Variable(owner)],
    ).get();
    return rows
        .map(
          (r) => {
            'id': r.read<String>('id'),
            'data': jsonDecode(r.read<String>('payload')),
            'revision': r.read<int>('revision'),
            'dirty': r.read<int>('dirty') == 1,
            'conflict': r.readNullable<String>('conflict'),
          },
        )
        .toList();
  }

  Future<void> putDayRow(
    String table,
    String owner,
    Map<String, dynamic> data,
  ) async {
    if (!dayTables.contains(table)) throw ArgumentError('Unknown day table');
    await customStatement(
      'INSERT INTO $table (owner,id,payload) VALUES (?,?,?) ON CONFLICT(owner,id) DO UPDATE SET payload=excluded.payload, dirty=1',
      [owner, data['id'], jsonEncode(data)],
    );
  }

  Future<void> clearDayOwner(String owner) async {
    for (final table in dayTables) {
      await customStatement('DELETE FROM $table WHERE owner=?', [owner]);
    }
  }

  Future<void> claimGuestDay(String owner) async {
    await transaction(() async {
      for (final table in dayTables) {
        await customStatement(
          'INSERT OR IGNORE INTO $table (owner,id,payload,revision,dirty) SELECT ?,id,payload,0,1 FROM $table WHERE owner=?',
          [owner, 'guest'],
        );
        await customStatement('DELETE FROM $table WHERE owner=?', ['guest']);
      }
    });
  }

  Future<void> importLegacyResults(SharedPreferences prefs) async {
    const key = 'results.v1';
    if (prefs.getBool('results.driftImported.v1') == true) return;
    final raw = prefs.getStringList(key) ?? const [];
    await transaction(() async {
      for (final value in raw) {
        final result = ExerciseResult.fromJson(
          jsonDecode(value) as Map<String, dynamic>,
        );
        await upsertResult(result);
      }
    });
    await prefs.setBool('results.driftImported.v1', true);
    await prefs.remove(key);
  }

  Future<List<ExerciseResult>> allResults() async {
    final rows = await (select(
      storedResults,
    )..orderBy([(row) => OrderingTerm.asc(row.completedAt)])).get();
    return rows.map(_resultFromRow).toList();
  }

  Stream<List<ExerciseResult>> watchResults() =>
      (select(storedResults)
            ..orderBy([(row) => OrderingTerm.asc(row.completedAt)]))
          .watch()
          .map((rows) => rows.map(_resultFromRow).toList());

  Future<void> upsertResult(ExerciseResult result) =>
      into(storedResults).insertOnConflictUpdate(
        StoredResultsCompanion.insert(
          id: result.id,
          type: result.type.name,
          completedAt: result.date,
          correct: result.correct,
          attempted: result.attempted,
          score: result.score,
          practice: result.practice,
          difficulty: result.difficulty,
          algorithmVersion: result.algorithmVersion,
          startedAt: Value(result.startedAt),
          workoutId: Value(result.workoutId),
        ),
      );

  Future<void> clearResults() => delete(storedResults).go();

  Future<void> replaceFriends(
    String ownerId,
    List<Map<String, dynamic>> raw,
  ) async {
    final fetchedAt = DateTime.now();
    await transaction(() async {
      await (delete(
        cachedFriends,
      )..where((row) => row.ownerId.equals(ownerId))).go();
      for (final item in raw) {
        final account = item['account'] as Map<String, dynamic>;
        await into(cachedFriends).insert(
          CachedFriendsCompanion.insert(
            ownerId: ownerId,
            friendId: account['id'] as String,
            nickname: account['nickname'] as String,
            fetchedAt: fetchedAt,
          ),
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> readFriends(String ownerId) async {
    final rows = await (select(
      cachedFriends,
    )..where((row) => row.ownerId.equals(ownerId))).get();
    return rows
        .map(
          (row) => {
            'account': {'id': row.friendId, 'nickname': row.nickname},
            'fetchedAt': row.fetchedAt.toIso8601String(),
          },
        )
        .toList();
  }

  Future<void> replaceFriendRequests(
    String ownerId,
    Map<String, dynamic> raw,
  ) async {
    final fetchedAt = DateTime.now();
    await transaction(() async {
      await (delete(
        cachedFriendRequests,
      )..where((row) => row.ownerId.equals(ownerId))).go();
      for (final direction in ['incoming', 'outgoing']) {
        for (final value in (raw[direction] as List<dynamic>? ?? const [])) {
          final item = value as Map<String, dynamic>;
          final account = item['account'] as Map<String, dynamic>;
          await into(cachedFriendRequests).insert(
            CachedFriendRequestsCompanion.insert(
              ownerId: ownerId,
              requestId: item['id'] as String,
              accountId: account['id'] as String,
              nickname: account['nickname'] as String,
              direction: direction,
              createdAt: DateTime.parse(item['createdAt'] as String),
              fetchedAt: fetchedAt,
            ),
          );
        }
      }
    });
  }

  Future<Map<String, dynamic>> readFriendRequests(String ownerId) async {
    final rows = await (select(
      cachedFriendRequests,
    )..where((row) => row.ownerId.equals(ownerId))).get();
    Map<String, dynamic> encode(CachedFriendRequest row) => {
      'id': row.requestId,
      'account': {'id': row.accountId, 'nickname': row.nickname},
      'createdAt': row.createdAt.toIso8601String(),
    };
    return {
      'incoming': rows
          .where((row) => row.direction == 'incoming')
          .map(encode)
          .toList(),
      'outgoing': rows
          .where((row) => row.direction == 'outgoing')
          .map(encode)
          .toList(),
    };
  }

  Future<void> cacheFriendActivity(
    String ownerId,
    String friendId,
    Map<String, dynamic> raw,
  ) => into(cachedFriendActivities).insertOnConflictUpdate(
    CachedFriendActivitiesCompanion.insert(
      ownerId: ownerId,
      friendId: friendId,
      practicedDays: raw['practicedDays'] as int,
      activitiesCompleted: raw['activitiesCompleted'] as int,
      exerciseCountsJson: jsonEncode(raw['exerciseCounts']),
      recentActivityJson: jsonEncode(raw['recentActivity']),
      fetchedAt: DateTime.now(),
    ),
  );

  Future<Map<String, dynamic>?> readFriendActivity(
    String ownerId,
    String friendId,
  ) async {
    final row =
        await (select(cachedFriendActivities)..where(
              (row) =>
                  row.ownerId.equals(ownerId) & row.friendId.equals(friendId),
            ))
            .getSingleOrNull();
    if (row == null) return null;
    return {
      'practicedDays': row.practicedDays,
      'activitiesCompleted': row.activitiesCompleted,
      'exerciseCounts': jsonDecode(row.exerciseCountsJson),
      'recentActivity': jsonDecode(row.recentActivityJson),
      'fetchedAt': row.fetchedAt.toIso8601String(),
    };
  }

  Future<void> clearSocialCache(String ownerId) async {
    await transaction(() async {
      await (delete(
        cachedFriends,
      )..where((row) => row.ownerId.equals(ownerId))).go();
      await (delete(
        cachedFriendRequests,
      )..where((row) => row.ownerId.equals(ownerId))).go();
      await (delete(
        cachedFriendActivities,
      )..where((row) => row.ownerId.equals(ownerId))).go();
    });
  }

  ExerciseResult _resultFromRow(StoredResult row) => ExerciseResult(
    id: row.id,
    type: ExerciseType.values.byName(row.type),
    date: row.completedAt,
    correct: row.correct,
    attempted: row.attempted,
    score: row.score,
    practice: row.practice,
    difficulty: row.difficulty,
    algorithmVersion: row.algorithmVersion,
    startedAt: row.startedAt,
    workoutId: row.workoutId,
  );
}
