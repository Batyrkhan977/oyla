import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oyla/src/api.dart';
import 'package:oyla/src/app_state.dart';
import 'package:oyla/src/database.dart';
import 'package:oyla/src/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const reminders = MethodChannel('oyla/reminders');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    messenger.setMockMethodCallHandler(reminders, (_) async => null);
  });
  tearDown(() => messenger.setMockMethodCallHandler(reminders, null));

  test('successful backup records its time', () async {
    final api = _FakeApi();
    final database = OylaDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        apiProvider.overrideWithValue(api),
        databaseProvider.overrideWithValue(database),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(database.close);
    await container.read(appStateProvider.future);
    await container.read(appStateProvider.notifier).markSignedIn('user-1');

    expect(
      container.read(appStateProvider).requireValue.sync.phase,
      SyncPhase.pending,
    );
    expect(await container.read(appStateProvider.notifier).syncNow(), isTrue);
    final sync = container.read(appStateProvider).requireValue.sync;
    expect(sync.phase, SyncPhase.synced);
    expect(sync.lastSuccessfulAt, isNotNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('lastSuccessfulSync.user-1'), isNotNull);
  });

  test('failed backup stays pending and preserves local results', () async {
    final api = _FakeApi(fail: true);
    final database = OylaDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        apiProvider.overrideWithValue(api),
        databaseProvider.overrideWithValue(database),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(database.close);
    await container.read(appStateProvider.future);
    await container.read(appStateProvider.notifier).markSignedIn('user-1');
    await container
        .read(appStateProvider.notifier)
        .addResult(
          ExerciseResult(
            type: ExerciseType.quickSums,
            date: DateTime(2026, 8, 19),
            correct: 4,
            attempted: 5,
            score: 80,
          ),
        );
    await Future<void>.delayed(Duration.zero);

    expect(await container.read(appStateProvider.notifier).syncNow(), isFalse);
    final data = container.read(appStateProvider).requireValue;
    expect(data.sync.phase, SyncPhase.pending);
    expect(data.results, hasLength(1));
  });
}

class _FakeApi extends OylaApi {
  _FakeApi({this.fail = false});
  final bool fail;

  @override
  Future<Map<String, dynamic>> syncDayRecords(
    List<Map<String, dynamic>> records,
  ) async => {'records': [], 'conflicts': []};

  @override
  Future<bool> isSignedIn() async => true;

  @override
  Future<String?> currentUserId() async => 'user-1';

  @override
  Future<List<ExerciseResult>> sync(List<ExerciseResult> results) async {
    if (fail) throw StateError('offline');
    return const [];
  }
}
