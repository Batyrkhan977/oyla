// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $StoredResultsTable extends StoredResults
    with TableInfo<$StoredResultsTable, StoredResult> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctMeta = const VerificationMeta(
    'correct',
  );
  @override
  late final GeneratedColumn<int> correct = GeneratedColumn<int>(
    'correct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptedMeta = const VerificationMeta(
    'attempted',
  );
  @override
  late final GeneratedColumn<int> attempted = GeneratedColumn<int>(
    'attempted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _practiceMeta = const VerificationMeta(
    'practice',
  );
  @override
  late final GeneratedColumn<bool> practice = GeneratedColumn<bool>(
    'practice',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("practice" IN (0, 1))',
    ),
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<int> difficulty = GeneratedColumn<int>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _algorithmVersionMeta = const VerificationMeta(
    'algorithmVersion',
  );
  @override
  late final GeneratedColumn<int> algorithmVersion = GeneratedColumn<int>(
    'algorithm_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _workoutIdMeta = const VerificationMeta(
    'workoutId',
  );
  @override
  late final GeneratedColumn<String> workoutId = GeneratedColumn<String>(
    'workout_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    completedAt,
    correct,
    attempted,
    score,
    practice,
    difficulty,
    algorithmVersion,
    startedAt,
    workoutId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stored_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredResult> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('correct')) {
      context.handle(
        _correctMeta,
        correct.isAcceptableOrUnknown(data['correct']!, _correctMeta),
      );
    } else if (isInserting) {
      context.missing(_correctMeta);
    }
    if (data.containsKey('attempted')) {
      context.handle(
        _attemptedMeta,
        attempted.isAcceptableOrUnknown(data['attempted']!, _attemptedMeta),
      );
    } else if (isInserting) {
      context.missing(_attemptedMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('practice')) {
      context.handle(
        _practiceMeta,
        practice.isAcceptableOrUnknown(data['practice']!, _practiceMeta),
      );
    } else if (isInserting) {
      context.missing(_practiceMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('algorithm_version')) {
      context.handle(
        _algorithmVersionMeta,
        algorithmVersion.isAcceptableOrUnknown(
          data['algorithm_version']!,
          _algorithmVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_algorithmVersionMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('workout_id')) {
      context.handle(
        _workoutIdMeta,
        workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredResult map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredResult(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
      correct: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct'],
      )!,
      attempted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempted'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      practice: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}practice'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}difficulty'],
      )!,
      algorithmVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}algorithm_version'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
      workoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workout_id'],
      ),
    );
  }

  @override
  $StoredResultsTable createAlias(String alias) {
    return $StoredResultsTable(attachedDatabase, alias);
  }
}

class StoredResult extends DataClass implements Insertable<StoredResult> {
  final String id;
  final String type;
  final DateTime completedAt;
  final int correct;
  final int attempted;
  final int score;
  final bool practice;
  final int difficulty;
  final int algorithmVersion;
  final DateTime? startedAt;
  final String? workoutId;
  const StoredResult({
    required this.id,
    required this.type,
    required this.completedAt,
    required this.correct,
    required this.attempted,
    required this.score,
    required this.practice,
    required this.difficulty,
    required this.algorithmVersion,
    this.startedAt,
    this.workoutId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['completed_at'] = Variable<DateTime>(completedAt);
    map['correct'] = Variable<int>(correct);
    map['attempted'] = Variable<int>(attempted);
    map['score'] = Variable<int>(score);
    map['practice'] = Variable<bool>(practice);
    map['difficulty'] = Variable<int>(difficulty);
    map['algorithm_version'] = Variable<int>(algorithmVersion);
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || workoutId != null) {
      map['workout_id'] = Variable<String>(workoutId);
    }
    return map;
  }

  StoredResultsCompanion toCompanion(bool nullToAbsent) {
    return StoredResultsCompanion(
      id: Value(id),
      type: Value(type),
      completedAt: Value(completedAt),
      correct: Value(correct),
      attempted: Value(attempted),
      score: Value(score),
      practice: Value(practice),
      difficulty: Value(difficulty),
      algorithmVersion: Value(algorithmVersion),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      workoutId: workoutId == null && nullToAbsent
          ? const Value.absent()
          : Value(workoutId),
    );
  }

