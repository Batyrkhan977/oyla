import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'day_screens.dart';
import 'day_state.dart';

/// Accept only individual YouTube videos; discard tracking and playlist params.
String? normalizeYouTubeUrl(String input) {
  final text = input.trim();
  final uri = Uri.tryParse(text.contains('://') ? text : 'https://$text');
  if (uri == null ||
      !['https', 'http'].contains(uri.scheme) ||
      uri.userInfo.isNotEmpty ||
      uri.hasPort) {
    return null;
  }
  String? id;
  if (uri.host == 'youtu.be' && uri.pathSegments.length == 1) {
    id = uri.pathSegments.first;
  } else if ([
    'youtube.com',
    'www.youtube.com',
    'm.youtube.com',
    'music.youtube.com',
  ].contains(uri.host)) {
    if (uri.path == '/watch') id = uri.queryParameters['v'];
    if (uri.pathSegments.length == 2 &&
        ['shorts', 'embed', 'live'].contains(uri.pathSegments.first)) {
      id = uri.pathSegments[1];
    }
  }
  if (id == null || !RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(id)) return null;
  return 'https://www.youtube.com/watch?v=$id';
}

Future<void> openActivityVideo(
  BuildContext context,
  WidgetRef ref,
  String input, {
  String? songTitle,
  List<String> alternativeVideoIds = const [],
  bool external = false,
}) async {
  final url = normalizeYouTubeUrl(input);
  try {
    if (url != null &&
        !external &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android) {
      try {
        await const MethodChannel('oyla/youtube').invokeMethod<void>('play', {
          'videoId': Uri.parse(url).queryParameters['v'],
          'language': w(ref, 'en', 'kk', 'ru'),
          if (songTitle != null) 'songTitle': songTitle,
          if (alternativeVideoIds.isNotEmpty)
            'alternativeVideoIds': alternativeVideoIds,
        });
        return;
      } on PlatformException {
        // Retain external playback if the native player cannot be opened.
      } on MissingPluginException {
        // Older hosts may not yet include the native integration.
      }
    }
    if (url == null ||
        !await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        )) {
      throw StateError('Cannot open video');
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            w(
              ref,
              'Could not open YouTube. Check your connection and try again.',
              'YouTube ашылмады. Байланысты тексеріп, қайталаңыз.',
              'Не удалось открыть YouTube. Проверьте соединение и повторите.',
            ),
          ),
        ),
      );
    }
  }
}

class VideoSourcePicker extends ConsumerStatefulWidget {
  const VideoSourcePicker({super.key, this.initialUrl});
  final String? initialUrl;
  @override
  ConsumerState<VideoSourcePicker> createState() => _VideoSourcePickerState();
}

class _VideoSourcePickerState extends ConsumerState<VideoSourcePicker> {
  late final TextEditingController input;
  String? error;
  @override
  void initState() {
    super.initState();
    input = TextEditingController(text: widget.initialUrl);
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalized = normalizeYouTubeUrl(input.text);
    final saved =
        ref
            .watch(dayProvider)
            .valueOrNull
            ?.routines
            .where((r) => !r.deleted && r.videoUrl != null) ??
        [];
    final seen = <String>{};
    return Scaffold(
      appBar: AppBar(
        title: Text(
          words(ref, 'Choose a video', 'Видео таңдау', 'Выбрать видео'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.ondemand_video, size: 56),
          const SizedBox(height: 20),
          Text(
            words(
              ref,
              'YouTube link',
              'YouTube сілтемесі',
              'Ссылка на YouTube',
            ),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            words(
              ref,
              'Paste a link to the video you want to use for this activity.',
              'Осы әрекетке арналған видео сілтемесін қойыңыз.',
              'Вставьте ссылку на видео для этого занятия.',
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: input,
            keyboardType: TextInputType.url,
            autocorrect: false,
            onChanged: (_) => setState(() => error = null),
            decoration: InputDecoration(
              labelText: words(
                ref,
                'YouTube link',
                'YouTube сілтемесі',
                'Ссылка на YouTube',
              ),
              hintText: 'https://www.youtube.com/watch?v=…',
              border: const OutlineInputBorder(),
              errorText: error,
              errorMaxLines: 4,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            words(
              ref,
              'Videos play inside ÖmirAI on Android and in YouTube or your browser on other devices. Internet is required; the timer works offline.',
              'Android-та видео ÖmirAI ішінде, басқа құрылғыларда YouTube не браузерде ойнатылады. Интернет қажет; таймер офлайн жұмыс істейді.',
              'На Android видео воспроизводится в ÖmirAI, на других устройствах — в YouTube или браузере. Нужен интернет; таймер работает офлайн.',
            ),
          ),
          const SizedBox(height: 24),
          if (normalized != null)
            OutlinedButton.icon(
              onPressed: () => openActivityVideo(context, ref, normalized),
              icon: const Icon(Icons.open_in_new),
              label: Text(
                words(ref, 'Preview video', 'Видеоны көру', 'Посмотреть видео'),
              ),
            ),
          FilledButton.icon(
            onPressed: () {
              if (normalized == null) {
                setState(
                  () => error = w(
                    ref,
                    'Enter a valid link to a YouTube video.',
                    'YouTube видеосының дұрыс сілтемесін енгізіңіз.',
                    'Введите корректную ссылку на ролик YouTube.',
                  ),
                );
              } else {
                Navigator.pop(context, normalized);
              }
            },
            icon: const Icon(Icons.check),
            label: Text(
              words(
                ref,
                'Use this video',
                'Осы видеоны таңдау',
                'Использовать это видео',
              ),
            ),
          ),
          if (saved.isNotEmpty) ...[
            const SizedBox(height: 32),
            Text(
              words(ref, 'My videos', 'Менің видеоларым', 'Мои видео'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (final routine in saved)
              if (normalizeYouTubeUrl(routine.videoUrl!) case final String url)
                if (seen.add(url))
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.ondemand_video),
                      title: Text(routine.label(lang(ref))),
                      subtitle: const Text('YouTube'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pop(context, url),
                    ),
                  ),
          ],
        ],
      ),
    );
  }
}
