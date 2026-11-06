import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'day_state.dart';
import 'api.dart';
import 'database.dart';
import 'reminders.dart';

final appStateProvider = AsyncNotifierProvider<AppState, AppData>(AppState.new);
final apiProvider = Provider<OylaApi>((ref) => OylaApi());
final databaseProvider = Provider<OylaDatabase>((ref) {
  final database = OylaDatabase.defaults();
  ref.onDispose(database.close);
  return database;
});

enum SyncPhase { deviceOnly, syncing, synced, pending }

class SyncInfo {
  const SyncInfo({this.phase = SyncPhase.deviceOnly, this.lastSuccessfulAt});
  final SyncPhase phase;
  final DateTime? lastSuccessfulAt;
}

class AppData {
  const AppData({
    required this.settings,
    required this.results,
    this.sync = const SyncInfo(),
  });
  final UserSettings settings;
  final List<ExerciseResult> results;
  final SyncInfo sync;
  bool get completedToday {
    final now = DateTime.now();
    return results
            .where(
              (r) =>
                  !r.practice &&
                  activeExercises.contains(r.type) &&
                  r.date.year == now.year &&
                  r.date.month == now.month &&
                  r.date.day == now.day,
            )
            .map((r) => r.type)
            .toSet()
            .length >=
        3;
  }
}

class AppState extends AsyncNotifier<AppData> {
  static const _settingsKey = 'settings.v1';
  final FlutterTts _tts = FlutterTts();

  @override
  Future<AppData> build() async {
    final prefs = await SharedPreferences.getInstance();
    final database = ref.watch(databaseProvider);
    await database.importLegacyResults(prefs);
    final settingsRaw = prefs.getString(_settingsKey);
    var settings = settingsRaw == null
        ? const UserSettings()
        : UserSettings.fromJson(
            jsonDecode(settingsRaw) as Map<String, dynamic>,
          );
    final reminderApplied = await ReminderService().apply(
      enabled: settings.remindersEnabled,
      hour: settings.reminderHour,
      weekdayHours: settings.reminderHours,
      quietStartHour: settings.quietStartHour,
      quietEndHour: settings.quietEndHour,
      languageCode: settings.language.name,
    );
    if (settings.remindersEnabled && !reminderApplied) {
      settings = settings.copyWith(remindersEnabled: false);
      await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
    }
    return AppData(
      settings: settings,
      results: await database.allResults(),
      sync: const SyncInfo(),
    );
  }

