import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_state.dart';
import 'day_models.dart';
import 'day_screens.dart';
import 'day_state.dart';
import 'models.dart';
import 'video_source.dart';
import 'youtube.dart';

String youtubeError(WidgetRef ref, Object error) {
  final code = error is YouTubeFailure ? error.code : '';
  return switch (code) {
    'YOUTUBE_NOT_CONFIGURED' => w(
      ref,
      'YouTube search is not connected yet. You can still paste a video link.',
      'YouTube іздеуі әлі қосылмаған. Видео сілтемесін қоюға болады.',
      'Поиск YouTube ещё не подключён. Можно вставить ссылку на видео.',
    ),
    'YOUTUBE_LIMITED' => w(
      ref,
      'YouTube is busy. Please try again in a few minutes.',
      'YouTube бос емес. Бірнеше минуттан кейін қайталаңыз.',
      'YouTube временно недоступен. Повторите через несколько минут.',
    ),
    _ => w(
      ref,
      'Could not reach YouTube. Check your connection and try again.',
      'YouTube-қа қосылмады. Байланысты тексеріп, қайталаңыз.',
      'Не удалось подключиться к YouTube. Проверьте соединение и повторите.',
    ),
  };
}

class YouTubeChannelPicker extends ConsumerStatefulWidget {
  const YouTubeChannelPicker({
    super.key,
    required this.kind,
    this.initial = const [],
  });
  final ActivityKind kind;
  final List<YouTubeChannel> initial;
  @override
  ConsumerState<YouTubeChannelPicker> createState() =>
      _YouTubeChannelPickerState();
}

class _YouTubeChannelPickerState extends ConsumerState<YouTubeChannelPicker> {
  final search = TextEditingController();
  final random = Random();
  final selected = <String, YouTubeChannel>{};
  List<YouTubeChannel> results = [];
  String query = '', language = 'en';
  String? nextPage, error;
  bool loading = false, saving = false;
  int generation = 0;
  @override
  void initState() {
    super.initState();
    final settings = ref.read(dayProvider).valueOrNull?.settings;
    final favorites = settings?['youtubeFavorites'];
    final saved = favorites is Map ? favorites[widget.kind.name] : null;
    for (final c
        in widget.initial.isNotEmpty
            ? widget.initial
            : (saved is List
                  ? saved.map(
                      (v) => YouTubeChannel.fromJson(
                        Map<String, dynamic>.from(v as Map),
                      ),
                    )
                  : <YouTubeChannel>[])) {
      selected[c.id] = c;
    }
    language = switch (ref
        .read(appStateProvider)
        .requireValue
        .settings
        .language) {
      AppLanguage.english => 'en',
      AppLanguage.kazakh => 'kk',
      AppLanguage.russian => 'ru',
    };
    load();
  }

  @override
  void dispose() {
    generation++;
    search.dispose();
    super.dispose();
  }

  Future<void> load({bool more = false}) async {
    final request = ++generation;
    setState(() {
      loading = true;
      error = null;
      if (!more) {
        results = [];
        nextPage = null;
        query = search.text.trim();
      }
    });
    try {
      final page = await ref
          .read(youtubeProvider)
          .channels(
            widget.kind.name,
            language,
            query: query,
            pageToken: more ? nextPage : null,
          );
      if (!mounted || request != generation) return;
      setState(() {
        final combined = {
          for (final c in [...results, ...page.items]) c.id: c,
        };
        results = combined.values.toList();
        nextPage = page.nextPageToken;
      });
    } catch (e) {
      if (mounted && request == generation) {
        setState(() => error = youtubeError(ref, e));
      }
    } finally {
      if (mounted && request == generation) setState(() => loading = false);
    }
  }

