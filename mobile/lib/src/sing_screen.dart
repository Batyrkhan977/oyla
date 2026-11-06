import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'day_screens.dart';
import 'day_state.dart';
import 'media.dart';
import 'models.dart';
import 'song_recordings.dart';
import 'video_source.dart';

/// Publication is explicit. Traditional repertoire must carry source-specific
/// composition, lyrics and recording clearance before being added here.
class Song {
  const Song(
    this.id,
    this.title,
    this.lines,
    this.notes, {
    required this.author,
    required this.source,
    required this.rightsStatus,
    required this.licenseType,
    required this.approvedForPublication,
  });
  final String id, title, author, source, rightsStatus, licenseType;
  final List<String> lines;
  final List<List<int>> notes;
  final bool approvedForPublication;
}

const songCatalog = [
  Song(
    'morning',
    'Таңғы әуен',
    [
      'Таңғы самал, ашық аспан,',
      'Жаңа күнді қарсы алам.',
      'Әуеніме үн қосамын,',
      'Бүгін асықпай ән салам.',
    ],
    [
      [60, 64, 67, 64],
      [62, 65, 69, 65],
      [64, 67, 72, 67],
      [65, 64, 62, 60],
    ],
    author: 'ÖmirAI',
    source: 'Original ÖmirAI words, melody and synthesized accompaniment, 2026',
    rightsStatus: 'original',
    licenseType: 'ÖmirAI original content',
    approvedForPublication: true,
  ),
];

class PracticeSongScreen extends ConsumerStatefulWidget {
  const PracticeSongScreen({super.key});
  @override
  ConsumerState<PracticeSongScreen> createState() => _SingState();
}

