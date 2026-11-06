import 'day_state.dart';
import 'package:flutter/material.dart';
import 'localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'app_state.dart';
import 'day_screens.dart';
import 'brand.dart';

final connectProvider = FutureProvider<Map<String, dynamic>>((ref) {
  ref.watch(dayProvider.select((s) => s.valueOrNull?.owner));
  return ref.watch(apiProvider).connect();
});

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});
  @override
  ConsumerState<ConnectScreen> createState() => _ConnectState();
}

class _ConnectState extends ConsumerState<ConnectScreen> {
  final code = TextEditingController(), email = TextEditingController();
  int days = 3;
  bool consent = false, weekly = false, busy = false;
  String? error;
  @override
  void dispose() {
    code.dispose();
    email.dispose();
    super.dispose();
  }

  Future<void> send(
    String path,
    Map<String, dynamic>? data, {
    String method = 'POST',
  }) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(apiProvider).connect(path, data, method);
      ref.invalidate(connectProvider);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = words(
            ref,
            'Could not save. Check your connection, permissions and invitation details.',
            'Сақталмады. Байланысты, рұқсаттар мен шақыру деректерін тексеріңіз.',
            'Не удалось сохранить. Проверьте соединение, разрешения и данные приглашения.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.strings.text('connectTitle'))),
    body: ref
        .watch(connectProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                words(
                  ref,
                  'Sign in and connect to the internet to manage friends and family emails.',
                  'Достар мен жақындарға хаттарды басқару үшін кіріп, интернетке қосылыңыз.',
                  'Войдите и подключитесь к интернету для управления друзьями и письмами близким.',
                ),
              ),
              FilledButton(
                onPressed: () => context.push('/account'),
                child: Text(words(ref, 'Account', 'Тіркелгі', 'Аккаунт')),
              ),
              OutlinedButton(
                onPressed: () => ref.invalidate(connectProvider),
                child: Text(words(ref, 'Retry', 'Қайталау', 'Повторить')),
              ),
            ],
          ),
          data: (data) {
            final settings = Map<String, dynamic>.from(data['settings']);
            Future<void> setting(String key, bool value) =>
                send('/settings', {...settings, key: value}, method: 'PUT');
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const OmirIcon(OmirDirection.connect),
                SwitchListTile(
                  title: Text(
                    words(
                      ref,
                      'Enable friends',
                      'Достарды қосу',
                      'Включить друзей',
                    ),
                  ),
                  value: settings['enabled'] == true,
                  onChanged: busy ? null : (v) => setting('enabled', v),
                ),
                SwitchListTile(
                  title: Text(
                    words(
                      ref,
                      'Share active days and general activity status',
                      'Белсенді күндер мен жалпы күйді бөлісу',
                      'Делиться активными днями и общим статусом',
                    ),
                  ),
                  value: settings['shareActivity'] == true,
                  onChanged: busy ? null : (v) => setting('shareActivity', v),
                ),
                Text(
                  words(
                    ref,
                    'Friends never see scores, answers or personal routine contents.',
                    'Достар баллдар, жауаптар мен жеке әрекеттерді көрмейді.',
                    'Друзья не видят баллы, ответы и содержание личных рутин.',
                  ),
                ),
                SwitchListTile(
                  title: Text(
                    words(
                      ref,
                      'Show streaks',
                      'Серияларды көрсету',
                      'Показывать серии',
                    ),
                  ),
                  value: settings['showStreak'] == true,
                  onChanged: busy ? null : (v) => setting('showStreak', v),
                ),
                if (settings['showStreak'] == true) ...[
                  Text(
                    '${words(ref, 'Streak', 'Серия', 'Серия')}: ${settings['streak']} · ${words(ref, 'Freezes', 'Сақтаулар', 'Разморозки')}: ${settings['freezes']}',
                  ),
                  Text(
                    words(
                      ref,
                      'Earn a freeze every seven active days. Up to three can be saved.',
                      'Әр жеті белсенді күн үшін бір сақтау. Үшеуге дейін жинауға болады.',
                      'Разморозка за каждые семь активных дней. Можно сохранить до трёх.',
                    ),
                  ),
                  OutlinedButton(
                    onPressed: busy || settings['freezes'] == 0
                        ? null
                        : () => send('/freeze', {}),
                    child: Text(
                      words(
                        ref,
                        'Use a freeze for yesterday',
                        'Кешегі күнді сақтау',
                        'Сохранить серию за вчера',
                      ),
                    ),
                  ),
                ],
                if (settings['enabled'] == true) ...[
                  SelectableText(
                    '${words(ref, 'Your invitation code', 'Шақыру кодыңыз', 'Ваш код приглашения')}: ${data['friendCode']}',
                  ),
                  TextField(
                    controller: code,
                    maxLength: 10,
                    decoration: InputDecoration(
                      labelText: words(
                        ref,
                        'Friend invitation code',
                        'Дос шақыру коды',
                        'Код друга',
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () => send('/friends', {'code': code.text.trim()}),
                    child: Text(
                      words(
                        ref,
                        'Request friendship',
                        'Достық сұрау',
                        'Запросить дружбу',
                      ),
                    ),
                  ),
                  for (final f in data['friends'] as List)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${f['name'] == 'ÖmirAI member' ? context.strings.text('member') : f['name']} · ${statusLabel(context, f['status'])}',
                            ),
                            if (f['activity']['sharing'] == true)
                              Text(
                                '${words(ref, 'Active days', 'Белсенді күндер', 'Активные дни')}: ${f['activity']['activeDays']}',
                              ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (f['status'] == 'PENDING' &&
                                    f['incoming'] == true)
                                  OutlinedButton(
                                    onPressed: busy
                                        ? null
                                        : () => send('/friends/${f['id']}', {
                                            'action': 'accept',
                                          }),
                                    child: Text(
                                      words(
                                        ref,
                                        'Accept',
                                        'Қабылдау',
                                        'Принять',
                                      ),
                                    ),
                                  ),
                                if (f['status'] == 'ACCEPTED') ...[
                                  OutlinedButton(
                                    onPressed: busy
                                        ? null
                                        : () => send('/friends/${f['id']}', {
                                            'action': 'invite',
                                          }),
                                    child: Text(
                                      words(
                                        ref,
                                        'Practice together',
                                        'Бірге айналысу',
                                        'Позаниматься вместе',
                                      ),
                                    ),
                                  ),
                                  OutlinedButton(
                                    onPressed: busy
                                        ? null
                                        : () => send('/friends/${f['id']}', {
                                            'action': 'gift',
                                          }),
                                    child: Text(
                                      words(
                                        ref,
                                        'Gift a freeze',
                                        'Сақтауды сыйлау',
                                        'Подарить разморозку',
                                      ),
                                    ),
                                  ),
                                  for (final type in [
                                    'reading',
                                    'active',
                                    'walking',
                                    'movement',
                                  ])
                                    OutlinedButton(
                                      onPressed: busy
                                          ? null
                                          : () => send('/challenges', {
                                              'friendshipId': f['id'],
                                              'type': type,
                                            }),
                                      child: Text(switch (type) {
                                        'reading' => words(
                                          ref,
                                          'Read 5 days',
                                          '5 күн оқу',
                                          'Читать 5 дней',
                                        ),
                                        'walking' => words(
                                          ref,
                                          'Walk 4 days',
                                          '4 күн серуен',
                                          'Гулять 4 дня',
                                        ),
                                        'movement' => words(
                                          ref,
                                          'Move 60 minutes',
                                          '60 минут қозғалыс',
                                          '60 минут движения',
                                        ),
                                        _ => words(
                                          ref,
                                          'Active week',
                                          'Белсенді апта',
                                          'Активная неделя',
                                        ),
                                      }),
                                    ),
                                ],
                                TextButton(
                                  onPressed: busy
                                      ? null
                                      : () => send('/friends/${f['id']}', {
                                          'action': 'remove',
                                        }),
                                  child: Text(
                                    words(
                                      ref,
                                      'Remove / decline',
                                      'Жою / бас тарту',
                                      'Удалить / отклонить',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  for (final c in data['challenges'] as List)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              '${context.strings.text('challenge.${c['type']}')} · ${c['progress']} / ${c['goal']} · ${MaterialLocalizations.of(context).formatShortDate(DateTime.parse(c['endDate']))} · ${statusLabel(context, c['status'])}',
                            ),
                            if (c['incoming'] == true &&
                                c['status'] == 'PENDING')
                              Wrap(
                                children: [
                                  for (final action in ['accept', 'decline'])
                                    TextButton(
                                      onPressed: busy
                                          ? null
                                          : () => send(
                                              '/challenges/${c['id']}',
                                              {'action': action},
                                            ),
                                      child: Text(
                                        action == 'accept'
                                            ? words(
                                                ref,
                                                'Join',
                                                'Қосылу',
                                                'Участвовать',
                                              )
                                            : words(
                                                ref,
                                                'Decline',
                                                'Бас тарту',
                                                'Отклонить',
                                              ),
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
                const Divider(height: 32),
                if (data['familyDeliveryConfigured'] != true)
                  Text(
                    words(
                      ref,
                      'Email delivery is not configured on this server yet. Saved consent will apply when delivery is enabled.',
                      'Бұл серверде хат жіберу әлі бапталмаған. Жіберу қосылғанда сақталған келісім қолданылады.',
                      'Отправка писем на сервере ещё не настроена. Сохранённое согласие начнёт действовать после включения отправки.',
                    ),
                  ),
                Text(
                  words(
                    ref,
                    'Family email updates',
                    'Жақындарға хаттар',
                    'Письма близким',
                  ),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  words(
                    ref,
                    'Only app inactivity and optional weekly active-day counts are shared. Offline activity may arrive later. No health conclusions or private routine details.',
                    'Тек қолданбадағы белсенділіктің жоқтығы және апталық белсенді күндер жіберіледі. Офлайн деректер кейін келуі мүмкін. Денсаулық қорытындылары мен жеке әрекеттер жіберілмейді.',
                    'Передаётся только отсутствие активности и, по желанию, число активных дней за неделю. Офлайн данные могут поступить позже. Без выводов о здоровье и личных рутин.',
                  ),
                ),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: words(
                      ref,
                      'Recipient email',
                      'Алушының email',
                      'Email получателя',
                    ),
                  ),
                ),
                DropdownButton<int>(
                  isExpanded: true,
                  value: days,
                  items: [
                    for (var d = 2; d <= 30; d++)
                      DropdownMenuItem(
                        value: d,
                        child: Text(
                          '$d ${words(ref, 'days without activity', 'күн белсенділік жоқ', 'дней без активности')}',
                        ),
                      ),
                  ],
                  onChanged: busy ? null : (v) => setState(() => days = v!),
                ),
                CheckboxListTile(
                  title: Text(
                    words(
                      ref,
                      'Optional weekly summary',
                      'Апталық қорытынды',
                      'Еженедельная сводка',
                    ),
                  ),
                  value: weekly,
                  onChanged: (v) => setState(() => weekly = v!),
                ),
                CheckboxListTile(
                  title: Text(
                    words(
                      ref,
                      'I explicitly consent to these emails to this recipient',
                      'Осы алушыға осы хаттарды жіберуге келісемін',
                      'Я явно разрешаю эти письма этому получателю',
                    ),
                  ),
                  value: consent,
                  onChanged: (v) => setState(() => consent = v!),
                ),
                FilledButton(
                  onPressed: busy || !consent
                      ? null
                      : () => send('/family', {
                          'recipient': email.text.trim(),
                          'inactivityDays': days,
                          'weekly': weekly,
                          'consent': consent,
                        }),
                  child: Text(
                    words(
                      ref,
                      'Save consent',
                      'Келісімді сақтау',
                      'Сохранить согласие',
                    ),
                  ),
                ),
                for (final s in data['family'] as List)
                  ListTile(
                    title: Text(s['recipient']),
                    subtitle: Text(
                      s['unsubscribed'] == true
                          ? words(
                              ref,
                              'Recipient opted out',
                              'Алушы бас тартты',
                              'Получатель отписался',
                            )
                          : s['enabled'] == true
                          ? words(ref, 'Enabled', 'Қосулы', 'Включено')
                          : words(ref, 'Disabled', 'Өшірулі', 'Отключено'),
                    ),
                    trailing: s['enabled'] == true
                        ? IconButton(
                            tooltip: words(
                              ref,
                              'Revoke consent',
                              'Келісімді қайтару',
                              'Отозвать согласие',
                            ),
                            icon: const Icon(Icons.close),
                            onPressed: busy
                                ? null
                                : () => send(
                                    '/family/${s['id']}',
                                    null,
                                    method: 'DELETE',
                                  ),
                          )
                        : null,
                  ),
                if (error != null)
                  Semantics(liveRegion: true, child: Text(error!)),
              ],
            );
          },
        ),
  );
}

String statusLabel(
  BuildContext context,
  Object? status,
) => context.strings.text(
  'status.${const {'PENDING', 'ACCEPTED', 'DECLINED', 'REMOVED'}.contains(status) ? status : 'unknown'}',
);
