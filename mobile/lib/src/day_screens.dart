import 'music_screens.dart';
import 'brand.dart';
import 'media.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'activity_editor.dart';
import 'video_source.dart';
import 'youtube_screens.dart';
import 'app_state.dart';
import 'day_models.dart';
import 'day_state.dart';
import 'models.dart';
import 'localization.dart';
import 'reading_library.dart';

String words(WidgetRef ref, String en, String kk, String ru) => localized(
  ref.watch(appStateProvider).requireValue.settings.language,
  en,
  kk,
  ru,
);
String w(WidgetRef ref, String en, String kk, String ru) => localized(
  ref.read(appStateProvider).requireValue.settings.language,
  en,
  kk,
  ru,
);
AppLanguage lang(WidgetRef ref) =>
    ref.watch(appStateProvider).requireValue.settings.language;
Future<void> runDayAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ActivityScheduleException
                ? e.label(
                    ProviderScope.containerOf(
                      context,
                    ).read(appStateProvider).requireValue.settings.language,
                  )
                : context.strings.text('saveError'),
          ),
        ),
      );
    }
  }
}

class MyDayScreen extends ConsumerStatefulWidget {
  const MyDayScreen({super.key});
  @override
  ConsumerState<MyDayScreen> createState() => _MyDayScreenState();
}

