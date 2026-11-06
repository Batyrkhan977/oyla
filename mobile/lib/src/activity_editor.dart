import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'app_state.dart';
import 'day_models.dart';
import 'day_screens.dart';
import 'day_state.dart';
import 'video_source.dart';
import 'reminders.dart';
import 'youtube.dart';
import 'youtube_screens.dart';

IconData activityIcon(ActivityKind kind) => switch (kind) {
  ActivityKind.cognitive => Icons.psychology_outlined,
  ActivityKind.reading => Icons.menu_book_outlined,
  ActivityKind.walking => Icons.directions_walk,
  ActivityKind.yoga || ActivityKind.taiChi => Icons.self_improvement,
  ActivityKind.exercise || ActivityKind.pilates => Icons.fitness_center,
  ActivityKind.music => Icons.music_note,
  ActivityKind.togyz => Icons.grid_view,
  ActivityKind.stretching || ActivityKind.dance => Icons.accessibility_new,
  ActivityKind.custom ||
  ActivityKind.personal ||
  ActivityKind.other => Icons.wb_sunny_outlined,
};

enum ActivityGroup { mind, read, move, music, togyz }

ActivityGroup activityGroup(ActivityKind kind) => switch (kind) {
  ActivityKind.cognitive ||
  ActivityKind.custom ||
  ActivityKind.personal ||
  ActivityKind.other => ActivityGroup.mind,
  ActivityKind.reading => ActivityGroup.read,
  ActivityKind.music => ActivityGroup.music,
  ActivityKind.togyz => ActivityGroup.togyz,
  _ => ActivityGroup.move,
};
String groupLabel(ActivityGroup group, WidgetRef ref) => switch (group) {
  ActivityGroup.mind => words(ref, 'Mind', 'Ой', 'Ум'),
  ActivityGroup.read => words(ref, 'Read', 'Оқу', 'Чтение'),
  ActivityGroup.music => words(ref, 'Music', 'Музыка', 'Музыка'),
  ActivityGroup.togyz => words(ref, 'Togyz', 'Тоғызқұмалақ', 'Тогызкумалак'),
  ActivityGroup.move => words(ref, 'Move', 'Қозғалыс', 'Движение'),
};

Future<void> editRoutine(
  BuildContext context,
  WidgetRef ref, {
  Routine? routine,
  ActivityKind kind = ActivityKind.custom,
}) => Navigator.of(context, rootNavigator: true).push<void>(
  MaterialPageRoute(
    builder: (_) => ActivityEditorScreen(routine: routine, kind: kind),
  ),
);

class ActivityEditorScreen extends ConsumerStatefulWidget {
  const ActivityEditorScreen({
    super.key,
    this.routine,
    this.kind = ActivityKind.custom,
  });
  final Routine? routine;
  final ActivityKind kind;
  @override
  ConsumerState<ActivityEditorScreen> createState() =>
      _ActivityEditorScreenState();
}

