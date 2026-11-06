import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oyla/src/api.dart';
import 'package:oyla/src/app_state.dart';
import 'package:oyla/src/database.dart';
import 'package:oyla/src/day_models.dart';
import 'package:oyla/src/day_state.dart';
import 'package:oyla/src/youtube.dart';
import 'package:oyla/src/youtube_screens.dart';
import 'package:oyla/src/video_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Guest extends OylaApi {
  @override
  Future<bool> isSignedIn() async => false;
}

class FakeYouTube extends YouTubeClient {
  FakeYouTube() : super(Guest());
  int pages = 0;
  bool unavailable = false;
  final queries = <String>[];
  @override
  Future<YouTubePage<YouTubeChannel>> channels(
    String kind,
    String language, {
    String query = '',
    String? pageToken,
  }) async {
    queries.add('$kind:$query');
    if (unavailable) throw const YouTubeFailure('YOUTUBE_NOT_CONFIGURED');
    return YouTubePage([
      for (var i = 0; i < (query.isEmpty ? 3 : 1); i++)
        YouTubeChannel(
          id: 'channel$i',
          title: query.isEmpty ? 'Gentle channel $i' : query,
        ),
    ], null);
  }

  @override
  Future<YouTubePage<YouTubeVideo>> videos(
    String channelId,
    int minutes, {
    String? pageToken,
  }) async {
    pages++;
    if (pageToken == null) return const YouTubePage([], 'older');
    return YouTubePage([
      YouTubeVideo(
        id: 'abcdefghijk',
        title: 'A full session',
        channelId: channelId,
        channelTitle: 'Gentle channel 0',
        seconds: minutes * 60,
      ),
    ], null);
  }
}

void main() {
  late OylaDatabase db;
  late ProviderContainer container;
  late FakeYouTube youtube;
  Future<void> setup(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('oyla/reminders'),
          (call) async => call.method == 'pendingActions' ? [] : null,
        );
    db = OylaDatabase(NativeDatabase.memory());
    youtube = FakeYouTube();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        apiProvider.overrideWithValue(Guest()),
        youtubeProvider.overrideWithValue(youtube),
      ],
    );
    await tester.runAsync(() async {
      await container.read(appStateProvider.future);
      await container.read(dayProvider.future);
    });
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> cleanup(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.runAsync(db.close);
  }

  Future<void> tap(WidgetTester tester, String text) async {
    final finder = find.text(text);
    await tester.scrollUntilVisible(
      finder,
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('video previews open the Android player with a clean video ID', (
    tester,
  ) async {
    await setup(tester);
    final calls = <MethodCall>[];
    const player = MethodChannel('oyla/youtube');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(player, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(player, null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: VideoSourcePicker(
            initialUrl: 'https://youtu.be/abcdefghI_1?list=ignored',
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Preview video'));
    await tester.tap(find.text('Preview video'));
    await tester.pumpAndSettle();
    expect(calls.single.method, 'play');
    expect(calls.single.arguments, {
      'videoId': 'abcdefghI_1',
      'language': 'en',
    });
    await cleanup(tester);
  });
  testWidgets(
    'three recommendations, custom search, favorite save and reopen',
    (tester) async {
      await setup(tester);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  child: const Text('Open channels'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const YouTubeChannelPicker(kind: ActivityKind.yoga),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open channels'));
      await settle(tester);
      expect(find.byType(CheckboxListTile), findsNWidgets(3));
      expect(youtube.queries.single, 'yoga:');
      await tap(tester, 'Gentle channel 0');
      await tap(tester, 'Use favorite channels');
      await settle(tester);
      final favorites =
          container.read(dayProvider).requireValue.settings['youtubeFavorites']
              as Map;
      expect((favorites['yoga'] as List).single['id'], 'channel0');
      await tester.tap(find.text('Open channels'));
      await settle(tester);
      expect(
        tester
            .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
            .where((v) => v.value == true)
            .length,
        1,
      );
      await tester.enterText(find.byType(TextField), 'A different teacher');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await settle(tester);
      expect(youtube.queries.last, 'yoga:A different teacher');
      expect(find.text('A different teacher'), findsWidgets);
      expect(tester.takeException(), isNull);
      await cleanup(tester);
    },
  );
  testWidgets(
    'session searches older uploads and retains selection after reopening',
    (tester) async {
      await setup(tester);
      await tester.runAsync(() async {
        final c = container.read(dayProvider.notifier);
        await c.saveRoutine(
          const Routine(
            id: 'yoga',
            title: 'Yoga',
            kind: ActivityKind.yoga,
            weekdays: [1, 2, 3, 4, 5, 6, 7],
            minute: 540,
            duration: 15,
            youtubeChannels: [
              YouTubeChannel(id: 'channel0', title: 'Gentle channel 0'),
            ],
          ),
        );
        await c.initializeDay();
        await c.act(
          container.read(dayProvider).requireValue.occurrences.single.id,
          OccurrenceStatus.started,
        );
      });
      Widget screen() => UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, child) => Scaffold(
              body: ListView(
                children: [
                  YouTubeSession(
                    occurrence: ref
                        .watch(dayProvider)
                        .requireValue
                        .occurrences
                        .single,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(screen());
      await settle(tester);
      expect(youtube.pages, 2);
      expect(
        container
            .read(dayProvider)
            .requireValue
            .occurrences
            .single
            .sessionVideo!
            .seconds,
        900,
      );
      expect(find.text('A full session'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(screen());
      await settle(tester);
      expect(youtube.pages, 2);
      expect(find.text('A full session'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await cleanup(tester);
    },
  );
  testWidgets('missing key is explained on a narrow display with large text', (
    tester,
  ) async {
    await setup(tester);
    youtube.unavailable = true;
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const YouTubeChannelPicker(kind: ActivityKind.yoga),
        ),
      ),
    );
    await settle(tester);
    await tester.scrollUntilVisible(
      find.text(
        'YouTube search is not connected yet. You can still paste a video link.',
      ),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
    await cleanup(tester);
  });
}
