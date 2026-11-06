import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';

class OylaApi {
  OylaApi({String? baseUrl})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl ?? _defaultBaseUrl(),
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      ) {
    _dio.interceptors.add(InterceptorsWrapper(onError: _retryAfterRefresh));
  }
  final Dio _dio;
  static const _secure = FlutterSecureStorage();
  Future<bool>? _refreshing;

  static String _defaultBaseUrl() {
    const configured = String.fromEnvironment('OYLA_API_URL');
    if (configured.isNotEmpty) return configured;
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8080/api/v1'
        : 'http://127.0.0.1:8080/api/v1';
  }

  Future<Map<String, dynamic>> youTube(
    String path,
    Map<String, dynamic> parameters,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/youtube/$path',
      queryParameters: parameters,
      options: Options(receiveTimeout: const Duration(seconds: 40)),
    );
    return response.data!;
  }

  Future<Map<String, dynamic>> connect([
    String path = '',
    Map<String, dynamic>? data,
    String method = 'GET',
  ]) async {
    final access = await _secure.read(key: 'accessToken');
    if (access == null) throw StateError('Sign in to use Connect');
    final response = await _dio.request<Map<String, dynamic>>(
      '/connect$path',
      data: data,
      options: Options(
        method: method,
        headers: {'Authorization': 'Bearer $access'},
      ),
    );
    return response.data ?? {};
  }

  Future<String?> requestCode(String email) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/code/request',
      data: {'email': email},
    );
    return response.data?['developmentCode'] as String?;
  }

  Future<void> verifyCode(String email, String code) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/code/verify',
      data: {'email': email, 'code': code},
    );
    await _storeTokens(response.data);
  }

  Future<bool> isSignedIn() async =>
      (await _secure.read(key: 'accessToken')) != null;

  Future<String?> currentUserId() => _secure.read(key: 'userId');

  Future<Map<String, dynamic>?> profile() async {
    final access = await _secure.read(key: 'accessToken');
    if (access == null) return null;
    final response = await _dio.get<Map<String, dynamic>>(
      '/me',
      options: Options(headers: {'Authorization': 'Bearer $access'}),
    );
    return response.data;
  }

  String _localOffset() {
    final minutes = DateTime.now().timeZoneOffset.inMinutes;
    final absolute = minutes.abs();
    return '${minutes < 0 ? '-' : '+'}${(absolute ~/ 60).toString().padLeft(2, '0')}:${(absolute % 60).toString().padLeft(2, '0')}';
  }

  Future<void> updateProfile({String? nickname, UserSettings? settings}) async {
    final access = await _secure.read(key: 'accessToken');
    if (access == null) return;
    await _dio.patch<void>(
      '/me',
      data: {
        if (nickname != null) 'nickname': nickname,
        if (settings != null) 'settingsJson': jsonEncode(settings.toJson()),
        'locale': 'en',
        'timezone': _localOffset(),
      },
      options: Options(headers: {'Authorization': 'Bearer $access'}),
    );
  }

  Future<void> logout() async {
    final refresh = await _secure.read(key: 'refreshToken');
    if (refresh != null) {
      try {
        await _dio.post<void>('/auth/logout', data: {'refreshToken': refresh});
      } on DioException {
        /* Local sign-out must still succeed. */
      }
    }
    await _secure.deleteAll();
  }

  Future<void> deleteAccount() async {
    await _authorizedDelete('/me');
    await _secure.deleteAll();
  }

  Future<Map<String, dynamic>> syncDayRecords(
    List<Map<String, dynamic>> records,
  ) async {
    Map<String, dynamic> response = {'records': [], 'conflicts': []};
    final conflicts = <dynamic>[];
    for (var start = 0; start < records.length || start == 0; start += 1000) {
      final end = (start + 1000).clamp(0, records.length);
      response = (await _authorizedPost<Map<String, dynamic>>(
        '/sync/day',
        data: {'records': records.sublist(start, end)},
      )).data!;
      conflicts.addAll(response['conflicts'] as List<dynamic>);
    }
    return {...response, 'conflicts': conflicts};
  }

  Future<List<ExerciseResult>> sync(List<ExerciseResult> results) async {
    final access = await _secure.read(key: 'accessToken');
    if (access == null) return const [];
    final prefs = await SharedPreferences.getInstance();
    var installationId = prefs.getString('installationId');
    installationId ??= const Uuid().v4();
    await prefs.setString('installationId', installationId);
    String localDate(DateTime date) =>
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final dailyGroups = <String, List<ExerciseResult>>{};
    for (final result in results.where((result) => !result.practice)) {
      dailyGroups.putIfAbsent(localDate(result.date), () => []).add(result);
    }
    final completedDates = dailyGroups.entries
        .where(
          (entry) =>
              entry.value.map((result) => result.type).toSet().length >= 3,
        )
        .map((entry) => entry.key)
        .toSet();
    String workoutId(String date) =>
        const Uuid().v5(Namespace.url.value, 'oyla:$installationId:$date');
    final userId = await _secure.read(key: 'userId') ?? 'unknown';
    final cursorKey = 'syncCursor.$userId';
    final cursor = prefs.getString(cursorKey);
    final body = {
      'cursor': cursor,
      'workouts': completedDates.map((date) {
        final rounds = dailyGroups[date]!
          ..sort((a, b) => a.date.compareTo(b.date));
        return {
          'id': workoutId(date),
          'installationId': installationId,
          'localDate': date,
          'startedAt': (rounds.first.startedAt ?? rounds.first.date)
              .toUtc()
              .toIso8601String(),
          'completedAt': rounds.last.date.toUtc().toIso8601String(),
          'completionState': 'COMPLETED',
        };
      }).toList(),
      'results': results
          .where(
            (r) => r.practice || completedDates.contains(localDate(r.date)),
          )
          .map(
            (r) => {
              'id': r.id,
              'workoutId': r.practice ? null : workoutId(localDate(r.date)),
              'installationId': installationId,
              'exerciseType': r.type.name,
              'difficulty': r.difficulty,
              'algorithmVersion': r.algorithmVersion,
              'startedAt':
                  (r.startedAt ?? r.date.subtract(const Duration(minutes: 1)))
                      .toUtc()
                      .toIso8601String(),
              'completedAt': r.date.toUtc().toIso8601String(),
              'localDate': localDate(r.date),
              'correctCount': r.correct,
              'attemptedCount': r.attempted,
              'score': r.score,
              'practice': r.practice,
            },
          )
          .toList(),
    };
    final response = await _dio.post<Map<String, dynamic>>(
      '/sync',
      data: body,
      options: Options(headers: {'Authorization': 'Bearer $access'}),
    );
    final next = response.data?['cursor'] as String?;
    if (next != null) await prefs.setString(cursorKey, next);
    final remote = response.data?['results'] as List<dynamic>? ?? const [];
    return remote.map((raw) {
      final item = raw as Map<String, dynamic>;
      return ExerciseResult(
        id: item['id'] as String,
        type: ExerciseType.values.byName(item['exerciseType'] as String),
        date: DateTime.parse(item['completedAt'] as String).toLocal(),
        correct: item['correctCount'] as int,
        attempted: item['attemptedCount'] as int,
        score: item['score'] as int,
        // localDate is intentionally represented by the completion DateTime in
        // the local model; the server retains it separately for friend views.
        difficulty: item['difficulty'] as int,
        algorithmVersion: item['algorithmVersion'] as int,
        startedAt: DateTime.parse(item['startedAt'] as String).toLocal(),
        workoutId: item['workoutId'] as String?,
        practice: item['practice'] as bool? ?? false,
      );
    }).toList();
  }

  Future<void> _authorizedDelete(String path) async {
    final access = await _secure.read(key: 'accessToken');
    await _dio.delete<void>(
      path,
      options: Options(headers: {'Authorization': 'Bearer $access'}),
    );
  }

  Future<Response<T>> _authorizedPost<T>(String path, {Object? data}) async {
    final access = await _secure.read(key: 'accessToken');
    return _dio.post<T>(
      path,
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $access'}),
    );
  }

  Future<void> _retryAfterRefresh(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final request = error.requestOptions;
    if (error.response?.statusCode != 401 ||
        request.extra['retried'] == true ||
        request.path.startsWith('/auth/')) {
      handler.next(error);
      return;
    }
    final refreshed = await (_refreshing ??= _refreshTokens());
    _refreshing = null;
    if (!refreshed) {
      handler.next(error);
      return;
    }
    request.extra['retried'] = true;
    request.headers['Authorization'] =
        'Bearer ${await _secure.read(key: 'accessToken')}';
    try {
      handler.resolve(await _dio.fetch<dynamic>(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<bool> _refreshTokens() async {
    final refresh = await _secure.read(key: 'refreshToken');
    if (refresh == null) return false;
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refresh},
      );
      await _storeTokens(response.data);
      return true;
    } on DioException {
      await _secure.deleteAll();
      return false;
    }
  }

  Future<void> _storeTokens(Map<String, dynamic>? data) async {
    await _secure.write(
      key: 'accessToken',
      value: data?['accessToken'] as String?,
    );
    await _secure.write(
      key: 'refreshToken',
      value: data?['refreshToken'] as String?,
    );
    if (data?['userId'] != null) {
      await _secure.write(key: 'userId', value: data!['userId'] as String);
    }
  }
}