  void toggle(YouTubeChannel c) {
    if (selected.containsKey(c.id)) {
      setState(() => selected.remove(c.id));
      return;
    }
    if (selected.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            w(
              ref,
              'Choose up to five favorite channels.',
              'Беске дейін таңдаулы арна таңдаңыз.',
              'Выберите до пяти любимых каналов.',
            ),
          ),
        ),
      );
      return;
    }
    setState(() => selected[c.id] = c);
  }

  Future<void> save() async {
    if (saving || selected.isEmpty) return;
    setState(() => saving = true);
    try {
      final previous = ref
          .read(dayProvider)
          .requireValue
          .settings['youtubeFavorites'];
      await ref.read(dayProvider.notifier).setSettings({
        'youtubeFavorites': {
          if (previous is Map) ...Map<String, dynamic>.from(previous),
          widget.kind.name: selected.values.map((c) => c.toJson()).toList(),
        },
      });
      if (mounted) Navigator.pop(context, selected.values.toList());
    } catch (e) {
      if (mounted) {
        setState(
          () => error = w(
            ref,
            'Could not save favorites. Please try again.',
            'Таңдаулылар сақталмады. Қайталаңыз.',
            'Не удалось сохранить избранное. Повторите.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget channel(YouTubeChannel c) => Card(
    child: CheckboxListTile(
      value: selected.containsKey(c.id),
      onChanged: saving ? null : (_) => toggle(c),
      title: Text(c.title),
      subtitle: Text(
        words(ref, 'YouTube channel', 'YouTube арнасы', 'Канал YouTube'),
      ),
      controlAffinity: ListTileControlAffinity.trailing,
    ),
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          words(ref, 'Choose channels', 'Арналарды таңдау', 'Выбрать каналы'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            kindLabel(widget.kind, lang(ref)),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            words(
              ref,
              'Pick your favorites. Each session uses a random video from one of these channels.',
              'Таңдаулы арналарды таңдаңыз. Әр сабаққа осы арналардың бірінен кездейсоқ видео беріледі.',
              'Выберите любимые каналы. На каждое занятие — случайное видео из одного из них.',
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: search,
            maxLength: 100,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => load(),
            decoration: InputDecoration(
              labelText: words(
                ref,
                'Search YouTube channels',
                'YouTube арналарын іздеу',
                'Поиск каналов YouTube',
              ),
              suffixIcon: IconButton(
                tooltip: words(ref, 'Search', 'Іздеу', 'Найти'),
                icon: const Icon(Icons.search),
                onPressed: saving ? null : () => load(),
              ),
            ),
          ),
          if (selected.isNotEmpty) ...[
            Text(
              words(
                ref,
                'My favorite channels',
                'Таңдаулы арналарым',
                'Мои любимые каналы',
              ),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            for (final c in selected.values.toList()) channel(c),
            const SizedBox(height: 20),
          ],
          Text(
            query.isEmpty
                ? words(
                    ref,
                    'Recommended channels',
                    'Ұсынылатын арналар',
                    'Рекомендуемые каналы',
                  )
                : words(
                    ref,
                    'Search results',
                    'Іздеу нәтижелері',
                    'Результаты поиска',
                  ),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          for (final c in results.where((c) => !selected.containsKey(c.id)))
            channel(c),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!loading && error == null && results.isEmpty)
            Text(
              words(
                ref,
                'No channels found. Try another search.',
                'Арна табылмады. Басқа сұрау енгізіңіз.',
                'Каналы не найдены. Попробуйте другой запрос.',
              ),
            ),
          if (error != null) ...[
            Text(error!, semanticsLabel: error),
            TextButton(
              onPressed: () => load(more: nextPage != null),
              child: Text(words(ref, 'Try again', 'Қайталау', 'Повторить')),
            ),
          ],
          if (!loading && nextPage != null)
            TextButton(
              onPressed: () => load(more: true),
              child: Text(
                words(ref, 'More channels', 'Тағы арналар', 'Ещё каналы'),
              ),
            ),
          if (results.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.shuffle),
              onPressed: saving
                  ? null
                  : () {
                      final pool = results
                          .where((c) => !selected.containsKey(c.id))
                          .toList();
                      if (pool.isNotEmpty) {
                        toggle(pool[random.nextInt(pool.length)]);
                      }
                    },
              label: Text(
                words(
                  ref,
                  'Pick a random channel',
                  'Кездейсоқ арна таңдау',
                  'Выбрать случайный канал',
                ),
              ),
            ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: selected.isEmpty || saving ? null : save,
            child: Text(
              words(
                ref,
                'Use favorite channels',
                'Таңдаулы арналарды қолдану',
                'Использовать любимые каналы',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// The selected video belongs to the occurrence, not a transient screen state.
class YouTubeSession extends ConsumerStatefulWidget {
  const YouTubeSession({super.key, required this.occurrence});
  final DayOccurrence occurrence;
  @override
  ConsumerState<YouTubeSession> createState() => _YouTubeSessionState();
}

class _YouTubeSessionState extends ConsumerState<YouTubeSession> {
  final random = Random();
  YouTubeChannel? channel;
  String? nextPage, error;
  bool loading = false, exhausted = false, timerOnly = false;
  int generation = 0;
  @override
  void initState() {
    super.initState();
    if (widget.occurrence.sessionVideo == null) findVideo();
  }

  @override
  void dispose() {
    generation++;
    super.dispose();
  }

  Future<void> findVideo({bool more = false}) async {
    final request = ++generation;
    final o = widget.occurrence;
    if (!more) {
      final previous = channel?.id ?? o.sessionVideo?.channelId;
      final pool = o.routine.youtubeChannels
          .where(
            (c) => o.routine.youtubeChannels.length == 1 || c.id != previous,
          )
          .toList();
      channel = pool[random.nextInt(pool.length)];
      nextPage = null;
    }
    setState(() {
      loading = true;
      error = null;
      exhausted = false;
      timerOnly = false;
    });
    try {
      // Search progressively. Long channels can be continued without a timeout or
      // an incorrect claim that no qualifying video exists anywhere on the channel.
      for (var batch = 0; batch < 10; batch++) {
        final page = await ref
            .read(youtubeProvider)
            .videos(channel!.id, o.routine.duration, pageToken: nextPage);
        if (!mounted || request != generation) return;
        nextPage = page.nextPageToken;
        final video = chooseSessionVideo(
          page.items,
          channel!.id,
          o.routine.duration,
          random,
          previousId: o.sessionVideo?.id,
        );
        if (video != null) {
          await ref.read(dayProvider.notifier).saveSessionVideo(o.id, video);
          nextPage = null;
          return;
        }
        if (nextPage == null) {
          setState(() => exhausted = true);
          return;
        }
      }
    } catch (e) {
      if (mounted && request == generation) {
        setState(() => error = youtubeError(ref, e));
      }
    } finally {
      if (mounted && request == generation) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.occurrence.sessionVideo;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              words(ref, "Today's video", 'Бүгінгі видео', 'Видео на сегодня'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (!timerOnly && video != null) ...[
              const SizedBox(height: 12),
              if (video.thumbnail.startsWith('https://'))
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    video.thumbnail,
                    height: 160,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                    errorBuilder: (_, e, stack) =>
                        const Icon(Icons.ondemand_video, size: 48),
                  ),
                ),
              Text(video.title),
              Text('${video.durationLabel} · ${video.channelTitle} · YouTube'),
              FilledButton.icon(
                onPressed: () => openActivityVideo(context, ref, video.url),
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  words(
                    ref,
                    'Open YouTube video',
                    'YouTube видеосын ашу',
                    'Открыть видео на YouTube',
                  ),
                ),
              ),
              Text(
                words(
                  ref,
                  'Return here after the video to record what you completed.',
                  'Не орындағаныңызды белгілеу үшін видеодан кейін осында оралыңыз.',
                  'После видео вернитесь сюда и отметьте, сколько удалось выполнить.',
                ),
              ),
            ],
            if (loading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
              Text(
                words(
                  ref,
                  'Finding a video long enough for your session…',
                  'Сабақ ұзақтығына сәйкес видео ізделуде…',
                  'Ищем видео не короче вашего занятия…',
                ),
              ),
            ],
            if (error != null && !timerOnly) Text(error!),
            if (exhausted && !timerOnly)
              Text(
                words(
                  ref,
                  'No available video on this channel is long enough. Try another channel or use the timer.',
                  'Бұл арнада жеткілікті ұзақ видео жоқ. Басқа арнаны не таймерді таңдаңыз.',
                  'На этом канале нет доступного видео нужной длины. Выберите другой канал или таймер.',
                ),
              ),
            if (!loading && !timerOnly && nextPage != null && !exhausted)
              TextButton(
                onPressed: () => findVideo(more: true),
                child: Text(
                  words(
                    ref,
                    'Look through older videos',
                    'Ескі видеолардан іздеу',
                    'Посмотреть более старые видео',
                  ),
                ),
              ),
            if (!loading)
              TextButton.icon(
                icon: const Icon(Icons.shuffle),
                onPressed: () => findVideo(),
                label: Text(
                  words(
                    ref,
                    'Choose another video',
                    'Басқа видео таңдау',
                    'Выбрать другое видео',
                  ),
                ),
              ),
            if (!timerOnly)
              TextButton(
                onPressed: () => setState(() {
                  generation++;
                  loading = false;
                  timerOnly = true;
                }),
                child: Text(
                  words(
                    ref,
                    'Do without video',
                    'Видеосыз орындау',
                    'Заниматься без видео',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
