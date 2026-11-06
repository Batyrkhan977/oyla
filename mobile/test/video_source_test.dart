import 'package:flutter_test/flutter_test.dart';
import 'package:oyla/src/day_models.dart';
import 'package:oyla/src/video_source.dart';

void main() {
  test('normalizes video links without tracking or playlist context', () {
    for (final input in [
      'https://www.youtube.com/watch?v=abcdefghI_1&list=PLtest&t=15',
      ' https://youtu.be/abcdefghI_1?si=tracking ',
      'youtube.com/shorts/abcdefghI_1',
      'https://m.youtube.com/watch?v=abcdefghI_1',
      'https://www.youtube.com/embed/abcdefghI_1',
      'https://www.youtube.com/live/abcdefghI_1',
    ]) {
      expect(
        normalizeYouTubeUrl(input),
        'https://www.youtube.com/watch?v=abcdefghI_1',
        reason: input,
      );
    }
  });
  test('rejects other hosts, malformed IDs and non-video sources', () {
    for (final input in [
      '',
      'not a URL',
      'https://youtube.com.evil.test/watch?v=abcdefghI_1',
      'https://youtube.com@evil.test/watch?v=abcdefghI_1',
      'https://evil.test@youtube.com/watch?v=abcdefghI_1',
      'javascript://youtube.com/watch?v=abcdefghI_1',
      'https://www.youtube.com/watch?v=short',
      'https://youtube.com:8080/watch?v=abcdefghI_1',
      'https://youtube.com/playlist?list=PLtest',
      'https://youtube.com/@channel',
      'https://youtu.be/abcdefghI_1/extra',
    ]) {
      expect(normalizeYouTubeUrl(input), isNull, reason: input);
    }
  });
  test(
    'old routines remain timer-only; video survives storage and recommendations',
    () {
      const routine = Routine(
        id: 'walk',
        title: 'Walk',
        kind: ActivityKind.walking,
        weekdays: [1],
        minute: 540,
        duration: 10,
      );
      expect(Routine.fromJson(routine.toJson()).videoUrl, isNull);
      final withVideo = Routine.fromJson({
        ...routine.toJson(),
        'videoUrl': 'https://www.youtube.com/watch?v=abcdefghI_1',
      });
      expect(
        Routine.fromJson(withVideo.copyWith(duration: 20).toJson()).videoUrl,
        withVideo.videoUrl,
      );
      final occurrence = DayOccurrence(
        id: 'today',
        routine: withVideo,
        date: '2026-09-13',
        scheduledAt: DateTime(2026, 9, 13, 9),
      );
      expect(
        DayOccurrence.fromJson(occurrence.toJson()).routine.videoUrl,
        withVideo.videoUrl,
      );
    },
  );
}