  Future<bool> updateSettings(UserSettings settings) async {
    final data = state.requireValue;
    final reminderApplied = await ReminderService().apply(
      enabled: settings.remindersEnabled,
      hour: settings.reminderHour,
      weekdayHours: settings.reminderHours,
      quietStartHour: settings.quietStartHour,
      quietEndHour: settings.quietEndHour,
      languageCode: settings.language.name,
    );
    final appliedSettings = settings.remindersEnabled && !reminderApplied
        ? settings.copyWith(remindersEnabled: false)
        : settings;
    state = AsyncData(
      AppData(
        settings: appliedSettings,
        results: data.results,
        sync: data.sync,
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(appliedSettings.toJson()));
    if (ref.exists(dayProvider)) {
      await ref.read(dayProvider.notifier).initializeDay();
    }
    unawaited(
      ref
          .read(apiProvider)
          .updateProfile(settings: appliedSettings)
          .catchError((_) {}),
    );
    return reminderApplied;
  }

  Future<void> addResult(ExerciseResult result) async {
    final data = state.requireValue;
    final results = [...data.results, result];
    await ref.read(databaseProvider).upsertResult(result);
    if (ref.exists(dayProvider) && ref.read(dayProvider).hasValue) {
      await ref.read(dayProvider.notifier).recordExercise(result);
    }
    state = AsyncData(
      AppData(settings: data.settings, results: results, sync: data.sync),
    );
    if (state.requireValue.completedToday && data.settings.remindersEnabled) {
      unawaited(
        ReminderService().skipToday(
          data.settings.reminderHour,
          weekdayHours: data.settings.reminderHours,
          quietStartHour: data.settings.quietStartHour,
          quietEndHour: data.settings.quietEndHour,
          languageCode: data.settings.language.name,
        ),
      );
    }
    unawaited(syncNow());
  }

  Future<void> clearResults() async {
    final data = state.requireValue;
    state = AsyncData(
      AppData(settings: data.settings, results: const [], sync: data.sync),
    );
    final prefs = await SharedPreferences.getInstance();
    await ref.read(databaseProvider).clearResults();
    await prefs.remove('installationId');
  }

  Future<void> syncProfile() async {
    final profile = await ref.read(apiProvider).profile();
    if (profile == null) return;
    final raw = profile['settingsJson'] as String?;
    if (raw == null || raw == '{}') {
      await ref
          .read(apiProvider)
          .updateProfile(settings: state.requireValue.settings);
      return;
    }
    var remote = UserSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    final reminderApplied = await ReminderService().apply(
      enabled: remote.remindersEnabled,
      hour: remote.reminderHour,
      weekdayHours: remote.reminderHours,
      quietStartHour: remote.quietStartHour,
      quietEndHour: remote.quietEndHour,
      languageCode: remote.language.name,
    );
    if (remote.remindersEnabled && !reminderApplied) {
      remote = remote.copyWith(remindersEnabled: false);
    }
    final data = state.requireValue;
    state = AsyncData(
      AppData(settings: remote, results: data.results, sync: data.sync),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(remote.toJson()));
  }

  Future<bool> syncNow() async {
    if (state.requireValue.sync.phase == SyncPhase.deviceOnly) return false;
    final api = ref.read(apiProvider);
    var data = state.requireValue;
    state = AsyncData(
      AppData(
        settings: data.settings,
        results: data.results,
        sync: SyncInfo(
          phase: SyncPhase.syncing,
          lastSuccessfulAt: data.sync.lastSuccessfulAt,
        ),
      ),
    );
    try {
      final downloaded = await api.sync(data.results);
      if (ref.exists(dayProvider)) {
        await ref.read(dayProvider.future);
        await ref.read(dayProvider.notifier).sync();
      }
      data = state.requireValue;
      final merged = <String, ExerciseResult>{
        for (final item in data.results) item.id: item,
      };
      for (final item in downloaded) {
        merged[item.id] = item;
      }
      final results = merged.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      final syncedAt = DateTime.now();
      state = AsyncData(
        AppData(
          settings: data.settings,
          results: results,
          sync: SyncInfo(phase: SyncPhase.synced, lastSuccessfulAt: syncedAt),
        ),
      );
      for (final result in downloaded) {
        await ref.read(databaseProvider).upsertResult(result);
        if (ref.exists(dayProvider) && ref.read(dayProvider).hasValue) {
          await ref.read(dayProvider.notifier).recordExercise(result);
        }
      }
      final userId = await api.currentUserId();
      if (userId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'lastSuccessfulSync.$userId',
          syncedAt.toIso8601String(),
        );
      }
      return true;
    } catch (_) {
      data = state.requireValue;
      state = AsyncData(
        AppData(
          settings: data.settings,
          results: data.results,
          sync: SyncInfo(
            phase: SyncPhase.pending,
            lastSuccessfulAt: data.sync.lastSuccessfulAt,
          ),
        ),
      );
      return false;
    }
  }

  void markSignedOut() {
    ref.invalidate(dayProvider);
    unawaited(ReminderService().cancelActivities());
    final data = state.requireValue;
    state = AsyncData(
      AppData(
        settings: data.settings,
        results: data.results,
        sync: const SyncInfo(),
      ),
    );
  }

  Future<void> markSignedIn([String? userId]) async {
    if (userId != null) await ref.read(databaseProvider).claimGuestDay(userId);
    ref.invalidate(dayProvider);
    final data = state.requireValue;
    final prefs = await SharedPreferences.getInstance();
    final raw = userId == null
        ? null
        : prefs.getString('lastSuccessfulSync.$userId');
    state = AsyncData(
      AppData(
        settings: data.settings,
        results: data.results,
        sync: SyncInfo(
          phase: SyncPhase.pending,
          lastSuccessfulAt: raw == null ? null : DateTime.tryParse(raw),
        ),
      ),
    );
  }

  Future<void> speak(String text) async {
    if (!state.requireValue.settings.narration) return;
    await _tts.setSpeechRate(0.42);
    await _tts.stop();
    await _tts.speak(text);
  }
}