class _SingState extends ConsumerState<PracticeSongScreen>
    with WidgetsBindingObserver {
  final song = songCatalog.firstWhere((s) => s.approvedForPublication);
  int line = 0, mode = 0, token = 0;
  double tempo = 1;
  bool playing = false, hints = false, reveal = false, recording = false;
  String? error;
  final watch = Stopwatch();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    token++;
    watch.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) stop();
  }

  void stop() {
    token++;
    watch.stop();
    if (mounted) setState(() => playing = false);
  }

  Future<void> play() async {
    final generation = ++token;
    watch.start();
    setState(() {
      playing = true;
      error = null;
    });
    try {
      do {
        for (final note in song.notes[line]) {
          if (!mounted || generation != token) return;
          await OmirMedia.note(note, milliseconds: (600 / tempo).round());
        }
        if (!mounted || generation != token) return;
        if (mode == 2) break;
        if (line == song.lines.length - 1) break;
        setState(() {
          line++;
          reveal = false;
        });
      } while (true);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = words(
            ref,
            'Audio is unavailable on this device.',
            'Бұл құрылғыда дыбыс қолжетімсіз.',
            'Звук на этом устройстве недоступен.',
          ),
        );
      }
    }
    if (mounted && generation == token) {
      watch.stop();
      setState(() => playing = false);
    }
  }

  Future<void> finish() async {
    stop();
    setState(() => recording = true);
    try {
      await ref
          .read(dayProvider.notifier)
          .recordModuleSession('sing:${song.id}', watch.elapsed.inSeconds, 1);
      watch.reset();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              words(
                ref,
                'Session saved',
                'Сабақ сақталды',
                'Занятие сохранено',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => recording = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(words(ref, 'Sing', 'Ән салайық', 'Петь'))),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(song.title, style: Theme.of(context).textTheme.headlineMedium),
        Text(
          words(
            ref,
            'An original song for offline practice.',
            'Интернетсіз жаттығуға арналған төл ән.',
            'Авторская песня для занятий без интернета.',
          ),
        ),
        for (var m = 0; m < 3; m++)
          ListTile(
            selected: mode == m,
            leading: Icon(
              mode == m ? Icons.radio_button_checked : Icons.radio_button_off,
            ),
            onTap: playing ? null : () => setState(() => mode = m),
            title: Text(
              [
                words(ref, 'Listen', 'Тыңдау', 'Слушать'),
                words(ref, 'Sing together', 'Бірге айту', 'Петь вместе'),
                words(
                  ref,
                  'Repeat verse',
                  'Шумақты қайталау',
                  'Повторить куплет',
                ),
              ][m],
            ),
          ),
        for (var i = 0; i < song.lines.length; i++)
          Semantics(
            selected: i == line,
            liveRegion: i == line,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: i == line
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : null,
                borderRadius: BorderRadius.circular(16),
                border: i == line
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                    : null,
              ),
              child: Text(
                hints && !reveal
                    ? song.lines[i].replaceFirst(RegExp(r'\S+$'), '…')
                    : song.lines[i],
                style: const TextStyle(fontSize: 26, height: 1.5),
              ),
            ),
          ),
        SwitchListTile(
          title: Text(
            words(
              ref,
              'Optional lyric hints',
              'Мәтін кеңестері',
              'Подсказки текста',
            ),
          ),
          value: hints,
          onChanged: (v) => setState(() => hints = v),
        ),
        if (hints)
          OutlinedButton(
            onPressed: () => setState(() => reveal = !reveal),
            child: Text(
              words(
                ref,
                'Show / hide words',
                'Сөздерді көрсету / жасыру',
                'Показать / скрыть слова',
              ),
            ),
          ),
        Text(
          '${words(ref, 'Tempo', 'Қарқын', 'Темп')}: ${tempo.toStringAsFixed(1)}×',
        ),
        Slider(
          value: tempo,
          min: .5,
          max: 1.5,
          divisions: 4,
          label: '$tempo×',
          onChanged: playing ? null : (v) => setState(() => tempo = v),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: playing ? stop : play,
              child: Text(
                playing
                    ? words(ref, 'Pause', 'Кідіріс', 'Пауза')
                    : words(ref, 'Play', 'Ойнату', 'Воспроизвести'),
              ),
            ),
            OutlinedButton(
              onPressed: playing
                  ? null
                  : () => setState(
                      () => line =
                          (line + song.lines.length - 1) % song.lines.length,
                    ),
              child: Text(
                words(ref, 'Previous line', 'Алдыңғы жол', 'Предыдущая строка'),
              ),
            ),
            OutlinedButton(
              onPressed: playing
                  ? null
                  : () => setState(() => line = (line + 1) % song.lines.length),
              child: Text(
                words(ref, 'Next line', 'Келесі жол', 'Следующая строка'),
              ),
            ),
            FilledButton(
              onPressed: recording ? null : finish,
              child: Text(
                words(
                  ref,
                  'Finish session',
                  'Сабақты аяқтау',
                  'Завершить занятие',
                ),
              ),
            ),
          ],
        ),
        if (error != null) Text(error!),
        Text(
          words(
            ref,
            'No microphone, recording or voice score.',
            'Микрофон, аудиожазба және дауыс бағасы жоқ.',
            'Без микрофона, записи и оценки голоса.',
          ),
        ),
        ExpansionTile(
          title: Text(
            words(
              ref,
              'Content rights',
              'Мазмұн құқықтары',
              'Права на материал',
            ),
          ),
          children: [
            Text(
              words(
                ref,
                'Original ÖmirAI words, melody and synthesized accompaniment, 2026. Included for practice in ÖmirAI.',
                'ÖmirAI төл мәтіні, әуені және синтезделген сүйемелдеуі, 2026. ÖmirAI ішінде жаттығуға арналған.',
                'Оригинальные слова, мелодия и синтезированный аккомпанемент ÖmirAI, 2026. Для занятий в ÖmirAI.',
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class SingScreen extends ConsumerStatefulWidget {
  const SingScreen({super.key});
  @override
  ConsumerState<SingScreen> createState() => _SingCatalogState();
}

class _SingCatalogState extends ConsumerState<SingScreen> {
  String query = '';
  AppLanguage? filter;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(words(ref, 'Sing', 'Ән салайық', 'Петь'))),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          words(ref, 'Choose a song', 'Ән таңдаңыз', 'Выберите песню'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text(
          words(
            ref,
            'Listen and sing along with a recording. Internet is required.',
            'Жазбаны тыңдап, бірге ән айтыңыз. Интернет қажет.',
            'Слушайте запись и пойте вместе. Нужен интернет.',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: (value) => setState(() => query = value),
          decoration: InputDecoration(
            labelText: words(
              ref,
              'Search songs',
              'Әндерді іздеу',
              'Поиск песен',
            ),
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final entry in <(AppLanguage?, String)>[
              (null, words(ref, 'All', 'Барлығы', 'Все')),
              (
                AppLanguage.kazakh,
                words(ref, 'Kazakh', 'Қазақша', 'Казахские'),
              ),
              (AppLanguage.russian, words(ref, 'Russian', 'Орысша', 'Русские')),
            ])
              ChoiceChip(
                label: Text(entry.$2),
                selected: filter == entry.$1,
                onSelected: (_) => setState(() => filter = entry.$1),
              ),
          ],
        ),
        for (final language in [AppLanguage.kazakh, AppLanguage.russian])
          if ((filter == null || filter == language) &&
              songRecordings.any(
                (s) => s.language == language && s.matches(query),
              )) ...[
            const SizedBox(height: 24),
            Text(
              language == AppLanguage.kazakh
                  ? words(
                      ref,
                      'Kazakh songs',
                      'Қазақ әндері',
                      'Казахские песни',
                    )
                  : words(ref, 'Russian songs', 'Орыс әндері', 'Русские песни'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            for (final song in songRecordings)
              if (song.language == language && song.matches(query))
                Card(
                  child: ListTile(
                    key: ValueKey('song:${song.id}'),
                    title: Text(song.title),
                    subtitle: Text(
                      '${song.transliteration} · ${song.performer}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SongRecordingScreen(song: song),
                      ),
                    ),
                  ),
                ),
          ],
        if (!songRecordings.any(
          (s) => (filter == null || s.language == filter) && s.matches(query),
        ))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              words(
                ref,
                'No songs found. Try another title.',
                'Ән табылмады. Басқа атауды енгізіңіз.',
                'Песни не найдены. Введите другое название.',
              ),
            ),
          ),
        const Divider(height: 32),
        ListTile(
          title: Text(
            words(
              ref,
              'Offline practice',
              'Интернетсіз жаттығу',
              'Занятие без интернета',
            ),
          ),
          subtitle: Text(songCatalog.first.title),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const PracticeSongScreen()),
          ),
        ),
      ],
    ),
  );
}