  factory StoredResult.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredResult(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      correct: serializer.fromJson<int>(json['correct']),
      attempted: serializer.fromJson<int>(json['attempted']),
      score: serializer.fromJson<int>(json['score']),
      practice: serializer.fromJson<bool>(json['practice']),
      difficulty: serializer.fromJson<int>(json['difficulty']),
      algorithmVersion: serializer.fromJson<int>(json['algorithmVersion']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      workoutId: serializer.fromJson<String?>(json['workoutId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'correct': serializer.toJson<int>(correct),
      'attempted': serializer.toJson<int>(attempted),
      'score': serializer.toJson<int>(score),
      'practice': serializer.toJson<bool>(practice),
      'difficulty': serializer.toJson<int>(difficulty),
      'algorithmVersion': serializer.toJson<int>(algorithmVersion),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'workoutId': serializer.toJson<String?>(workoutId),
    };
  }

  StoredResult copyWith({
    String? id,
    String? type,
    DateTime? completedAt,
    int? correct,
    int? attempted,
    int? score,
    bool? practice,
    int? difficulty,
    int? algorithmVersion,
    Value<DateTime?> startedAt = const Value.absent(),
    Value<String?> workoutId = const Value.absent(),
  }) => StoredResult(
    id: id ?? this.id,
    type: type ?? this.type,
    completedAt: completedAt ?? this.completedAt,
    correct: correct ?? this.correct,
    attempted: attempted ?? this.attempted,
    score: score ?? this.score,
    practice: practice ?? this.practice,
    difficulty: difficulty ?? this.difficulty,
    algorithmVersion: algorithmVersion ?? this.algorithmVersion,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    workoutId: workoutId.present ? workoutId.value : this.workoutId,
  );
  StoredResult copyWithCompanion(StoredResultsCompanion data) {
    return StoredResult(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      correct: data.correct.present ? data.correct.value : this.correct,
      attempted: data.attempted.present ? data.attempted.value : this.attempted,
      score: data.score.present ? data.score.value : this.score,
      practice: data.practice.present ? data.practice.value : this.practice,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      algorithmVersion: data.algorithmVersion.present
          ? data.algorithmVersion.value
          : this.algorithmVersion,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredResult(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('completedAt: $completedAt, ')
          ..write('correct: $correct, ')
          ..write('attempted: $attempted, ')
          ..write('score: $score, ')
          ..write('practice: $practice, ')
          ..write('difficulty: $difficulty, ')
          ..write('algorithmVersion: $algorithmVersion, ')
          ..write('startedAt: $startedAt, ')
          ..write('workoutId: $workoutId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    completedAt,
    correct,
    attempted,
    score,
    practice,
    difficulty,
    algorithmVersion,
    startedAt,
    workoutId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredResult &&
          other.id == this.id &&
          other.type == this.type &&
          other.completedAt == this.completedAt &&
          other.correct == this.correct &&
          other.attempted == this.attempted &&
          other.score == this.score &&
          other.practice == this.practice &&
          other.difficulty == this.difficulty &&
          other.algorithmVersion == this.algorithmVersion &&
          other.startedAt == this.startedAt &&
          other.workoutId == this.workoutId);
}

class StoredResultsCompanion extends UpdateCompanion<StoredResult> {
  final Value<String> id;
  final Value<String> type;
  final Value<DateTime> completedAt;
  final Value<int> correct;
  final Value<int> attempted;
  final Value<int> score;
  final Value<bool> practice;
  final Value<int> difficulty;
  final Value<int> algorithmVersion;
  final Value<DateTime?> startedAt;
  final Value<String?> workoutId;
  final Value<int> rowid;
  const StoredResultsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.correct = const Value.absent(),
    this.attempted = const Value.absent(),
    this.score = const Value.absent(),
    this.practice = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.algorithmVersion = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoredResultsCompanion.insert({
    required String id,
    required String type,
    required DateTime completedAt,
    required int correct,
    required int attempted,
    required int score,
    required bool practice,
    required int difficulty,
    required int algorithmVersion,
    this.startedAt = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       completedAt = Value(completedAt),
       correct = Value(correct),
       attempted = Value(attempted),
       score = Value(score),
       practice = Value(practice),
       difficulty = Value(difficulty),
       algorithmVersion = Value(algorithmVersion);
  static Insertable<StoredResult> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<DateTime>? completedAt,
    Expression<int>? correct,
    Expression<int>? attempted,
    Expression<int>? score,
    Expression<bool>? practice,
    Expression<int>? difficulty,
    Expression<int>? algorithmVersion,
    Expression<DateTime>? startedAt,
    Expression<String>? workoutId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (completedAt != null) 'completed_at': completedAt,
      if (correct != null) 'correct': correct,
      if (attempted != null) 'attempted': attempted,
      if (score != null) 'score': score,
      if (practice != null) 'practice': practice,
      if (difficulty != null) 'difficulty': difficulty,
      if (algorithmVersion != null) 'algorithm_version': algorithmVersion,
      if (startedAt != null) 'started_at': startedAt,
      if (workoutId != null) 'workout_id': workoutId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoredResultsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<DateTime>? completedAt,
    Value<int>? correct,
    Value<int>? attempted,
    Value<int>? score,
    Value<bool>? practice,
    Value<int>? difficulty,
    Value<int>? algorithmVersion,
    Value<DateTime?>? startedAt,
    Value<String?>? workoutId,
    Value<int>? rowid,
  }) {
    return StoredResultsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      completedAt: completedAt ?? this.completedAt,
      correct: correct ?? this.correct,
      attempted: attempted ?? this.attempted,
      score: score ?? this.score,
      practice: practice ?? this.practice,
      difficulty: difficulty ?? this.difficulty,
      algorithmVersion: algorithmVersion ?? this.algorithmVersion,
      startedAt: startedAt ?? this.startedAt,
      workoutId: workoutId ?? this.workoutId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (correct.present) {
      map['correct'] = Variable<int>(correct.value);
    }
    if (attempted.present) {
      map['attempted'] = Variable<int>(attempted.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (practice.present) {
      map['practice'] = Variable<bool>(practice.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<int>(difficulty.value);
    }
    if (algorithmVersion.present) {
      map['algorithm_version'] = Variable<int>(algorithmVersion.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (workoutId.present) {
      map['workout_id'] = Variable<String>(workoutId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoredResultsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('completedAt: $completedAt, ')
          ..write('correct: $correct, ')
          ..write('attempted: $attempted, ')
          ..write('score: $score, ')
          ..write('practice: $practice, ')
          ..write('difficulty: $difficulty, ')
          ..write('algorithmVersion: $algorithmVersion, ')
          ..write('startedAt: $startedAt, ')
          ..write('workoutId: $workoutId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedFriendsTable extends CachedFriends
    with TableInfo<$CachedFriendsTable, CachedFriend> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedFriendsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _friendIdMeta = const VerificationMeta(
    'friendId',
  );
  @override
  late final GeneratedColumn<String> friendId = GeneratedColumn<String>(
    'friend_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nicknameMeta = const VerificationMeta(
    'nickname',
  );
  @override
  late final GeneratedColumn<String> nickname = GeneratedColumn<String>(
    'nickname',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    ownerId,
    friendId,
    nickname,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_friends';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedFriend> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('friend_id')) {
      context.handle(
        _friendIdMeta,
        friendId.isAcceptableOrUnknown(data['friend_id']!, _friendIdMeta),
      );
    } else if (isInserting) {
      context.missing(_friendIdMeta);
    }
    if (data.containsKey('nickname')) {
      context.handle(
        _nicknameMeta,
        nickname.isAcceptableOrUnknown(data['nickname']!, _nicknameMeta),
      );
    } else if (isInserting) {
      context.missing(_nicknameMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerId, friendId};
  @override
  CachedFriend map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedFriend(
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      friendId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}friend_id'],
      )!,
      nickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nickname'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $CachedFriendsTable createAlias(String alias) {
    return $CachedFriendsTable(attachedDatabase, alias);
  }
}

class CachedFriend extends DataClass implements Insertable<CachedFriend> {
  final String ownerId;
  final String friendId;
  final String nickname;
  final DateTime fetchedAt;
  const CachedFriend({
    required this.ownerId,
    required this.friendId,
    required this.nickname,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_id'] = Variable<String>(ownerId);
    map['friend_id'] = Variable<String>(friendId);
    map['nickname'] = Variable<String>(nickname);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  CachedFriendsCompanion toCompanion(bool nullToAbsent) {
    return CachedFriendsCompanion(
      ownerId: Value(ownerId),
      friendId: Value(friendId),
      nickname: Value(nickname),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory CachedFriend.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedFriend(
      ownerId: serializer.fromJson<String>(json['ownerId']),
      friendId: serializer.fromJson<String>(json['friendId']),
      nickname: serializer.fromJson<String>(json['nickname']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerId': serializer.toJson<String>(ownerId),
      'friendId': serializer.toJson<String>(friendId),
      'nickname': serializer.toJson<String>(nickname),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  CachedFriend copyWith({
    String? ownerId,
    String? friendId,
    String? nickname,
    DateTime? fetchedAt,
  }) => CachedFriend(
    ownerId: ownerId ?? this.ownerId,
    friendId: friendId ?? this.friendId,
    nickname: nickname ?? this.nickname,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  CachedFriend copyWithCompanion(CachedFriendsCompanion data) {
    return CachedFriend(
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      friendId: data.friendId.present ? data.friendId.value : this.friendId,
      nickname: data.nickname.present ? data.nickname.value : this.nickname,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedFriend(')
          ..write('ownerId: $ownerId, ')
          ..write('friendId: $friendId, ')
          ..write('nickname: $nickname, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(ownerId, friendId, nickname, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedFriend &&
          other.ownerId == this.ownerId &&
          other.friendId == this.friendId &&
          other.nickname == this.nickname &&
          other.fetchedAt == this.fetchedAt);
}

class CachedFriendsCompanion extends UpdateCompanion<CachedFriend> {
  final Value<String> ownerId;
  final Value<String> friendId;
  final Value<String> nickname;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const CachedFriendsCompanion({
    this.ownerId = const Value.absent(),
    this.friendId = const Value.absent(),
    this.nickname = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedFriendsCompanion.insert({
    required String ownerId,
    required String friendId,
    required String nickname,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : ownerId = Value(ownerId),
       friendId = Value(friendId),
       nickname = Value(nickname),
       fetchedAt = Value(fetchedAt);
  static Insertable<CachedFriend> custom({
    Expression<String>? ownerId,
    Expression<String>? friendId,
    Expression<String>? nickname,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerId != null) 'owner_id': ownerId,
      if (friendId != null) 'friend_id': friendId,
      if (nickname != null) 'nickname': nickname,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedFriendsCompanion copyWith({
    Value<String>? ownerId,
    Value<String>? friendId,
    Value<String>? nickname,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return CachedFriendsCompanion(
      ownerId: ownerId ?? this.ownerId,
      friendId: friendId ?? this.friendId,
      nickname: nickname ?? this.nickname,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (friendId.present) {
      map['friend_id'] = Variable<String>(friendId.value);
    }
    if (nickname.present) {
      map['nickname'] = Variable<String>(nickname.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedFriendsCompanion(')
          ..write('ownerId: $ownerId, ')
          ..write('friendId: $friendId, ')
          ..write('nickname: $nickname, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedFriendActivitiesTable extends CachedFriendActivities
    with TableInfo<$CachedFriendActivitiesTable, CachedFriendActivity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedFriendActivitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _friendIdMeta = const VerificationMeta(
    'friendId',
  );
  @override
  late final GeneratedColumn<String> friendId = GeneratedColumn<String>(
    'friend_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _practicedDaysMeta = const VerificationMeta(
    'practicedDays',
  );
  @override
  late final GeneratedColumn<int> practicedDays = GeneratedColumn<int>(
    'practiced_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activitiesCompletedMeta =
      const VerificationMeta('activitiesCompleted');
  @override
  late final GeneratedColumn<int> activitiesCompleted = GeneratedColumn<int>(
    'activities_completed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseCountsJsonMeta =
      const VerificationMeta('exerciseCountsJson');
  @override
  late final GeneratedColumn<String> exerciseCountsJson =
      GeneratedColumn<String>(
        'exercise_counts_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _recentActivityJsonMeta =
      const VerificationMeta('recentActivityJson');
  @override
  late final GeneratedColumn<String> recentActivityJson =
      GeneratedColumn<String>(
        'recent_activity_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    ownerId,
    friendId,
    practicedDays,
    activitiesCompleted,
    exerciseCountsJson,
    recentActivityJson,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_friend_activities';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedFriendActivity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('friend_id')) {
      context.handle(
        _friendIdMeta,
        friendId.isAcceptableOrUnknown(data['friend_id']!, _friendIdMeta),
      );
    } else if (isInserting) {
      context.missing(_friendIdMeta);
    }
    if (data.containsKey('practiced_days')) {
      context.handle(
        _practicedDaysMeta,
        practicedDays.isAcceptableOrUnknown(
          data['practiced_days']!,
          _practicedDaysMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_practicedDaysMeta);
    }
    if (data.containsKey('activities_completed')) {
      context.handle(
        _activitiesCompletedMeta,
        activitiesCompleted.isAcceptableOrUnknown(
          data['activities_completed']!,
          _activitiesCompletedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activitiesCompletedMeta);
    }
    if (data.containsKey('exercise_counts_json')) {
      context.handle(
        _exerciseCountsJsonMeta,
        exerciseCountsJson.isAcceptableOrUnknown(
          data['exercise_counts_json']!,
          _exerciseCountsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exerciseCountsJsonMeta);
    }
    if (data.containsKey('recent_activity_json')) {
      context.handle(
        _recentActivityJsonMeta,
        recentActivityJson.isAcceptableOrUnknown(
          data['recent_activity_json']!,
          _recentActivityJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recentActivityJsonMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerId, friendId};
  @override
  CachedFriendActivity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedFriendActivity(
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      friendId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}friend_id'],
      )!,
      practicedDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}practiced_days'],
      )!,
      activitiesCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}activities_completed'],
      )!,
      exerciseCountsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_counts_json'],
      )!,
      recentActivityJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recent_activity_json'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $CachedFriendActivitiesTable createAlias(String alias) {
    return $CachedFriendActivitiesTable(attachedDatabase, alias);
  }
}

class CachedFriendActivity extends DataClass
    implements Insertable<CachedFriendActivity> {
  final String ownerId;
  final String friendId;
  final int practicedDays;
  final int activitiesCompleted;
  final String exerciseCountsJson;
  final String recentActivityJson;
  final DateTime fetchedAt;
  const CachedFriendActivity({
    required this.ownerId,
    required this.friendId,
    required this.practicedDays,
    required this.activitiesCompleted,
    required this.exerciseCountsJson,
    required this.recentActivityJson,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_id'] = Variable<String>(ownerId);
    map['friend_id'] = Variable<String>(friendId);
    map['practiced_days'] = Variable<int>(practicedDays);
    map['activities_completed'] = Variable<int>(activitiesCompleted);
    map['exercise_counts_json'] = Variable<String>(exerciseCountsJson);
    map['recent_activity_json'] = Variable<String>(recentActivityJson);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  CachedFriendActivitiesCompanion toCompanion(bool nullToAbsent) {
    return CachedFriendActivitiesCompanion(
      ownerId: Value(ownerId),
      friendId: Value(friendId),
      practicedDays: Value(practicedDays),
      activitiesCompleted: Value(activitiesCompleted),
      exerciseCountsJson: Value(exerciseCountsJson),
      recentActivityJson: Value(recentActivityJson),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory CachedFriendActivity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedFriendActivity(
      ownerId: serializer.fromJson<String>(json['ownerId']),
      friendId: serializer.fromJson<String>(json['friendId']),
      practicedDays: serializer.fromJson<int>(json['practicedDays']),
      activitiesCompleted: serializer.fromJson<int>(
        json['activitiesCompleted'],
      ),
      exerciseCountsJson: serializer.fromJson<String>(
        json['exerciseCountsJson'],
      ),
      recentActivityJson: serializer.fromJson<String>(
        json['recentActivityJson'],
      ),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerId': serializer.toJson<String>(ownerId),
      'friendId': serializer.toJson<String>(friendId),
      'practicedDays': serializer.toJson<int>(practicedDays),
      'activitiesCompleted': serializer.toJson<int>(activitiesCompleted),
      'exerciseCountsJson': serializer.toJson<String>(exerciseCountsJson),
      'recentActivityJson': serializer.toJson<String>(recentActivityJson),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  CachedFriendActivity copyWith({
    String? ownerId,
    String? friendId,
    int? practicedDays,
    int? activitiesCompleted,
    String? exerciseCountsJson,
    String? recentActivityJson,
    DateTime? fetchedAt,
  }) => CachedFriendActivity(
    ownerId: ownerId ?? this.ownerId,
    friendId: friendId ?? this.friendId,
    practicedDays: practicedDays ?? this.practicedDays,
    activitiesCompleted: activitiesCompleted ?? this.activitiesCompleted,
    exerciseCountsJson: exerciseCountsJson ?? this.exerciseCountsJson,
    recentActivityJson: recentActivityJson ?? this.recentActivityJson,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  CachedFriendActivity copyWithCompanion(CachedFriendActivitiesCompanion data) {
    return CachedFriendActivity(
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      friendId: data.friendId.present ? data.friendId.value : this.friendId,
      practicedDays: data.practicedDays.present
          ? data.practicedDays.value
          : this.practicedDays,
      activitiesCompleted: data.activitiesCompleted.present
          ? data.activitiesCompleted.value
          : this.activitiesCompleted,
      exerciseCountsJson: data.exerciseCountsJson.present
          ? data.exerciseCountsJson.value
          : this.exerciseCountsJson,
      recentActivityJson: data.recentActivityJson.present
          ? data.recentActivityJson.value
          : this.recentActivityJson,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedFriendActivity(')
          ..write('ownerId: $ownerId, ')
          ..write('friendId: $friendId, ')
          ..write('practicedDays: $practicedDays, ')
          ..write('activitiesCompleted: $activitiesCompleted, ')
          ..write('exerciseCountsJson: $exerciseCountsJson, ')
          ..write('recentActivityJson: $recentActivityJson, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    ownerId,
    friendId,
    practicedDays,
    activitiesCompleted,
    exerciseCountsJson,
    recentActivityJson,
    fetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedFriendActivity &&
          other.ownerId == this.ownerId &&
          other.friendId == this.friendId &&
          other.practicedDays == this.practicedDays &&
          other.activitiesCompleted == this.activitiesCompleted &&
          other.exerciseCountsJson == this.exerciseCountsJson &&
          other.recentActivityJson == this.recentActivityJson &&
          other.fetchedAt == this.fetchedAt);
}

class CachedFriendActivitiesCompanion
    extends UpdateCompanion<CachedFriendActivity> {
  final Value<String> ownerId;
  final Value<String> friendId;
  final Value<int> practicedDays;
  final Value<int> activitiesCompleted;
  final Value<String> exerciseCountsJson;
  final Value<String> recentActivityJson;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const CachedFriendActivitiesCompanion({
    this.ownerId = const Value.absent(),
    this.friendId = const Value.absent(),
    this.practicedDays = const Value.absent(),
    this.activitiesCompleted = const Value.absent(),
    this.exerciseCountsJson = const Value.absent(),
    this.recentActivityJson = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedFriendActivitiesCompanion.insert({
    required String ownerId,
    required String friendId,
    required int practicedDays,
    required int activitiesCompleted,
    required String exerciseCountsJson,
    required String recentActivityJson,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : ownerId = Value(ownerId),
       friendId = Value(friendId),
       practicedDays = Value(practicedDays),
       activitiesCompleted = Value(activitiesCompleted),
       exerciseCountsJson = Value(exerciseCountsJson),
       recentActivityJson = Value(recentActivityJson),
       fetchedAt = Value(fetchedAt);
  static Insertable<CachedFriendActivity> custom({
    Expression<String>? ownerId,
    Expression<String>? friendId,
    Expression<int>? practicedDays,
    Expression<int>? activitiesCompleted,
    Expression<String>? exerciseCountsJson,
    Expression<String>? recentActivityJson,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerId != null) 'owner_id': ownerId,
      if (friendId != null) 'friend_id': friendId,
      if (practicedDays != null) 'practiced_days': practicedDays,
      if (activitiesCompleted != null)
        'activities_completed': activitiesCompleted,
      if (exerciseCountsJson != null)
        'exercise_counts_json': exerciseCountsJson,
      if (recentActivityJson != null)
        'recent_activity_json': recentActivityJson,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedFriendActivitiesCompanion copyWith({
    Value<String>? ownerId,
    Value<String>? friendId,
    Value<int>? practicedDays,
    Value<int>? activitiesCompleted,
    Value<String>? exerciseCountsJson,
    Value<String>? recentActivityJson,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return CachedFriendActivitiesCompanion(
      ownerId: ownerId ?? this.ownerId,
      friendId: friendId ?? this.friendId,
      practicedDays: practicedDays ?? this.practicedDays,
      activitiesCompleted: activitiesCompleted ?? this.activitiesCompleted,
      exerciseCountsJson: exerciseCountsJson ?? this.exerciseCountsJson,
      recentActivityJson: recentActivityJson ?? this.recentActivityJson,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (friendId.present) {
      map['friend_id'] = Variable<String>(friendId.value);
    }
    if (practicedDays.present) {
      map['practiced_days'] = Variable<int>(practicedDays.value);
    }
    if (activitiesCompleted.present) {
      map['activities_completed'] = Variable<int>(activitiesCompleted.value);
    }
    if (exerciseCountsJson.present) {
      map['exercise_counts_json'] = Variable<String>(exerciseCountsJson.value);
    }
    if (recentActivityJson.present) {
      map['recent_activity_json'] = Variable<String>(recentActivityJson.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedFriendActivitiesCompanion(')
          ..write('ownerId: $ownerId, ')
          ..write('friendId: $friendId, ')
          ..write('practicedDays: $practicedDays, ')
          ..write('activitiesCompleted: $activitiesCompleted, ')
          ..write('exerciseCountsJson: $exerciseCountsJson, ')
          ..write('recentActivityJson: $recentActivityJson, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedFriendRequestsTable extends CachedFriendRequests
    with TableInfo<$CachedFriendRequestsTable, CachedFriendRequest> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedFriendRequestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requestIdMeta = const VerificationMeta(
    'requestId',
  );
  @override
  late final GeneratedColumn<String> requestId = GeneratedColumn<String>(
    'request_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nicknameMeta = const VerificationMeta(
    'nickname',
  );
  @override
  late final GeneratedColumn<String> nickname = GeneratedColumn<String>(
    'nickname',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    ownerId,
    requestId,
    accountId,
    nickname,
    direction,
    createdAt,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_friend_requests';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedFriendRequest> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('request_id')) {
      context.handle(
        _requestIdMeta,
        requestId.isAcceptableOrUnknown(data['request_id']!, _requestIdMeta),
      );
    } else if (isInserting) {
      context.missing(_requestIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('nickname')) {
      context.handle(
        _nicknameMeta,
        nickname.isAcceptableOrUnknown(data['nickname']!, _nicknameMeta),
      );
    } else if (isInserting) {
      context.missing(_nicknameMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerId, requestId};
  @override
  CachedFriendRequest map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedFriendRequest(
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      requestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}request_id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      nickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nickname'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $CachedFriendRequestsTable createAlias(String alias) {
    return $CachedFriendRequestsTable(attachedDatabase, alias);
  }
}

class CachedFriendRequest extends DataClass
    implements Insertable<CachedFriendRequest> {
  final String ownerId;
  final String requestId;
  final String accountId;
  final String nickname;
  final String direction;
  final DateTime createdAt;
  final DateTime fetchedAt;
  const CachedFriendRequest({
    required this.ownerId,
    required this.requestId,
    required this.accountId,
    required this.nickname,
    required this.direction,
    required this.createdAt,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_id'] = Variable<String>(ownerId);
    map['request_id'] = Variable<String>(requestId);
    map['account_id'] = Variable<String>(accountId);
    map['nickname'] = Variable<String>(nickname);
    map['direction'] = Variable<String>(direction);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  CachedFriendRequestsCompanion toCompanion(bool nullToAbsent) {
    return CachedFriendRequestsCompanion(
      ownerId: Value(ownerId),
      requestId: Value(requestId),
      accountId: Value(accountId),
      nickname: Value(nickname),
      direction: Value(direction),
      createdAt: Value(createdAt),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory CachedFriendRequest.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedFriendRequest(
      ownerId: serializer.fromJson<String>(json['ownerId']),
      requestId: serializer.fromJson<String>(json['requestId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      nickname: serializer.fromJson<String>(json['nickname']),
      direction: serializer.fromJson<String>(json['direction']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerId': serializer.toJson<String>(ownerId),
      'requestId': serializer.toJson<String>(requestId),
      'accountId': serializer.toJson<String>(accountId),
      'nickname': serializer.toJson<String>(nickname),
      'direction': serializer.toJson<String>(direction),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  CachedFriendRequest copyWith({
    String? ownerId,
    String? requestId,
    String? accountId,
    String? nickname,
    String? direction,
    DateTime? createdAt,
    DateTime? fetchedAt,
  }) => CachedFriendRequest(
    ownerId: ownerId ?? this.ownerId,
    requestId: requestId ?? this.requestId,
    accountId: accountId ?? this.accountId,
    nickname: nickname ?? this.nickname,
    direction: direction ?? this.direction,
    createdAt: createdAt ?? this.createdAt,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  CachedFriendRequest copyWithCompanion(CachedFriendRequestsCompanion data) {
    return CachedFriendRequest(
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      requestId: data.requestId.present ? data.requestId.value : this.requestId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      nickname: data.nickname.present ? data.nickname.value : this.nickname,
      direction: data.direction.present ? data.direction.value : this.direction,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedFriendRequest(')
          ..write('ownerId: $ownerId, ')
          ..write('requestId: $requestId, ')
          ..write('accountId: $accountId, ')
          ..write('nickname: $nickname, ')
          ..write('direction: $direction, ')
          ..write('createdAt: $createdAt, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    ownerId,
    requestId,
    accountId,
    nickname,
    direction,
    createdAt,
    fetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedFriendRequest &&
          other.ownerId == this.ownerId &&
          other.requestId == this.requestId &&
          other.accountId == this.accountId &&
          other.nickname == this.nickname &&
          other.direction == this.direction &&
          other.createdAt == this.createdAt &&
          other.fetchedAt == this.fetchedAt);
}

class CachedFriendRequestsCompanion
    extends UpdateCompanion<CachedFriendRequest> {
  final Value<String> ownerId;
  final Value<String> requestId;
  final Value<String> accountId;
  final Value<String> nickname;
  final Value<String> direction;
  final Value<DateTime> createdAt;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const CachedFriendRequestsCompanion({
    this.ownerId = const Value.absent(),
    this.requestId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.nickname = const Value.absent(),
    this.direction = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedFriendRequestsCompanion.insert({
    required String ownerId,
    required String requestId,
    required String accountId,
    required String nickname,
    required String direction,
    required DateTime createdAt,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : ownerId = Value(ownerId),
       requestId = Value(requestId),
       accountId = Value(accountId),
       nickname = Value(nickname),
       direction = Value(direction),
       createdAt = Value(createdAt),
       fetchedAt = Value(fetchedAt);
  static Insertable<CachedFriendRequest> custom({
    Expression<String>? ownerId,
    Expression<String>? requestId,
    Expression<String>? accountId,
    Expression<String>? nickname,
    Expression<String>? direction,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerId != null) 'owner_id': ownerId,
      if (requestId != null) 'request_id': requestId,
      if (accountId != null) 'account_id': accountId,
      if (nickname != null) 'nickname': nickname,
      if (direction != null) 'direction': direction,
      if (createdAt != null) 'created_at': createdAt,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedFriendRequestsCompanion copyWith({
    Value<String>? ownerId,
    Value<String>? requestId,
    Value<String>? accountId,
    Value<String>? nickname,
    Value<String>? direction,
    Value<DateTime>? createdAt,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return CachedFriendRequestsCompanion(
      ownerId: ownerId ?? this.ownerId,
      requestId: requestId ?? this.requestId,
      accountId: accountId ?? this.accountId,
      nickname: nickname ?? this.nickname,
      direction: direction ?? this.direction,
      createdAt: createdAt ?? this.createdAt,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (requestId.present) {
      map['request_id'] = Variable<String>(requestId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (nickname.present) {
      map['nickname'] = Variable<String>(nickname.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedFriendRequestsCompanion(')
          ..write('ownerId: $ownerId, ')
          ..write('requestId: $requestId, ')
          ..write('accountId: $accountId, ')
          ..write('nickname: $nickname, ')
          ..write('direction: $direction, ')
          ..write('createdAt: $createdAt, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$OylaDatabase extends GeneratedDatabase {
  _$OylaDatabase(QueryExecutor e) : super(e);
  $OylaDatabaseManager get managers => $OylaDatabaseManager(this);
  late final $StoredResultsTable storedResults = $StoredResultsTable(this);
  late final $CachedFriendsTable cachedFriends = $CachedFriendsTable(this);
  late final $CachedFriendActivitiesTable cachedFriendActivities =
      $CachedFriendActivitiesTable(this);
  late final $CachedFriendRequestsTable cachedFriendRequests =
      $CachedFriendRequestsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    storedResults,
    cachedFriends,
    cachedFriendActivities,
    cachedFriendRequests,
  ];
}

typedef $$StoredResultsTableCreateCompanionBuilder =
    StoredResultsCompanion Function({
      required String id,
      required String type,
      required DateTime completedAt,
      required int correct,
      required int attempted,
      required int score,
      required bool practice,
      required int difficulty,
      required int algorithmVersion,
      Value<DateTime?> startedAt,
      Value<String?> workoutId,
      Value<int> rowid,
    });
typedef $$StoredResultsTableUpdateCompanionBuilder =
    StoredResultsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<DateTime> completedAt,
      Value<int> correct,
      Value<int> attempted,
      Value<int> score,
      Value<bool> practice,
      Value<int> difficulty,
      Value<int> algorithmVersion,
      Value<DateTime?> startedAt,
      Value<String?> workoutId,
      Value<int> rowid,
    });

class $$StoredResultsTableFilterComposer
    extends Composer<_$OylaDatabase, $StoredResultsTable> {
  $$StoredResultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempted => $composableBuilder(
    column: $table.attempted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get practice => $composableBuilder(
    column: $table.practice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get algorithmVersion => $composableBuilder(
    column: $table.algorithmVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workoutId => $composableBuilder(
    column: $table.workoutId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StoredResultsTableOrderingComposer
    extends Composer<_$OylaDatabase, $StoredResultsTable> {
  $$StoredResultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempted => $composableBuilder(
    column: $table.attempted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get practice => $composableBuilder(
    column: $table.practice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get algorithmVersion => $composableBuilder(
    column: $table.algorithmVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workoutId => $composableBuilder(
    column: $table.workoutId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StoredResultsTableAnnotationComposer
    extends Composer<_$OylaDatabase, $StoredResultsTable> {
  $$StoredResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get correct =>
      $composableBuilder(column: $table.correct, builder: (column) => column);

  GeneratedColumn<int> get attempted =>
      $composableBuilder(column: $table.attempted, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<bool> get practice =>
      $composableBuilder(column: $table.practice, builder: (column) => column);

  GeneratedColumn<int> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<int> get algorithmVersion => $composableBuilder(
    column: $table.algorithmVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<String> get workoutId =>
      $composableBuilder(column: $table.workoutId, builder: (column) => column);
}

class $$StoredResultsTableTableManager
    extends
        RootTableManager<
          _$OylaDatabase,
          $StoredResultsTable,
          StoredResult,
          $$StoredResultsTableFilterComposer,
          $$StoredResultsTableOrderingComposer,
          $$StoredResultsTableAnnotationComposer,
          $$StoredResultsTableCreateCompanionBuilder,
          $$StoredResultsTableUpdateCompanionBuilder,
          (
            StoredResult,
            BaseReferences<_$OylaDatabase, $StoredResultsTable, StoredResult>,
          ),
          StoredResult,
          PrefetchHooks Function()
        > {
  $$StoredResultsTableTableManager(_$OylaDatabase db, $StoredResultsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoredResultsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<int> correct = const Value.absent(),
                Value<int> attempted = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<bool> practice = const Value.absent(),
                Value<int> difficulty = const Value.absent(),
                Value<int> algorithmVersion = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<String?> workoutId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoredResultsCompanion(
                id: id,
                type: type,
                completedAt: completedAt,
                correct: correct,
                attempted: attempted,
                score: score,
                practice: practice,
                difficulty: difficulty,
                algorithmVersion: algorithmVersion,
                startedAt: startedAt,
                workoutId: workoutId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required DateTime completedAt,
                required int correct,
                required int attempted,
                required int score,
                required bool practice,
                required int difficulty,
                required int algorithmVersion,
                Value<DateTime?> startedAt = const Value.absent(),
                Value<String?> workoutId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoredResultsCompanion.insert(
                id: id,
                type: type,
                completedAt: completedAt,
                correct: correct,
                attempted: attempted,
                score: score,
                practice: practice,
                difficulty: difficulty,
                algorithmVersion: algorithmVersion,
                startedAt: startedAt,
                workoutId: workoutId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StoredResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$OylaDatabase,
      $StoredResultsTable,
      StoredResult,
      $$StoredResultsTableFilterComposer,
      $$StoredResultsTableOrderingComposer,
      $$StoredResultsTableAnnotationComposer,
      $$StoredResultsTableCreateCompanionBuilder,
      $$StoredResultsTableUpdateCompanionBuilder,
      (
        StoredResult,
        BaseReferences<_$OylaDatabase, $StoredResultsTable, StoredResult>,
      ),
      StoredResult,
      PrefetchHooks Function()
    >;
typedef $$CachedFriendsTableCreateCompanionBuilder =
    CachedFriendsCompanion Function({
      required String ownerId,
      required String friendId,
      required String nickname,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$CachedFriendsTableUpdateCompanionBuilder =
    CachedFriendsCompanion Function({
      Value<String> ownerId,
      Value<String> friendId,
      Value<String> nickname,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$CachedFriendsTableFilterComposer
    extends Composer<_$OylaDatabase, $CachedFriendsTable> {
  $$CachedFriendsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get friendId => $composableBuilder(
    column: $table.friendId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedFriendsTableOrderingComposer
    extends Composer<_$OylaDatabase, $CachedFriendsTable> {
  $$CachedFriendsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get friendId => $composableBuilder(
    column: $table.friendId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedFriendsTableAnnotationComposer
    extends Composer<_$OylaDatabase, $CachedFriendsTable> {
  $$CachedFriendsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get friendId =>
      $composableBuilder(column: $table.friendId, builder: (column) => column);

  GeneratedColumn<String> get nickname =>
      $composableBuilder(column: $table.nickname, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$CachedFriendsTableTableManager
    extends
        RootTableManager<
          _$OylaDatabase,
          $CachedFriendsTable,
          CachedFriend,
          $$CachedFriendsTableFilterComposer,
          $$CachedFriendsTableOrderingComposer,
          $$CachedFriendsTableAnnotationComposer,
          $$CachedFriendsTableCreateCompanionBuilder,
          $$CachedFriendsTableUpdateCompanionBuilder,
          (
            CachedFriend,
            BaseReferences<_$OylaDatabase, $CachedFriendsTable, CachedFriend>,
          ),
          CachedFriend,
          PrefetchHooks Function()
        > {
  $$CachedFriendsTableTableManager(_$OylaDatabase db, $CachedFriendsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedFriendsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedFriendsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedFriendsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> ownerId = const Value.absent(),
                Value<String> friendId = const Value.absent(),
                Value<String> nickname = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedFriendsCompanion(
                ownerId: ownerId,
                friendId: friendId,
                nickname: nickname,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ownerId,
                required String friendId,
                required String nickname,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedFriendsCompanion.insert(
                ownerId: ownerId,
                friendId: friendId,
                nickname: nickname,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedFriendsTableProcessedTableManager =
    ProcessedTableManager<
      _$OylaDatabase,
      $CachedFriendsTable,
      CachedFriend,
      $$CachedFriendsTableFilterComposer,
      $$CachedFriendsTableOrderingComposer,
      $$CachedFriendsTableAnnotationComposer,
      $$CachedFriendsTableCreateCompanionBuilder,
      $$CachedFriendsTableUpdateCompanionBuilder,
      (
        CachedFriend,
        BaseReferences<_$OylaDatabase, $CachedFriendsTable, CachedFriend>,
      ),
      CachedFriend,
      PrefetchHooks Function()
    >;
typedef $$CachedFriendActivitiesTableCreateCompanionBuilder =
    CachedFriendActivitiesCompanion Function({
      required String ownerId,
      required String friendId,
      required int practicedDays,
      required int activitiesCompleted,
      required String exerciseCountsJson,
      required String recentActivityJson,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$CachedFriendActivitiesTableUpdateCompanionBuilder =
    CachedFriendActivitiesCompanion Function({
      Value<String> ownerId,
      Value<String> friendId,
      Value<int> practicedDays,
      Value<int> activitiesCompleted,
      Value<String> exerciseCountsJson,
      Value<String> recentActivityJson,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$CachedFriendActivitiesTableFilterComposer
    extends Composer<_$OylaDatabase, $CachedFriendActivitiesTable> {
  $$CachedFriendActivitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get friendId => $composableBuilder(
    column: $table.friendId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get practicedDays => $composableBuilder(
    column: $table.practicedDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get activitiesCompleted => $composableBuilder(
    column: $table.activitiesCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseCountsJson => $composableBuilder(
    column: $table.exerciseCountsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recentActivityJson => $composableBuilder(
    column: $table.recentActivityJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedFriendActivitiesTableOrderingComposer
    extends Composer<_$OylaDatabase, $CachedFriendActivitiesTable> {
  $$CachedFriendActivitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get friendId => $composableBuilder(
    column: $table.friendId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get practicedDays => $composableBuilder(
    column: $table.practicedDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activitiesCompleted => $composableBuilder(
    column: $table.activitiesCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseCountsJson => $composableBuilder(
    column: $table.exerciseCountsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recentActivityJson => $composableBuilder(
    column: $table.recentActivityJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedFriendActivitiesTableAnnotationComposer
    extends Composer<_$OylaDatabase, $CachedFriendActivitiesTable> {
  $$CachedFriendActivitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get friendId =>
      $composableBuilder(column: $table.friendId, builder: (column) => column);

  GeneratedColumn<int> get practicedDays => $composableBuilder(
    column: $table.practicedDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get activitiesCompleted => $composableBuilder(
    column: $table.activitiesCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exerciseCountsJson => $composableBuilder(
    column: $table.exerciseCountsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recentActivityJson => $composableBuilder(
    column: $table.recentActivityJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$CachedFriendActivitiesTableTableManager
    extends
        RootTableManager<
          _$OylaDatabase,
          $CachedFriendActivitiesTable,
          CachedFriendActivity,
          $$CachedFriendActivitiesTableFilterComposer,
          $$CachedFriendActivitiesTableOrderingComposer,
          $$CachedFriendActivitiesTableAnnotationComposer,
          $$CachedFriendActivitiesTableCreateCompanionBuilder,
          $$CachedFriendActivitiesTableUpdateCompanionBuilder,
          (
            CachedFriendActivity,
            BaseReferences<
              _$OylaDatabase,
              $CachedFriendActivitiesTable,
              CachedFriendActivity
            >,
          ),
          CachedFriendActivity,
          PrefetchHooks Function()
        > {
  $$CachedFriendActivitiesTableTableManager(
    _$OylaDatabase db,
    $CachedFriendActivitiesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedFriendActivitiesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedFriendActivitiesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedFriendActivitiesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> ownerId = const Value.absent(),
                Value<String> friendId = const Value.absent(),
                Value<int> practicedDays = const Value.absent(),
                Value<int> activitiesCompleted = const Value.absent(),
                Value<String> exerciseCountsJson = const Value.absent(),
                Value<String> recentActivityJson = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedFriendActivitiesCompanion(
                ownerId: ownerId,
                friendId: friendId,
                practicedDays: practicedDays,
                activitiesCompleted: activitiesCompleted,
                exerciseCountsJson: exerciseCountsJson,
                recentActivityJson: recentActivityJson,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ownerId,
                required String friendId,
                required int practicedDays,
                required int activitiesCompleted,
                required String exerciseCountsJson,
                required String recentActivityJson,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedFriendActivitiesCompanion.insert(
                ownerId: ownerId,
                friendId: friendId,
                practicedDays: practicedDays,
                activitiesCompleted: activitiesCompleted,
                exerciseCountsJson: exerciseCountsJson,
                recentActivityJson: recentActivityJson,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedFriendActivitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$OylaDatabase,
      $CachedFriendActivitiesTable,
      CachedFriendActivity,
      $$CachedFriendActivitiesTableFilterComposer,
      $$CachedFriendActivitiesTableOrderingComposer,
      $$CachedFriendActivitiesTableAnnotationComposer,
      $$CachedFriendActivitiesTableCreateCompanionBuilder,
      $$CachedFriendActivitiesTableUpdateCompanionBuilder,
      (
        CachedFriendActivity,
        BaseReferences<
          _$OylaDatabase,
          $CachedFriendActivitiesTable,
          CachedFriendActivity
        >,
      ),
      CachedFriendActivity,
      PrefetchHooks Function()
    >;
typedef $$CachedFriendRequestsTableCreateCompanionBuilder =
    CachedFriendRequestsCompanion Function({
      required String ownerId,
      required String requestId,
      required String accountId,
      required String nickname,
      required String direction,
      required DateTime createdAt,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$CachedFriendRequestsTableUpdateCompanionBuilder =
    CachedFriendRequestsCompanion Function({
      Value<String> ownerId,
      Value<String> requestId,
      Value<String> accountId,
      Value<String> nickname,
      Value<String> direction,
      Value<DateTime> createdAt,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$CachedFriendRequestsTableFilterComposer
    extends Composer<_$OylaDatabase, $CachedFriendRequestsTable> {
  $$CachedFriendRequestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requestId => $composableBuilder(
    column: $table.requestId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedFriendRequestsTableOrderingComposer
    extends Composer<_$OylaDatabase, $CachedFriendRequestsTable> {
  $$CachedFriendRequestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requestId => $composableBuilder(
    column: $table.requestId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedFriendRequestsTableAnnotationComposer
    extends Composer<_$OylaDatabase, $CachedFriendRequestsTable> {
  $$CachedFriendRequestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get requestId =>
      $composableBuilder(column: $table.requestId, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get nickname =>
      $composableBuilder(column: $table.nickname, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$CachedFriendRequestsTableTableManager
    extends
        RootTableManager<
          _$OylaDatabase,
          $CachedFriendRequestsTable,
          CachedFriendRequest,
          $$CachedFriendRequestsTableFilterComposer,
          $$CachedFriendRequestsTableOrderingComposer,
          $$CachedFriendRequestsTableAnnotationComposer,
          $$CachedFriendRequestsTableCreateCompanionBuilder,
          $$CachedFriendRequestsTableUpdateCompanionBuilder,
          (
            CachedFriendRequest,
            BaseReferences<
              _$OylaDatabase,
              $CachedFriendRequestsTable,
              CachedFriendRequest
            >,
          ),
          CachedFriendRequest,
          PrefetchHooks Function()
        > {
  $$CachedFriendRequestsTableTableManager(
    _$OylaDatabase db,
    $CachedFriendRequestsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedFriendRequestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedFriendRequestsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedFriendRequestsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> ownerId = const Value.absent(),
                Value<String> requestId = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> nickname = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedFriendRequestsCompanion(
                ownerId: ownerId,
                requestId: requestId,
                accountId: accountId,
                nickname: nickname,
                direction: direction,
                createdAt: createdAt,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ownerId,
                required String requestId,
                required String accountId,
                required String nickname,
                required String direction,
                required DateTime createdAt,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedFriendRequestsCompanion.insert(
                ownerId: ownerId,
                requestId: requestId,
                accountId: accountId,
                nickname: nickname,
                direction: direction,
                createdAt: createdAt,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedFriendRequestsTableProcessedTableManager =
    ProcessedTableManager<
      _$OylaDatabase,
      $CachedFriendRequestsTable,
      CachedFriendRequest,
      $$CachedFriendRequestsTableFilterComposer,
      $$CachedFriendRequestsTableOrderingComposer,
      $$CachedFriendRequestsTableAnnotationComposer,
      $$CachedFriendRequestsTableCreateCompanionBuilder,
      $$CachedFriendRequestsTableUpdateCompanionBuilder,
      (
        CachedFriendRequest,
        BaseReferences<
          _$OylaDatabase,
          $CachedFriendRequestsTable,
          CachedFriendRequest
        >,
      ),
      CachedFriendRequest,
      PrefetchHooks Function()
    >;

class $OylaDatabaseManager {
  final _$OylaDatabase _db;
  $OylaDatabaseManager(this._db);
  $$StoredResultsTableTableManager get storedResults =>
      $$StoredResultsTableTableManager(_db, _db.storedResults);
  $$CachedFriendsTableTableManager get cachedFriends =>
      $$CachedFriendsTableTableManager(_db, _db.cachedFriends);
  $$CachedFriendActivitiesTableTableManager get cachedFriendActivities =>
      $$CachedFriendActivitiesTableTableManager(
        _db,
        _db.cachedFriendActivities,
      );
  $$CachedFriendRequestsTableTableManager get cachedFriendRequests =>
      $$CachedFriendRequestsTableTableManager(_db, _db.cachedFriendRequests);
}
