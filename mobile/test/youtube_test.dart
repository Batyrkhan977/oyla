import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:oyla/src/day_models.dart';
import 'package:oyla/src/youtube.dart';

void main() {
  YouTubeVideo video(String id, int seconds, {String channel = 'channel'}) =>
      YouTubeVideo(
        id: id,
        title: id,
        channelId: channel,
        channelTitle: channel,
        seconds: seconds,
      );
  test(
    'minimum duration is exact, and random selection stays in the selected channel',
    () {
      final videos = [
        video('short', 899),
        video('exact', 900),
        video('long', 1000),
        video('other', 1200, channel: 'other'),
      ];
      final selected = {
        for (var seed = 0; seed < 40; seed++)
          chooseSessionVideo(videos, 'channel', 15, Random(seed))!.id,
      };
      expect(selected, {'exact', 'long'});
      expect(chooseSessionVideo(videos, 'channel', 20, Random(1)), isNull);
      expect(
        chooseSessionVideo(
          videos,
          'channel',
          15,
          Random(1),
          previousId: 'exact',
        )!.id,
        'long',
      );
    },
  );
  test(
    'favorites and selected session video survive persistence and status changes',
    () {
      const routine = Routine(
        id: 'r',
        title: 'Yoga',
        kind: ActivityKind.yoga,
        weekdays: [1],
        minute: 540,
        duration: 15,
        youtubeChannels: [YouTubeChannel(id: 'channel', title: 'Yoga channel')],
      );
      final occurrence = DayOccurrence(
        id: 'o',
        routine: routine,
        date: '2026-09-13',
        scheduledAt: DateTime(2026, 9, 13),
        sessionVideo: video('exact', 900),
      );
      final restored = DayOccurrence.fromJson(
        occurrence.toJson(),
      ).transition(OccurrenceStatus.completed, DateTime(2026, 9, 13, 10));
      expect(restored.routine.youtubeChannels.single.title, 'Yoga channel');
      expect(restored.sessionVideo!.id, 'exact');
      expect(
        restored.routine.copyWith(duration: 20).youtubeChannels.single.id,
        'channel',
      );
      expect(
        routine.copyWith(kind: ActivityKind.walking).youtubeChannels,
        isEmpty,
      );
      final legacy = routine.toJson()..remove('youtubeChannels');
      expect(Routine.fromJson(legacy).youtubeChannels, isEmpty);
    },
  );
}