class SongRecordingScreen extends ConsumerWidget {
  const SongRecordingScreen({super.key, required this.song});
  final SongRecording song;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: Text(song.title)),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(song.title, style: Theme.of(context).textTheme.headlineMedium),
        Text(song.transliteration),
        const SizedBox(height: 16),
        Text(
          '${words(ref, 'Performer / channel', 'Орындаушы / арна', 'Исполнитель / канал')}: ${song.performer}',
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => openActivityVideo(
            context,
            ref,
            song.videoUrl,
            songTitle: song.title,
            alternativeVideoIds: song.alternatives
                .map((a) => a.videoId)
                .toList(),
          ),
          icon: const Icon(Icons.play_arrow),
          label: Text(
            words(
              ref,
              'Listen and sing along',
              'Тыңдап, бірге ән айту',
              'Слушать и петь вместе',
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () =>
              openActivityVideo(context, ref, song.videoUrl, external: true),
          icon: const Icon(Icons.open_in_new),
          label: Text(
            words(
              ref,
              'Open in YouTube',
              'YouTube-та ашу',
              'Открыть в YouTube',
            ),
          ),
        ),
        if (song.alternatives.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            words(ref, 'Other recordings', 'Басқа жазбалар', 'Другие записи'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          for (final alternative in song.alternatives)
            ListTile(
              title: Text(alternative.performer),
              leading: const Icon(Icons.play_circle_outline),
              onTap: () => openActivityVideo(
                context,
                ref,
                alternative.videoUrl,
                songTitle: song.title,
                alternativeVideoIds: [song.videoId],
              ),
            ),
        ],
        const SizedBox(height: 16),
        Text(
          words(
            ref,
            'Use the video controls to pause or repeat a part. Recordings play inside ÖmirAI on Android and in YouTube or your browser on other devices. Internet is required.',
            'Кідірту немесе бөлікті қайталау үшін видео басқару батырмаларын пайдаланыңыз. Android-та жазба ÖmirAI ішінде, басқа құрылғыларда YouTube не браузерде ойнатылады. Интернет қажет.',
            'Используйте управление видео, чтобы поставить запись на паузу или повторить фрагмент. На Android запись открывается в ÖmirAI, на других устройствах — в YouTube или браузере. Нужен интернет.',
          ),
        ),
      ],
    ),
  );
}
