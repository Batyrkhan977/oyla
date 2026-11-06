import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api.dart';
import 'app_state.dart';

class YouTubeChannel {
  const YouTubeChannel({
    required this.id,
    required this.title,
    this.thumbnail = '',
  });
  final String id, title, thumbnail;
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'thumbnail': thumbnail,
  };
  factory YouTubeChannel.fromJson(Map<String, dynamic> j) => YouTubeChannel(
    id: j['id'] as String,
    title: j['title'] as String,
    thumbnail: j['thumbnail'] as String? ?? '',
  );
}

class YouTubeVideo {
  const YouTubeVideo({
    required this.id,
    required this.title,
    required this.channelId,
    required this.channelTitle,
    required this.seconds,
    this.thumbnail = '',
  });
  final String id, title, channelId, channelTitle, thumbnail;
  final int seconds;
  String get url => 'https://www.youtube.com/watch?v=$id';
  String get durationLabel =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'channelId': channelId,
    'channelTitle': channelTitle,
    'seconds': seconds,
    'thumbnail': thumbnail,
  };
  factory YouTubeVideo.fromJson(Map<String, dynamic> j) => YouTubeVideo(
    id: j['id'] as String,
    title: j['title'] as String,
    channelId: j['channelId'] as String,
    channelTitle: j['channelTitle'] as String,
    seconds: j['seconds'] as int,
    thumbnail: j['thumbnail'] as String? ?? '',
  );
}

class YouTubePage<T> {
  const YouTubePage(this.items, this.nextPageToken);
  final List<T> items;
  final String? nextPageToken;
}

class YouTubeFailure implements Exception {
  const YouTubeFailure(this.code);
  final String code;
}

final youtubeProvider = Provider(
  (ref) => YouTubeClient(ref.watch(apiProvider)),
);

class YouTubeClient {
  YouTubeClient(this.api);
  final OylaApi api;
  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, dynamic> params,
  ) async {
    try {
      return await api.youTube(path, params);
    } on DioException catch (e) {
      final body = e.response?.data;
      throw YouTubeFailure(
        body is Map ? body['code'] as String? ?? 'OFFLINE' : 'OFFLINE',
      );
    }
  }

  Future<YouTubePage<YouTubeChannel>> channels(
    String kind,
    String language, {
    String query = '',
    String? pageToken,
  }) async {
    final j = await _get('channels', {
      'kind': kind,
      'language': language,
      'q': query,
      if (pageToken != null) 'pageToken': pageToken,
    });
    return YouTubePage(
      (j['items'] as List)
          .map(
            (v) => YouTubeChannel.fromJson(Map<String, dynamic>.from(v as Map)),
          )
          .toList(),
      j['nextPageToken'] as String?,
    );
  }

  Future<YouTubePage<YouTubeVideo>> videos(
    String channelId,
    int minutes, {
    String? pageToken,
  }) async {
    final j = await _get('videos', {
      'channelId': channelId,
      'minimumMinutes': minutes,
      if (pageToken != null) 'pageToken': pageToken,
    });
    return YouTubePage(
      (j['items'] as List)
          .map(
            (v) => YouTubeVideo.fromJson(Map<String, dynamic>.from(v as Map)),
          )
          .toList(),
      j['nextPageToken'] as String?,
    );
  }
}

// Check the threshold again on the client; never round up a short video.
YouTubeVideo? chooseSessionVideo(
  List<YouTubeVideo> videos,
  String channelId,
  int minutes,
  Random random, {
  String? previousId,
}) {
  final eligible = videos
      .where((v) => v.channelId == channelId && v.seconds >= minutes * 60)
      .toList();
  if (eligible.length > 1) eligible.removeWhere((v) => v.id == previousId);
  return eligible.isEmpty ? null : eligible[random.nextInt(eligible.length)];
}