class _MyDayScreenState extends ConsumerState<MyDayScreen>
    with WidgetsBindingObserver {
  Timer? timer;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    scheduleMicrotask(refresh);
    timer = Timer.periodic(const Duration(seconds: 1), (tick) {
      if (tick.tick % 60 == 0) refresh();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  Future<void> refresh() async {
    if (busy) return;
    busy = true;
    try {
      await ref.read(dayProvider.future);
      if (mounted) {
        final controller = ref.read(dayProvider.notifier);
        await controller.initializeDay();
        final launch = controller.takeNotificationStart();
        if (launch != null && mounted) {
          final o = ref
              .read(dayProvider)
              .requireValue
              .occurrences
              .where((v) => v.id == launch)
              .firstOrNull;
          if (o != null && !o.terminal) {
            await context.push('/movement/${Uri.encodeComponent(o.id)}');
          }
        }
      }
    } catch (_) {
      /* Async state retains startup errors. */
    } finally {
      busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(dayProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(words(ref, 'My Day', 'Менің күнім', 'Мой день')),
        actions: [
          IconButton(
            tooltip: words(ref, 'Settings', 'Баптаулар', 'Настройки'),
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(dayProvider),
            child: Text(words(ref, 'Try again', 'Қайталау', 'Повторить')),
          ),
        ),
        data: (data) {
          final today = data.today(DateTime.now());
          final controller = ref.read(dayProvider.notifier);
          final suggestion = data.recommendation;
          if (suggestion != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) controller.recommendationShown(suggestion);
            });
          }
          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const OmirWordmark(),
                const SizedBox(height: 16),
                Text(
                  DateTime.now().hour < 12
                      ? words(ref, 'Good morning', 'Қайырлы таң', 'Доброе утро')
                      : DateTime.now().hour < 18
                      ? words(
                          ref,
                          'Good afternoon',
                          'Қайырлы күн',
                          'Добрый день',
                        )
                      : words(
                          ref,
                          'Good evening',
                          'Қайырлы кеш',
                          'Добрый вечер',
                        ),
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  MaterialLocalizations.of(
                    context,
                  ).formatFullDate(DateTime.now()),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  words(ref, 'Today', 'Бүгін', 'Сегодня'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  '${today.where((o) => o.status == OccurrenceStatus.completed).length} / ${today.length} ${words(ref, 'actions completed', 'әрекет орындалды', 'действий выполнено')}',
                ),
                const SizedBox(height: 12),
                if (today.isNotEmpty)
                  LinearProgressIndicator(
                    value:
                        today
                            .where(
                              (o) => o.status == OccurrenceStatus.completed,
                            )
                            .length /
                        today.length,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                    semanticsLabel: words(
                      ref,
                      'Daily progress',
                      'Күндік ілгерілеу',
                      'Прогресс за день',
                    ),
                  ),
                const SizedBox(height: 24),
                if (!data.setup)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            words(
                              ref,
                              'Build a day that suits you',
                              'Өзіңізге ыңғайлы күн құрыңыз',
                              'Создайте удобный распорядок',
                            ),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            words(
                              ref,
                              'Choose activities, days, time, and reminders. You can change them later.',
                              'Әрекеттерді, күндерді, уақытты және еске салуды таңдаңыз. Кейін өзгертуге болады.',
                              'Выберите занятия, дни, время и напоминания. Позже их можно изменить.',
                            ),
                          ),
                          FilledButton(
                            onPressed: () => context.push('/routines'),
                            child: Text(
                              words(
                                ref,
                                'Set up my day',
                                'Күнімді жоспарлау',
                                'Настроить мой день',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                for (final conflict in data.conflicts)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            words(
                              ref,
                              'A cloud change needs your choice',
                              'Бұлттағы өзгерісті таңдаңыз',
                              'Выберите версию изменения',
                            ),
                          ),
                          Text(
                            '${conflict['table']} · ${(conflict['data'] as Map)['title'] ?? conflict['id']}',
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: () => runDayAction(
                                  context,
                                  () => controller.resolveConflict(
                                    conflict,
                                    true,
                                  ),
                                ),
                                child: Text(
                                  words(
                                    ref,
                                    'Keep this device',
                                    'Осы құрылғыны сақтау',
                                    'Оставить на устройстве',
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => runDayAction(
                                  context,
                                  () => controller.resolveConflict(
                                    conflict,
                                    false,
                                  ),
                                ),
                                child: Text(
                                  words(
                                    ref,
                                    'Use cloud version',
                                    'Бұлттағы нұсқа',
                                    'Версия из облака',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                if (today.isEmpty && data.setup)
                  Text(
                    words(
                      ref,
                      'A quiet day. Add an activity whenever you like.',
                      'Бүгін жоспар бос. Қалаған кезде әрекет қосыңыз.',
                      'Сегодня план пуст. Добавьте занятие, когда захотите.',
                    ),
                  ),
                for (final occurrence in today)
                  _OccurrenceCard(occurrence: occurrence, onChanged: refresh),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => editRoutine(context, ref),
                  icon: const Icon(Icons.add),
                  label: Text(
                    words(
                      ref,
                      'Add activity',
                      'Әрекет қосу',
                      'Добавить занятие',
                    ),
                  ),
                ),
                if (suggestion != null)
                  _RecommendationCard(recommendation: suggestion),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    words(
                      ref,
                      'Personal suggestions',
                      'Жеке ұсыныстар',
                      'Личные рекомендации',
                    ),
                  ),
                  subtitle: Text(
                    words(
                      ref,
                      'Based on how you use ÖmirAI. Changes always need your choice.',
                      'ÖmirAI қолдану тарихына негізделеді. Өзгерісті өзіңіз таңдайсыз.',
                      'На основе использования ÖmirAI. Изменения всегда выбираете вы.',
                    ),
                  ),
                  value: data.personalization,
                  onChanged: (v) => runDayAction(context, () async {
                    await controller.setSettings({'personalization': v});
                    await refresh();
                  }),
                ),
                if (data.owner != 'guest')
                  OutlinedButton(
                    onPressed: () => runDayAction(context, () async {
                      await controller.sync();
                      await refresh();
                    }),
                    child: Text(
                      words(
                        ref,
                        'Sync my day',
                        'Күнді синхрондау',
                        'Синхронизировать мой день',
                      ),
                    ),
                  ),
                Text(
                  words(
                    ref,
                    'ÖmirAI supports your daily routine. It does not assess your health.',
                    'ÖmirAI күн тәртібін қолдайды. Денсаулықты бағаламайды.',
                    'ÖmirAI помогает с распорядком дня и не оценивает здоровье.',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OccurrenceCard extends ConsumerWidget {
  const _OccurrenceCard({required this.occurrence, required this.onChanged});
  final DayOccurrence occurrence;
  final Future<void> Function() onChanged;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = occurrence, controller = ref.read(dayProvider.notifier);
    Future<void> preview() async {
      await context.push('/movement/${Uri.encodeComponent(o.id)}');
      await onChanged();
    }

    Future<void> start() async {
      await controller.act(
        o.id,
        OccurrenceStatus.started,
        source: o.status == OccurrenceStatus.skipped ? 'restart' : 'manual',
      );
      if (context.mounted) await preview();
    }

    Future<void> complete() async {
      if (isMovement(o.routine.kind)) {
        final minutes = await askMinutes(
          context,
          ref,
          initial: o.routine.duration,
        );
        if (minutes == null) return;
        await controller.act(
          o.id,
          OccurrenceStatus.completed,
          minutes: minutes,
          source: 'manual',
        );
      } else {
        await controller.act(o.id, OccurrenceStatus.completed);
      }
      await onChanged();
    }

    final status = switch (o.status) {
      OccurrenceStatus.scheduled => words(
        ref,
        'Scheduled',
        'Жоспарланған',
        'Запланировано',
      ),
      OccurrenceStatus.started => words(ref, 'Started', 'Басталды', 'Начато'),
      OccurrenceStatus.completed => words(
        ref,
        'Completed',
        'Орындалды',
        'Выполнено',
      ),
      OccurrenceStatus.postponed => words(
        ref,
        'Postponed',
        'Кейінге қалдырылды',
        'Перенесено',
      ),
      OccurrenceStatus.skipped => words(
        ref,
        'Skipped today',
        'Бүгін өткізілді',
        'Сегодня пропущено',
      ),
    };
    Future<void> secondaryAction(String action) async {
      if (action == 'delete') {
        await controller.deleteOccurrence(o.id);
        return;
      }
      if (action == 'complete') return complete();
      if (action == 'edit') {
        final routine = ref
            .read(dayProvider)
            .requireValue
            .routines
            .where((r) => r.id == o.routine.id && !r.deleted)
            .firstOrNull;
        if (routine != null) await editRoutine(context, ref, routine: routine);
        return;
      }
      if (action == 'skip') {
        await controller.act(o.id, OccurrenceStatus.skipped);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                w(
                  ref,
                  "That's okay. Your plan continues tomorrow.",
                  'Ештеңе етпейді. Жоспарыңыз ертең жалғасады.',
                  'Всё в порядке. Ваш план продолжится завтра.',
                ),
              ),
            ),
          );
        }
      } else if (action == 'postpone') {
        final now = DateTime.now();
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(
            now.add(const Duration(minutes: 30)),
          ),
        );
        if (time == null || !context.mounted) return;
        var date = atMinute(now, time.hour * 60 + time.minute);
        if (!date.isAfter(now)) {
          date = DateTime(
            now.year,
            now.month,
            now.day + 1,
            time.hour,
            time.minute,
          );
        }
        await controller.act(
          o.id,
          OccurrenceStatus.postponed,
          postponedTo: date,
        );
      }
      await onChanged();
    }

    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: preview,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      activityIcon(o.routine.kind),
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${dayKey(o.displayTime) != dayKey(DateTime.now()) ? '${MaterialLocalizations.of(context).formatShortDate(o.displayTime)} · ' : ''}${clockText(o.displayTime.hour * 60 + o.displayTime.minute)}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: words(
                      ref,
                      'Activity options',
                      'Әрекет параметрлері',
                      'Действия с занятием',
                    ),
                    onSelected: (action) =>
                        runDayAction(context, () => secondaryAction(action)),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          words(
                            ref,
                            'Delete activity',
                            'Әрекетті жою',
                            'Удалить занятие',
                          ),
                        ),
                      ),
                      if (!o.terminal)
                        PopupMenuItem(
                          value: 'complete',
                          child: Text(
                            words(
                              ref,
                              'Mark completed',
                              'Орындалды деп белгілеу',
                              'Отметить выполненным',
                            ),
                          ),
                        ),
                      if (!o.terminal && o.status != OccurrenceStatus.started)
                        PopupMenuItem(
                          value: 'postpone',
                          child: Text(
                            words(ref, 'Postpone', 'Кейінге', 'Перенести'),
                          ),
                        ),
                      if (!o.terminal)
                        PopupMenuItem(
                          value: 'skip',
                          child: Text(
                            words(ref, 'Skip', 'Өткізу', 'Пропустить'),
                          ),
                        ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(
                          words(
                            ref,
                            'Edit activity',
                            'Әрекетті өзгерту',
                            'Изменить занятие',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                o.routine.label(lang(ref)),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '${o.status == OccurrenceStatus.completed ? o.minutes : o.routine.duration} ${words(ref, 'minutes', 'минут', 'минут')}',
              ),
              if (o.routine.videoUrl != null ||
                  o.routine.youtubeChannels.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.ondemand_video, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          words(
                            ref,
                            o.sessionVideo != null
                                ? '${o.sessionVideo!.title} · ${o.sessionVideo!.durationLabel}'
                                : 'Video · YouTube',
                            o.sessionVideo != null
                                ? '${o.sessionVideo!.title} · ${o.sessionVideo!.durationLabel}'
                                : 'Видео · YouTube',
                            o.sessionVideo != null
                                ? '${o.sessionVideo!.title} · ${o.sessionVideo!.durationLabel}'
                                : 'Видео · YouTube',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (o.status != OccurrenceStatus.scheduled) ...[
                const SizedBox(height: 8),
                Text(status, style: TextStyle(color: colors.onSurfaceVariant)),
              ],
              if (o.status == OccurrenceStatus.skipped)
                TextButton.icon(
                  onPressed:
                      ref.read(dayClockProvider)().isBefore(o.displayTime)
                      ? null
                      : () => runDayAction(context, start),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    words(
                      ref,
                      'Do it anyway',
                      'Бәрібір орындау',
                      'Всё равно начать',
                    ),
                  ),
                ),
              if (!o.terminal) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed:
                      ref.read(dayClockProvider)().isBefore(o.displayTime)
                      ? null
                      : () => runDayAction(context, start),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    o.status == OccurrenceStatus.started
                        ? words(ref, 'Continue', 'Жалғастыру', 'Продолжить')
                        : words(ref, 'Start', 'Бастау', 'Начать'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendationCard extends ConsumerWidget {
  const _RecommendationCard({required this.recommendation});
  final DayRecommendation recommendation;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = recommendation;
    final routine = ref
        .watch(dayProvider)
        .valueOrNull
        ?.routines
        .where((routine) => routine.id == r.routineId)
        .firstOrNull;
    final reason = switch (r.type) {
      'postponed' => words(
        ref,
        'You postponed this activity to a similar time at least three times.',
        'Бұл әрекетті кемінде үш рет ұқсас уақытқа ауыстырдыңыз.',
        'Вы переносили это занятие на похожее время не менее трёх раз.',
      ),
      'time' => words(
        ref,
        'You usually start this activity around the same time.',
        'Бұл әрекетті көбіне бір уақытта бастайсыз.',
        'Вы обычно начинаете это занятие примерно в одно время.',
      ),
      'duration' => words(
        ref,
        'You usually record shorter sessions.',
        'Көбіне қысқа сабақтарды белгілейсіз.',
        'Вы обычно отмечаете более короткие занятия.',
      ),
      'reminder' => words(
        ref,
        'Several delivered reminders were not followed by an open or start.',
        'Бірнеше еске салудан кейін әрекет ашылмады не басталмады.',
        'После нескольких напоминаний занятие не открывали и не начинали.',
      ),
      _ => words(
        ref,
        'You choose this movement activity more often.',
        'Бұл қимыл түрін жиі таңдайсыз.',
        'Вы чаще выбираете этот вид движения.',
      ),
    };
    final proposal = switch (r.type) {
      'postponed' || 'time' =>
        '${words(ref, 'Change the usual time to', 'Әдеттегі уақытты ауыстыру', 'Изменить обычное время на')} ${clockText(r.value as int)}?',
      'duration' =>
        '${words(ref, 'Change the goal to', 'Мақсатты өзгерту', 'Изменить цель на')} ${r.value} ${words(ref, 'minutes', 'минут', 'минут')}?',
      'reminder' => words(
        ref,
        'Turn off this routine’s reminder?',
        'Осы жоспардың еске салуын өшіру керек пе?',
        'Отключить напоминание для этой рутины?',
      ),
      _ =>
        '${words(ref, 'Change the activity to', 'Әрекетті өзгерту', 'Изменить занятие на')} ${kindLabel(ActivityKind.values.byName(r.value as String), lang(ref))}?',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              words(
                ref,
                'A small suggestion',
                'Шағын ұсыныс',
                'Небольшое предложение',
              ),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              routine?.label(lang(ref)) ??
                  words(ref, 'Activity', 'Әрекет', 'Занятие'),
            ),
            Text(reason),
            const SizedBox(height: 8),
            Text(proposal),
            Text(
              words(
                ref,
                'Applies to future planned days.',
                'Келесі жоспарлы күндерге қолданылады.',
                'Для следующих запланированных дней.',
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  onPressed: () => runDayAction(
                    context,
                    () => ref.read(dayProvider.notifier).decide(r, true),
                  ),
                  child: Text(words(ref, 'Accept', 'Қабылдау', 'Принять')),
                ),
                OutlinedButton(
                  onPressed: () => runDayAction(
                    context,
                    () => ref.read(dayProvider.notifier).decide(r, false),
                  ),
                  child: Text(
                    words(ref, 'Keep unchanged', 'Өзгертпеу', 'Не менять'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RoutinesScreen extends ConsumerWidget {
  const RoutinesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: Text(words(ref, 'Activities', 'Әрекеттер', 'Занятия')),
    ),
    body: ref
        .watch(dayProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(
            child: Text(
              words(
                ref,
                'Could not load activities.',
                'Әрекеттер жүктелмеді.',
                'Не удалось загрузить занятия.',
              ),
            ),
          ),
          data: (data) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const OmirWordmark(),
              for (final entry in [
                (
                  OmirDirection.music,
                  words(ref, 'Music', 'Музыка', 'Музыка'),
                  '/music',
                ),
                (OmirDirection.togyz, 'Тоғызқұмалақ Academy', '/togyz'),
                (
                  OmirDirection.connect,
                  context.strings.text('connectTitle'),
                  '/connect',
                ),
              ])
                Card(
                  child: ListTile(
                    leading: OmirIcon(entry.$1),
                    title: Text(entry.$2),
                    onTap: () => context.push(entry.$3),
                  ),
                ),

              Text(
                words(
                  ref,
                  'Choose what you want in your day',
                  'Күніңізге не қосқыңыз келеді?',
                  'Выберите занятия для своего дня',
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              for (final group in ActivityGroup.values) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 28, bottom: 12),
                  child: Wrap(
                    spacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OmirIcon(switch (group) {
                        ActivityGroup.mind => OmirDirection.mind,
                        ActivityGroup.read => OmirDirection.read,
                        ActivityGroup.move => OmirDirection.move,
                        ActivityGroup.music => OmirDirection.music,
                        ActivityGroup.togyz => OmirDirection.togyz,
                      }),
                      Text(
                        groupLabel(group, ref),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                for (final r in data.routines.where(
                  (r) =>
                      !r.deleted &&
                      activityGroup(r.kind) == group &&
                      r.kind != ActivityKind.custom,
                ))
                  Card(
                    child: ListTile(
                      leading: Icon(activityIcon(r.kind)),
                      title: Text(r.label(lang(ref))),
                      subtitle: Text(
                        '${clockText(r.minute)} · ${r.duration} ${words(ref, 'min', 'мин', 'мин')}${r.videoUrl == null && r.youtubeChannels.isEmpty ? '' : ' · YouTube'}',
                      ),
                      onTap: () => editRoutine(context, ref, routine: r),
                      trailing: PopupMenuButton<String>(
                        tooltip: words(
                          ref,
                          'Activity options',
                          'Әрекет параметрлері',
                          'Действия с занятием',
                        ),
                        onSelected: (action) {
                          if (action == 'edit') {
                            editRoutine(context, ref, routine: r);
                          } else {
                            runDayAction(
                              context,
                              () => ref
                                  .read(dayProvider.notifier)
                                  .saveRoutine(r.copyWith(deleted: true)),
                            );
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(
                              words(
                                ref,
                                'Edit activity',
                                'Әрекетті өзгерту',
                                'Изменить занятие',
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'remove',
                            child: Text(
                              words(
                                ref,
                                'Remove from future days',
                                'Келесі күндерден алып тастау',
                                'Убрать из будущих дней',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                for (final kind in ActivityKind.values.where(
                  (kind) =>
                      activityGroup(kind) == group &&
                      kind != ActivityKind.custom,
                ))
                  Card(
                    child: ListTile(
                      minTileHeight: 72,
                      onTap: () => editRoutine(context, ref, kind: kind),
                      leading: Icon(activityIcon(kind)),
                      title: Text(kindLabel(kind, lang(ref))),
                      trailing: const Icon(Icons.add),
                    ),
                  ),
              ],
              Padding(
                padding: const EdgeInsets.only(top: 28, bottom: 12),
                child: Text(
                  words(
                    ref,
                    'Your activities',
                    'Сіздің әрекеттеріңіз',
                    'Ваши занятия',
                  ),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              for (final r in data.routines.where(
                (r) => !r.deleted && r.kind == ActivityKind.custom,
              ))
                Card(
                  child: ListTile(
                    leading: Icon(activityIcon(r.kind)),
                    title: Text(r.label(lang(ref))),
                    subtitle: Text(
                      '${clockText(r.minute)} · ${r.duration} ${words(ref, 'min', 'мин', 'мин')}',
                    ),
                    onTap: () => editRoutine(context, ref, routine: r),
                    trailing: IconButton(
                      tooltip: words(
                        ref,
                        'Remove from future days',
                        'Келесі күндерден алып тастау',
                        'Убрать из будущих дней',
                      ),
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => runDayAction(
                        context,
                        () => ref
                            .read(dayProvider.notifier)
                            .saveRoutine(r.copyWith(deleted: true)),
                      ),
                    ),
                  ),
                ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.add),
                  title: Text(
                    words(
                      ref,
                      'Create my own activity',
                      'Өз әрекетімді жасау',
                      'Создать своё занятие',
                    ),
                  ),
                  onTap: () => editRoutine(context, ref),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.grid_view_outlined),
                  title: Text(
                    words(
                      ref,
                      'Free practice',
                      'Еркін жаттығу',
                      'Свободная практика',
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/practice'),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => runDayAction(context, () async {
                  await ref.read(dayProvider.notifier).setSettings({
                    'setup': true,
                  });
                  await ref.read(dayProvider.notifier).initializeDay();
                  if (context.mounted) context.go('/');
                }),
                child: Text(
                  words(
                    ref,
                    'Save my day',
                    'Күнімді сақтау',
                    'Сохранить мой день',
                  ),
                ),
              ),
            ],
          ),
        ),
  );
}

Future<int?> askMinutes(
  BuildContext context,
  WidgetRef ref, {
  int initial = 10,
}) async {
  final input = TextEditingController(text: '$initial');
  String? error;
  final result = await showDialog<int>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(
          w(ref, 'How many minutes?', 'Неше минут?', 'Сколько минут?'),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 4,
                children: [
                  for (final n in [3, 5, 7, 10, 20, 30, 45])
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, n),
                      child: Text('$n'),
                    ),
                ],
              ),
              TextField(
                controller: input,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: w(
                    ref,
                    'Other duration',
                    'Басқа ұзақтық',
                    'Другая длительность',
                  ),
                  errorText: error,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(w(ref, 'Cancel', 'Болдырмау', 'Отмена')),
          ),
          FilledButton(
            onPressed: () {
              final n = int.tryParse(input.text);
              if (n == null || n < 1 || n > 1440) {
                setState(
                  () => error = w(
                    ref,
                    'Enter 1–1440 minutes',
                    '1–1440 минут енгізіңіз',
                    'Введите 1–1440 минут',
                  ),
                );
                return;
              }
              Navigator.pop(ctx, n);
            },
            child: Text(w(ref, 'Save', 'Сақтау', 'Сохранить')),
          ),
        ],
      ),
    ),
  );
  Future<void>.delayed(const Duration(seconds: 1), input.dispose);
  return result;
}

class MovementScreen extends ConsumerStatefulWidget {
  const MovementScreen({super.key, required this.occurrenceId});
  final String occurrenceId;
  @override
  ConsumerState<MovementScreen> createState() => _MovementScreenState();
}

class _MovementScreenState extends ConsumerState<MovementScreen> {
  Timer? timer;
  bool submitting = false;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(dayProvider).valueOrNull;
    final o = data?.occurrences
        .where((v) => v.id == widget.occurrenceId)
        .firstOrNull;
    if (o == null || o.deleted) {
      return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
    }
    final seconds = o.elapsedSeconds(ref.read(dayClockProvider)());
    Future<void> finish(int? minutes) async {
      if (submitting) return;
      setState(() => submitting = true);
      try {
        await ref
            .read(dayProvider.notifier)
            .act(
              o.id,
              minutes == null
                  ? OccurrenceStatus.skipped
                  : OccurrenceStatus.completed,
              minutes: minutes,
              source: 'timer_confirmed',
            );
        if (context.mounted) context.pop();
      } finally {
        if (mounted) setState(() => submitting = false);
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(o.routine.label(lang(ref)))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            kindLabel(o.routine.kind, lang(ref)),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          if (o.routine.kind == ActivityKind.cognitive)
            for (final exercise in dailyExercises(DateTime.parse(o.date)))
              ListTile(
                title: Text(context.strings.exerciseLabel(exercise)),
                subtitle: Text(context.strings.exerciseInstruction(exercise)),
              ),
          if (o.routine.kind == ActivityKind.music ||
              o.routine.kind == ActivityKind.togyz)
            FilledButton(
              onPressed: () => context.push(
                o.routine.kind == ActivityKind.music ? '/music' : '/togyz',
              ),
              child: Text(
                words(ref, 'Open activity', 'Әрекетті ашу', 'Открыть занятие'),
              ),
            ),
          if (o.routine.kind == ActivityKind.reading)
            Text(
              words(
                ref,
                'Choose a book from the library after starting.',
                'Бастағаннан кейін кітапханадан кітап таңдаңыз.',
                'После начала выберите книгу в библиотеке.',
              ),
            ),
          if (isMovement(o.routine.kind))
            Text(
              words(
                ref,
                'Choose movements you already know and feel comfortable doing. You can stop at any time.',
                'Өзіңіз білетін, ыңғайлы қимылдарды таңдаңыз. Кез келген уақытта тоқтай аласыз.',
                'Выберите знакомые и удобные движения. Можно остановиться в любой момент.',
              ),
            ),
          if (o.routine.youtubeChannels.isNotEmpty)
            YouTubeSession(key: ValueKey(o.id), occurrence: o),
          if (o.routine.videoUrl != null) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () =>
                  openActivityVideo(context, ref, o.routine.videoUrl!),
              icon: const Icon(Icons.play_circle_outline),
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
                'After watching, return here to record your completed activity. You can also exercise with the timer alone.',
                'Видеодан кейін әрекетті аяқтау үшін осында оралыңыз. Тек таймермен де жаттығуға болады.',
                'После просмотра вернитесь сюда, чтобы отметить выполнение. Можно заниматься только с таймером.',
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.displayMedium,
            semanticsLabel:
                '${seconds ~/ 60} ${words(ref, 'minutes elapsed', 'минут өтті', 'минут прошло')}',
          ),
          Text(
            '${words(ref, 'Planned', 'Жоспар', 'План')}: ${o.routine.duration} ${words(ref, 'min', 'мин', 'мин')}',
          ),
          const SizedBox(height: 24),
          if (o.terminal)
            Text(
              words(
                ref,
                'Activity finished',
                'Әрекет аяқталды',
                'Занятие завершено',
              ),
            ),
          if (!o.terminal && o.status != OccurrenceStatus.started)
            FilledButton(
              onPressed:
                  submitting ||
                      ref.read(dayClockProvider)().isBefore(o.displayTime)
                  ? null
                  : () => runDayAction(context, () async {
                      await ref
                          .read(dayProvider.notifier)
                          .act(
                            o.id,
                            OccurrenceStatus.started,
                            source: o.status == OccurrenceStatus.skipped
                                ? 'restart'
                                : 'manual',
                          );
                    }),
              child: Text(words(ref, 'Start', 'Бастау', 'Начать')),
            ),
          if (o.status == OccurrenceStatus.started) ...[
            if (o.routine.kind == ActivityKind.cognitive)
              FilledButton(
                onPressed: () => context.push(
                  '/workout?occurrence=${Uri.encodeComponent(o.id)}',
                ),
                child: Text(
                  words(
                    ref,
                    'Open workout',
                    'Жаттығуды ашу',
                    'Открыть тренировку',
                  ),
                ),
              ),
            if (o.routine.kind == ActivityKind.reading)
              FilledButton(
                onPressed: () => context.push(
                  '/reading?occurrence=${Uri.encodeComponent(o.id)}',
                ),
                child: Text(
                  words(
                    ref,
                    'Choose reading',
                    'Мәтінді таңдау',
                    'Выбрать чтение',
                  ),
                ),
              ),
            FilledButton(
              onPressed: submitting
                  ? null
                  : () => runDayAction(context, () => finish(seconds ~/ 60)),
              child: Text(
                words(
                  ref,
                  'Stop and complete',
                  'Тоқтату және аяқтау',
                  'Остановить и завершить',
                ),
              ),
            ),
          ],
          if (!o.terminal)
            TextButton(
              onPressed: submitting
                  ? null
                  : () => runDayAction(context, () => finish(null)),
              child: Text(words(ref, 'Not today', 'Бүгін емес', 'Не сегодня')),
            ),
          TextButton.icon(
            onPressed: () => runDayAction(context, () async {
              await ref.read(dayProvider.notifier).deleteOccurrence(o.id);
              if (context.mounted) context.pop();
            }),
            icon: const Icon(Icons.delete_outline),
            label: Text(
              words(ref, 'Delete activity', 'Әрекетті жою', 'Удалить занятие'),
            ),
          ),
        ],
      ),
    );
  }
}

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key, this.occurrenceId});
  final String? occurrenceId;
  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String? genre;
  @override
  void initState() {
    super.initState();
    final preferences = ref
        .read(dayProvider)
        .valueOrNull
        ?.settings['readingPreferences'];
    if (preferences is Map) {
      genre = preferences['genre'] as String?;
    }
  }

  void selectGenre(String? value) {
    setState(() => genre = value);
    unawaited(
      ref.read(dayProvider.notifier).setSettings({
        'readingPreferences': {'genre': value},
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = lang(ref);
    return Scaffold(
      appBar: AppBar(
        title: Text(words(ref, 'Library', 'Кітапхана', 'Библиотека')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            words(
              ref,
              'Original short reading, available offline',
              'Интернетсіз оқылатын төл қысқа мәтіндер',
              'Оригинальные короткие тексты доступны без интернета',
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(words(ref, 'All', 'Барлығы', 'Все')),
                selected: genre == null,
                onSelected: (_) => selectGenre(null),
              ),
              for (final g in readingLibrary.map((b) => b.genre).toSet())
                ChoiceChip(
                  label: Text(genreLabel(g, language)),
                  selected: genre == g,
                  onSelected: (_) => selectGenre(g),
                ),
            ],
          ),
          for (final book in readingLibrary.where(
            (b) => genre == null || b.genre == genre,
          ))
            Card(
              child: ListTile(
                minTileHeight: 72,
                title: Text(book.title(language)),
                subtitle: Text('${genreLabel(book.genre, language)} · ÖmirAI'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(
                  '/reading/${book.id}${widget.occurrenceId == null ? '' : '?occurrence=${Uri.encodeComponent(widget.occurrenceId!)}'}',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.bookId, this.occurrenceId});
  final String bookId;
  final String? occurrenceId;
  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with WidgetsBindingObserver {
  final tts = FlutterTts();
  final watch = Stopwatch();
  final sessionId = const Uuid().v4();
  Timer? timer;
  int position = 0;
  int paragraph = 0;
  bool listening = false, ready = false, closing = false, usedTts = false;
  bool usedAloud = false;
  String? ttsError;
  late ReadingMaterial book;
  late AppLanguage language;
  late List<String> paragraphs;
  late String full;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    book = readingLibrary.firstWhere((b) => b.id == widget.bookId);
    language = ref.read(appStateProvider).requireValue.settings.language;
    paragraphs = book.text(language);
    full = paragraphs.join('\n\n');
    final saved = ref
        .read(dayProvider)
        .valueOrNull
        ?.positions
        .where((r) => r['id'] == book.bookId(language))
        .firstOrNull;
    position = ((saved?['position'] as int?) ?? 0).clamp(0, full.length);
    paragraph = paragraphFor(position);
    watch.start();
    ready = true;
    tts.setProgressHandler((text, start, end, word) {
      if (mounted && listening) {
        setState(() {
          position = (speechStart + start).clamp(0, full.length);
          paragraph = paragraphFor(position);
        });
      }
    });
    tts.setCompletionHandler(() {
      if (mounted && listening) {
        setState(() {
          listening = false;
          position = full.length;
          paragraph = paragraphs.length - 1;
        });
        save();
      }
    });
    tts.setErrorHandler((message) {
      if (mounted) {
        setState(() {
          listening = false;
          ttsError = w(
            ref,
            'Speech is unavailable. You can continue reading.',
            'Дыбыстау қолжетімсіз. Оқуды жалғастырыңыз.',
            'Озвучивание недоступно. Можно продолжить чтение.',
          );
        });
      }
    });
    timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (watch.isRunning) unawaited(save());
    });
  }

  Future<void> readAloud() async {
    final consent = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(words(ref, 'Read aloud', 'Дауыстап оқу', 'Чтение вслух')),
        content: Text(
          words(
            ref,
            'Your device speech service will recognize this passage. ÖmirAI stores only your place, not audio. The device provider may use the network. Continue?',
            'Құрылғының сөйлеу қызметі мәтінді таниды. ÖmirAI тек оқу орнын сақтайды, аудионы сақтамайды. Қызмет интернетті қолдануы мүмкін. Жалғастыру керек пе?',
            'Служба устройства распознает речь. ÖmirAI сохраняет только место чтения, без аудио. Служба может использовать интернет. Продолжить?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(words(ref, 'Cancel', 'Бас тарту', 'Отмена')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(words(ref, 'Continue', 'Жалғастыру', 'Продолжить')),
          ),
        ],
      ),
    );
    if (consent != true || !mounted) return;
    await tts.stop();
    setState(() {
      listening = false;
      usedAloud = true;
    });
    try {
      final speech = await OmirMedia.recognize(switch (language) {
        AppLanguage.english => 'en-US',
        AppLanguage.kazakh => 'kk-KZ',
        AppLanguage.russian => 'ru-RU',
      });
      if (!mounted || speech == null) return;
      setState(() {
        position = spokenPosition(full, speech, position);
        paragraph = paragraphFor(position);
      });
      await save();
    } catch (_) {
      if (mounted) {
        setState(
          () => ttsError = words(
            ref,
            'Speech recognition is unavailable. Continue reading manually.',
            'Сөйлеуді тану қолжетімсіз. Оқуды жалғастырыңыз.',
            'Распознавание речи недоступно. Продолжайте читать вручную.',
          ),
        );
      }
    }
  }

  int speechStart = 0;
  int startOf(int p) =>
      paragraphs.take(p).fold(0, (sum, v) => sum + v.length + 2);
  int paragraphFor(int offset) {
    for (var p = paragraphs.length - 1; p >= 0; p--) {
      if (offset >= startOf(p)) return p;
    }
    return 0;
  }

  Future<void> save({bool finished = false}) async {
    if (!ready) return;
    await ref
        .read(dayProvider.notifier)
        .recordReading(
          sessionId: sessionId,
          bookId: book.bookId(language),
          position: position,
          total: full.length,
          seconds: watch.elapsed.inSeconds,
          mode: usedAloud
              ? 'aloud'
              : usedTts
              ? 'tts'
              : 'reading',
          finished: finished,
        );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      watch.start();
    } else {
      watch.stop();
      tts.stop();
      listening = false;
      save();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    watch.stop();
    tts.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> leave() async {
    if (closing) return;
    setState(() => closing = true);
    await tts.stop();
    watch.stop();
    await save(finished: true);
    if (mounted) {
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) context.pop();
    }
  }

  Future<void> listen() async {
    if (listening) {
      await tts.stop();
      setState(() => listening = false);
      await save();
      return;
    }
    try {
      await tts.setLanguage(switch (language) {
        AppLanguage.english => 'en-US',
        AppLanguage.kazakh => 'kk-KZ',
        AppLanguage.russian => 'ru-RU',
      });
      await tts.setSpeechRate(.42);
      speechStart = position == full.length ? 0 : position;
      setState(() {
        listening = true;
        usedTts = true;
        ttsError = null;
      });
      await tts.speak(full.substring(speechStart));
    } catch (_) {
      if (mounted) {
        setState(
          () => ttsError = w(
            ref,
            'Speech is unavailable on this device.',
            'Бұл құрылғыда дыбыстау қолжетімсіз.',
            'Озвучивание недоступно на этом устройстве.',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.occurrenceId != null) {
      final o = ref
          .watch(dayProvider)
          .valueOrNull
          ?.occurrences
          .where((o) => o.id == widget.occurrenceId)
          .firstOrNull;
      if (o == null || o.deleted || o.status != OccurrenceStatus.started) {
        watch.stop();
        if (listening) {
          unawaited(tts.stop());
          listening = false;
        }
        return Scaffold(
          appBar: AppBar(title: Text(book.title(language))),
          body: Center(
            child: Text(
              words(
                ref,
                'Activity finished',
                'Әрекет аяқталды',
                'Занятие завершено',
              ),
            ),
          ),
        );
      }
    }
    return PopScope(
      canPop: closing,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) leave();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: words(ref, 'Back', 'Артқа', 'Назад'),
            onPressed: leave,
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(book.title(language)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              '${paragraph + 1} / ${paragraphs.length}',
              semanticsLabel: '${paragraph + 1} / ${paragraphs.length}',
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: paragraphs[paragraph].substring(
                      0,
                      (position - startOf(paragraph)).clamp(
                        0,
                        paragraphs[paragraph].length,
                      ),
                    ),
                    style: usedAloud
                        ? TextStyle(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.secondaryContainer,
                            fontWeight: FontWeight.w700,
                          )
                        : null,
                  ),
                  TextSpan(
                    text: paragraphs[paragraph].substring(
                      (position - startOf(paragraph)).clamp(
                        0,
                        paragraphs[paragraph].length,
                      ),
                    ),
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 22, height: 1.6),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: paragraph == 0
                      ? null
                      : () async {
                          await tts.stop();
                          setState(() {
                            listening = false;
                            paragraph--;
                            position = startOf(paragraph);
                          });
                          await save();
                        },
                  child: Text(words(ref, 'Previous', 'Алдыңғы', 'Назад')),
                ),
                FilledButton(
                  onPressed: paragraph == paragraphs.length - 1
                      ? null
                      : () async {
                          await tts.stop();
                          setState(() {
                            listening = false;
                            paragraph++;
                            position = startOf(paragraph);
                          });
                          await save();
                        },
                  child: Text(words(ref, 'Next', 'Келесі', 'Далее')),
                ),
                OutlinedButton.icon(
                  onPressed: listen,
                  icon: Icon(
                    listening ? Icons.pause : Icons.volume_up_outlined,
                  ),
                  label: Text(
                    listening
                        ? words(
                            ref,
                            'Pause listening',
                            'Тыңдауды тоқтату',
                            'Пауза',
                          )
                        : words(ref, 'Listen', 'Тыңдау', 'Слушать'),
                  ),
                ),
              ],
            ),
            OutlinedButton.icon(
              onPressed: readAloud,
              icon: const Icon(Icons.mic_none),
              label: Text(
                words(ref, 'Read aloud', 'Дауыстап оқу', 'Чтение вслух'),
              ),
            ),
            if (usedAloud)
              LinearProgressIndicator(
                value: position / full.length,
                semanticsLabel: words(
                  ref,
                  'Reading position',
                  'Оқу орны',
                  'Место чтения',
                ),
              ),
            if (ttsError != null) Text(ttsError!),
            if (paragraph == paragraphs.length - 1) ...[
              FilledButton(
                onPressed: () => runDayAction(context, () async {
                  position = full.length;
                  watch.stop();
                  await tts.stop();
                  await save(finished: true);
                  if (widget.occurrenceId != null) {
                    await ref
                        .read(dayProvider.notifier)
                        .act(
                          widget.occurrenceId!,
                          OccurrenceStatus.completed,
                          source: 'reading',
                        );
                  }
                  if (context.mounted) {
                    await showDialog<void>(
                      context: context,
                      builder: (ctx) =>
                          ReadingQuestions(book: book, language: language),
                    );
                  }
                }),
                child: Text(
                  words(
                    ref,
                    'Finish reading',
                    'Оқуды аяқтау',
                    'Завершить чтение',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            ExpansionTile(
              title: Text(
                words(
                  ref,
                  'About this material',
                  'Мәтін туралы',
                  'Об этом материале',
                ),
              ),
              children: [
                for (final entry in book.metadata(language).entries)
                  ListTile(
                    title: Text(context.strings.text('metadata.${entry.key}')),
                    subtitle: Text(entry.value),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ReadingQuestions extends StatefulWidget {
  const ReadingQuestions({
    super.key,
    required this.book,
    required this.language,
  });
  final ReadingMaterial book;
  final AppLanguage language;
  @override
  State<ReadingQuestions> createState() => _ReadingQuestionsState();
}

class _ReadingQuestionsState extends State<ReadingQuestions> {
  bool started = false;
  final revealed = <int>{};
  String t(String en, String kk, String ru) =>
      localized(widget.language, en, kk, ru);
  @override
  Widget build(BuildContext context) {
    final i = widget.book.index(widget.language);
    return AlertDialog(
      title: Text(
        t(
          'A little memory practice?',
          'Есте сақтауды жаттықтырамыз ба?',
          'Хотите немного размять память?',
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (started)
              for (var q = 0; q < 2; q++) ...[
                Text(widget.book.questions[i][q]),
                TextField(
                  decoration: InputDecoration(
                    labelText: t(
                      'Your answer (optional)',
                      'Жауабыңыз (міндетті емес)',
                      'Ваш ответ (необязательно)',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => revealed.add(q)),
                  child: Text(
                    t('Show answer', 'Жауапты көрсету', 'Показать ответ'),
                  ),
                ),
                if (revealed.contains(q)) Text(widget.book.answers[i][q]),
                const SizedBox(height: 16),
              ]
            else
              Text(
                t(
                  'Two optional questions. Your answers stay on this screen.',
                  'Екі ерікті сұрақ. Жауаптар осы экранда ғана қалады.',
                  'Два необязательных вопроса. Ответы остаются на этом экране.',
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            started
                ? t('Done', 'Дайын', 'Готово')
                : t('Skip', 'Өткізу', 'Пропустить'),
          ),
        ),
        if (!started)
          FilledButton(
            onPressed: () => setState(() => started = true),
            child: Text(
              t(
                'Answer 2 questions',
                '2 сұраққа жауап беру',
                'Ответить на 2 вопроса',
              ),
            ),
          ),
      ],
    );
  }
}

class DayProgressScreen extends ConsumerWidget {
  const DayProgressScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dayProvider).valueOrNull;
    if (data == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final now = DateTime.now();
    final since = dayKey(DateTime(now.year, now.month, now.day - 6));
    final completed = data.occurrences
        .where(
          (o) =>
              o.status == OccurrenceStatus.completed &&
              o.activityDate.compareTo(since) >= 0 &&
              o.activityDate.compareTo(dayKey(now)) <= 0,
        )
        .toList();
    final reading = data.readingSessions
        .where(
          (r) =>
              (r['date'] as String).compareTo(since) >= 0 &&
              (r['date'] as String).compareTo(dayKey(now)) <= 0,
        )
        .toList();
    final results = ref
        .watch(appStateProvider)
        .requireValue
        .results
        .where(
          (r) =>
              dayKey(r.date).compareTo(since) >= 0 &&
              dayKey(r.date).compareTo(dayKey(now)) <= 0,
        )
        .toList();
    final days = <String>{
      ...data.events
          .where(
            (e) =>
                e.type == 'COMPLETED' &&
                dayKey(e.at).compareTo(since) >= 0 &&
                dayKey(e.at).compareTo(dayKey(now)) <= 0,
          )
          .map((e) => dayKey(e.at)),
      ...completed.map((o) => o.activityDate),
      ...reading
          .where((r) => (r['seconds'] as int) > 0)
          .map((r) => r['date'] as String),
      ...results.map((r) => dayKey(r.date)),
    };
    final workoutDays = results
        .where((r) => !r.practice)
        .map((r) => dayKey(r.date))
        .toSet()
        .where(
          (d) =>
              results
                  .where(
                    (r) =>
                        !r.practice &&
                        dayKey(r.date) == d &&
                        activeExercises.contains(r.type),
                  )
                  .map((r) => r.type)
                  .toSet()
                  .length >=
              3,
        )
        .length;
    final stats = [
      (
        words(ref, 'Active days', 'Белсенді күндер', 'Активные дни'),
        days.length,
      ),
      (
        words(
          ref,
          'Completed actions',
          'Орындалған әрекеттер',
          'Выполненные действия',
        ),
        completed.length,
      ),
      (
        words(ref, 'Reading minutes', 'Оқу минуттары', 'Минуты чтения'),
        reading.fold<int>(0, (sum, r) => sum + (r['seconds'] as int)) ~/ 60,
      ),
      (
        words(ref, 'Movement minutes', 'Қимыл минуттары', 'Минуты движения'),
        completed
            .where((o) => isMovement(o.routine.kind))
            .fold<int>(0, (sum, o) => sum + o.minutes),
      ),
      (
        words(
          ref,
          'Cognitive workouts',
          'Ақыл-ой жаттығулары',
          'Умственные тренировки',
        ),
        workoutDays,
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(words(ref, 'Progress', 'Ілгерілеу', 'Прогресс')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ref
              .watch(moduleRowsProvider('music_sessions'))
              .when(
                data: (rows) => ListTile(
                  title: Text(
                    words(
                      ref,
                      'Music sessions',
                      'Музыка сабақтары',
                      'Музыкальные занятия',
                    ),
                  ),
                  trailing: Text('${rows.length}'),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
              ),
          ListTile(
            title: const Text('Piano Journey'),
            onTap: () => context.push('/piano'),
          ),
          ListTile(
            title: const Text('Тоғызқұмалақ Academy'),
            onTap: () => context.push('/togyz'),
          ),

          Text(
            words(
              ref,
              'Your last seven days',
              'Соңғы жеті күніңіз',
              'Последние семь дней',
            ),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          for (final stat in stats)
            Card(
              child: ListTile(
                title: Text(stat.$1),
                subtitle: Text(
                  '${stat.$2}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
          Text(
            words(
              ref,
              'Every activity is a part of your routine. Skipped days need no explanation.',
              'Әр әрекет күн тәртібіңіздің бөлігі. Өткізген күндерді түсіндіру қажет емес.',
              'Каждое занятие — часть распорядка. Пропуски не требуют объяснений.',
            ),
          ),
        ],
      ),
    );
  }
}

class ActivityReminderMonitor extends ConsumerStatefulWidget {
  const ActivityReminderMonitor({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<ActivityReminderMonitor> createState() =>
      _ActivityReminderMonitorState();
}

class _ActivityReminderMonitorState
    extends ConsumerState<ActivityReminderMonitor>
    with WidgetsBindingObserver {
  Timer? timer;
  bool prompting = false;
  bool refreshing = false;
  final dueShown = <String>{};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(seconds: 1), (tick) {
      checkActivityReminders();
      if (tick.tick % 60 == 0) refreshActivities();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshActivities();
      checkActivityReminders();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> refreshActivities() async {
    if (refreshing || !mounted) return;
    refreshing = true;
    try {
      await ref.read(dayProvider.future);
      if (!mounted) return;
      final controller = ref.read(dayProvider.notifier);
      await controller.initializeDay();
      if (!mounted) return;
      final id = controller.takeNotificationStart();
      if (id != null) context.push('/movement/${Uri.encodeComponent(id)}');
    } catch (_) {
      // Retry refresh on the next tick or resume.
    } finally {
      refreshing = false;
    }
  }

  Future<void> checkActivityReminders() async {
    if (!mounted ||
        prompting ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused) {
      return;
    }
    final data = ref.read(dayProvider).valueOrNull;
    if (data == null) return;
    final now = ref.read(dayClockProvider)();
    final active = data.occurrences
        .where(
          (o) =>
              !o.deleted &&
              o.status == OccurrenceStatus.started &&
              !o.timerAcknowledged &&
              o.elapsedSeconds(now) >= o.routine.duration * 60,
        )
        .firstOrNull;
    if (active != null) {
      prompting = true;
      try {
        final stop = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text(
              w(
                ref,
                'Planned time completed',
                'Жоспарланған уақыт аяқталды',
                'Запланированное время истекло',
              ),
            ),
            content: Text(
              active.routine.label(
                ref.read(appStateProvider).requireValue.settings.language,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  w(
                    ref,
                    'Continue exercise',
                    'Жалғастыру',
                    'Продолжить занятие',
                  ),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  w(
                    ref,
                    'Stop and complete',
                    'Тоқтату және аяқтау',
                    'Остановить и завершить',
                  ),
                ),
              ),
            ],
          ),
        );
        if (!mounted || stop == null) return;
        await runDayAction(context, () async {
          if (stop) {
            await ref
                .read(dayProvider.notifier)
                .act(active.id, OccurrenceStatus.completed);
          } else {
            await ref.read(dayProvider.notifier).acknowledgeTimer(active.id);
          }
        });
      } finally {
        prompting = false;
      }
      return;
    }
    final settings = ref.read(appStateProvider).requireValue.settings;
    final hour = now.hour,
        start = settings.quietStartHour,
        end = settings.quietEndHour;
    final quiet =
        start != end &&
        (start > end
            ? hour >= start || hour < end
            : hour >= start && hour < end);
    if (!settings.remindersEnabled || quiet) return;
    for (final o
        in data
            .today(now)
            .where(
              (o) =>
                  !o.terminal &&
                  o.status != OccurrenceStatus.started &&
                  o.routine.reminder,
            )) {
      final key = '${o.id}:${o.displayTime.toIso8601String()}';
      if (!o.displayTime.isAfter(now) &&
          now.difference(o.displayTime).inMinutes < 1 &&
          dueShown.add(key)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 15),
            content: Text(o.routine.label(settings.language)),
            action: SnackBarAction(
              label: w(
                ref,
                'View activity',
                'Әрекетті көру',
                'Открыть занятие',
              ),
              onPressed: () =>
                  context.push('/movement/${Uri.encodeComponent(o.id)}'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