class _ActivityEditorScreenState extends ConsumerState<ActivityEditorScreen>
    with WidgetsBindingObserver {
  final form = GlobalKey<FormState>();
  late final TextEditingController title;
  late final TextEditingController duration;
  late ActivityKind kind;
  late TimeOfDay time;
  late Set<int> days;
  late bool reminder;
  late bool withVideo;
  String? videoUrl;
  List<YouTubeChannel> youtubeChannels = [];
  bool saving = false;
  bool? notificationsEnabled, exactAlarmsEnabled;
  String? error;
  late final String id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    checkNotifications();
    final r = widget.routine;
    id = r?.id ?? const Uuid().v4();
    kind = r?.kind ?? widget.kind;
    title = TextEditingController(
      text:
          r?.label(ref.read(appStateProvider).requireValue.settings.language) ??
          kindLabel(
            kind,
            ref.read(appStateProvider).requireValue.settings.language,
          ),
    );
    duration = TextEditingController(
      text: '${r?.duration ?? (kind == ActivityKind.walking ? 20 : 10)}',
    );
    time = TimeOfDay(
      hour: (r?.minute ?? 540) ~/ 60,
      minute: (r?.minute ?? 540) % 60,
    );
    days = r?.weekdays.toSet() ?? {1, 2, 3, 4, 5, 6, 7};
    reminder = r?.reminder ?? false;
    videoUrl = r?.videoUrl;
    youtubeChannels = r?.youtubeChannels.toList() ?? [];
    withVideo = videoUrl != null || youtubeChannels.isNotEmpty;
  }

  Future<void> checkNotifications() async {
    final enabled = await ReminderService().notificationsEnabled();
    final exact = await ReminderService().exactAlarmsEnabled();
    if (mounted) {
      setState(() {
        notificationsEnabled = enabled;
        exactAlarmsEnabled = exact;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) checkNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    title.dispose();
    duration.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    if (days.isEmpty ||
        (withVideo && videoUrl == null && youtubeChannels.isEmpty)) {
      setState(
        () => error = days.isEmpty
            ? w(
                ref,
                'Choose at least one day.',
                'Кемінде бір күн таңдаңыз.',
                'Выберите хотя бы один день.',
              )
            : w(
                ref,
                'Choose a video source.',
                'Видео көзін таңдаңыз.',
                'Выберите источник видео.',
              ),
      );
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final controller = ref.read(dayProvider.notifier);
      await controller.saveRoutine(
        Routine(
          id: id,
          title:
              [
                ActivityKind.custom,
                ActivityKind.personal,
                ActivityKind.other,
              ].contains(kind)
              ? title.text.trim()
              : kind.name,
          kind: kind,
          weekdays: days.toList()..sort(),
          minute: time.hour * 60 + time.minute,
          duration: int.parse(duration.text.trim()),
          reminder: reminder,
          videoUrl: withVideo ? videoUrl : null,
          youtubeChannels: withVideo ? youtubeChannels : [],
        ),
      );
      await controller.setSettings({'setup': true});
      await controller.initializeDay();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is ActivityScheduleException
              ? e.label(
                  ref.read(appStateProvider).requireValue.settings.language,
                )
              : w(
                  ref,
                  'Could not save. Please try again.',
                  'Сақталмады. Қайталаңыз.',
                  'Не удалось сохранить. Повторите.',
                ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = lang(ref);
    Widget heading(String en, String kk, String ru) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        words(ref, en, kk, ru),
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
    return PopScope(
      canPop: !saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.routine == null
                ? words(ref, 'Add activity', 'Әрекет қосу', 'Добавить занятие')
                : words(
                    ref,
                    'Edit activity',
                    'Әрекетті өзгерту',
                    'Изменить занятие',
                  ),
          ),
        ),
        body: AbsorbPointer(
          absorbing: saving,
          child: Form(
            key: form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                if (widget.routine != null)
                  Text(
                    words(
                      ref,
                      'Changes apply to activities that have not started yet.',
                      'Өзгерістер әлі басталмаған әрекеттерге қолданылады.',
                      'Изменения применяются к ещё не начатым занятиям.',
                    ),
                  ),
                heading('Activity', 'Әрекет', 'Занятие'),
                DropdownButtonFormField<ActivityKind>(
                  initialValue: kind,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: words(ref, 'Type', 'Түрі', 'Тип'),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    for (final k in ActivityKind.values)
                      DropdownMenuItem(
                        value: k,
                        child: Text(kindLabel(k, language)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      if (title.text == kindLabel(kind, language)) {
                        title.text = kindLabel(value, language);
                      }
                      if (kind != value) {
                        youtubeChannels = [];
                        videoUrl = null;
                      }
                      kind = value;
                      if (kind == ActivityKind.cognitive ||
                          kind == ActivityKind.reading) {
                        withVideo = false;
                      }
                    });
                  },
                ),
                const SizedBox(height: 20),
                if ([
                  ActivityKind.custom,
                  ActivityKind.personal,
                  ActivityKind.other,
                ].contains(kind))
                  TextFormField(
                    controller: title,
                    maxLength: 80,
                    decoration: InputDecoration(
                      labelText: words(ref, 'Title', 'Атауы', 'Название'),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? words(
                            ref,
                            'Enter a title',
                            'Атау енгізіңіз',
                            'Введите название',
                          )
                        : null,
                  ),
                heading('Duration', 'Ұзақтығы', 'Длительность'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final minutes in [5, 10, 15, 20, 30])
                      ChoiceChip(
                        label: Text(
                          '$minutes ${words(ref, 'min', 'мин', 'мин')}',
                        ),
                        selected: duration.text == '$minutes',
                        onSelected: (_) =>
                            setState(() => duration.text = '$minutes'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: duration,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: words(
                      ref,
                      'Duration in minutes',
                      'Ұзақтығы, минут',
                      'Длительность в минутах',
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    return n == null || n < 1 || n > 240
                        ? words(
                            ref,
                            'Enter 1–240 minutes',
                            '1–240 минут енгізіңіз',
                            'Введите 1–240 минут',
                          )
                        : null;
                  },
                ),
                heading('Schedule', 'Кесте', 'Расписание'),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.schedule),
                    title: Text(words(ref, 'Time', 'Уақыт', 'Время')),
                    subtitle: Text(clockText(time.hour * 60 + time.minute)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final selected = await showTimePicker(
                        context: context,
                        initialTime: time,
                      );
                      if (selected != null && mounted) {
                        setState(() => time = selected);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  words(
                    ref,
                    'Repeat on',
                    'Қайталанатын күндер',
                    'Дни повторения',
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(
                        words(ref, 'Every day', 'Күн сайын', 'Каждый день'),
                      ),
                      selected: days.length == 7,
                      onSelected: (_) =>
                          setState(() => days = {1, 2, 3, 4, 5, 6, 7}),
                    ),
                    ChoiceChip(
                      label: Text(
                        words(ref, 'Weekdays', 'Жұмыс күндері', 'По будням'),
                      ),
                      selected:
                          days.length == 5 && days.containsAll({1, 2, 3, 4, 5}),
                      onSelected: (_) => setState(() => days = {1, 2, 3, 4, 5}),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var d = 1; d <= 7; d++)
                      FilterChip(
                        showCheckmark: false,
                        label: Text(
                          localized(
                            language,
                            [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun',
                            ][d - 1],
                            ['Дс', 'Сс', 'Ср', 'Бс', 'Жм', 'Сб', 'Жс'][d - 1],
                            ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'][d - 1],
                          ),
                        ),
                        selected: days.contains(d),
                        onSelected: (v) =>
                            setState(() => v ? days.add(d) : days.remove(d)),
                      ),
                  ],
                ),
                heading('Reminder', 'Еске салу', 'Напоминание'),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    words(ref, 'Reminder', 'Еске салу', 'Напоминание'),
                  ),
                  subtitle: Text(
                    words(
                      ref,
                      'At activity time',
                      'Әрекет уақытында',
                      'В начале занятия',
                    ),
                  ),
                  value: reminder,
                  onChanged: (v) async {
                    setState(() => reminder = v);
                    if (v &&
                        !ref
                            .read(appStateProvider)
                            .requireValue
                            .settings
                            .remindersEnabled) {
                      await runDayAction(context, () async {
                        final settings = ref
                            .read(appStateProvider)
                            .requireValue
                            .settings;
                        await ref
                            .read(appStateProvider.notifier)
                            .updateSettings(
                              settings.copyWith(remindersEnabled: true),
                            );
                      });
                      await checkNotifications();
                    }
                  },
                ),
                if (reminder && exactAlarmsEnabled == false)
                  ListTile(
                    title: Text(
                      words(
                        ref,
                        'Allow reminders at the scheduled time',
                        'Жоспарланған уақытта еске салуға рұқсат беру',
                        'Разрешить напоминания в назначенное время',
                      ),
                    ),
                    trailing: const Icon(Icons.schedule),
                    onTap: () => runDayAction(
                      context,
                      () => ReminderService().openExactAlarmSettings(),
                    ),
                  ),
                if (reminder && notificationsEnabled == false)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            words(
                              ref,
                              'Notifications are currently turned off',
                              'Хабарландырулар өшірулі',
                              'Уведомления сейчас отключены',
                            ),
                          ),
                          TextButton(
                            onPressed: () => runDayAction(
                              context,
                              () =>
                                  ReminderService().openNotificationSettings(),
                            ),
                            child: Text(
                              words(
                                ref,
                                'Open settings',
                                'Баптауларды ашу',
                                'Открыть настройки',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (isMovement(kind) ||
                    [
                      ActivityKind.custom,
                      ActivityKind.personal,
                      ActivityKind.other,
                    ].contains(kind)) ...[
                  heading(
                    'Activity format',
                    'Әрекет форматы',
                    'Формат занятия',
                  ),
                  for (final video in [false, true])
                    Card(
                      color: withVideo == video
                          ? Theme.of(context).colorScheme.secondaryContainer
                          : null,
                      child: ListTile(
                        leading: Icon(
                          video ? Icons.ondemand_video : Icons.timer_outlined,
                        ),
                        title: Text(
                          video
                              ? words(ref, 'With video', 'Видеомен', 'С видео')
                              : words(
                                  ref,
                                  'Timer only',
                                  'Тек таймер',
                                  'Только таймер',
                                ),
                        ),
                        trailing: Icon(
                          withVideo == video
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                        ),
                        selected: withVideo == video,
                        onTap: () => setState(() => withVideo = video),
                      ),
                    ),
                  if (withVideo) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      icon: const Icon(Icons.subscriptions_outlined),
                      label: Text(
                        words(
                          ref,
                          'Choose YouTube channels',
                          'YouTube арналарын таңдау',
                          'Выбрать каналы YouTube',
                        ),
                      ),
                      onPressed: () async {
                        final selected = await Navigator.of(context)
                            .push<List<YouTubeChannel>>(
                              MaterialPageRoute(
                                builder: (_) => YouTubeChannelPicker(
                                  kind: kind,
                                  initial: youtubeChannels,
                                ),
                              ),
                            );
                        if (selected != null && mounted) {
                          setState(() {
                            youtubeChannels = selected;
                            videoUrl = null;
                            error = null;
                          });
                        }
                      },
                    ),
                    if (youtubeChannels.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(youtubeChannels.map((c) => c.title).join(' · ')),
                      Text(
                        words(
                          ref,
                          'A random video at least as long as your session',
                          'Ұзақтығы сабақтан кем емес кездейсоқ видео',
                          'Случайное видео не короче вашего занятия',
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.video_library_outlined),
                      label: Text(
                        videoUrl == null
                            ? words(
                                ref,
                                'Choose video source',
                                'Видео көзін таңдау',
                                'Выбрать источник видео',
                              )
                            : words(
                                ref,
                                'Change video source',
                                'Видео көзін өзгерту',
                                'Изменить источник видео',
                              ),
                      ),
                      onPressed: () async {
                        final selected = await Navigator.of(context)
                            .push<String>(
                              MaterialPageRoute(
                                builder: (_) =>
                                    VideoSourcePicker(initialUrl: videoUrl),
                              ),
                            );
                        if (selected != null && mounted) {
                          setState(() {
                            videoUrl = selected;
                            youtubeChannels = [];
                            error = null;
                          });
                        }
                      },
                    ),
                    if (videoUrl != null)
                      Text(
                        videoUrl!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                  ],
                ],
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      error!,
                      semanticsLabel: error,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: saving ? null : save,
                  icon: Icon(saving ? Icons.hourglass_top : Icons.check),
                  label: Text(
                    saving
                        ? words(ref, 'Saving…', 'Сақталуда…', 'Сохранение…')
                        : words(
                            ref,
                            'Save activity',
                            'Әрекетті сақтау',
                            'Сохранить занятие',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
