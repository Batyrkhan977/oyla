import 'brand.dart';
import 'music_screens.dart';
import 'sing_screen.dart';
import 'togyz_screen.dart';
import 'connect_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_state.dart';
import 'day_models.dart';
import 'day_screens.dart';
import 'reading_library.dart';
import 'models.dart';
import 'screens.dart';

final routerProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    routes: [
      ShellRoute(
        builder: (context, state, child) => ActivityReminderMonitor(
          child: _MainNavigation(path: state.uri.path, child: child),
        ),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const _LandingScreen()),
          GoRoute(
            path: '/progress',
            builder: (_, __) => const ProgressScreen(),
          ),
          GoRoute(
            path: '/practice',
            builder: (_, __) => const PracticeScreen(),
          ),
          GoRoute(
            path: '/routines',
            builder: (_, __) => const RoutinesScreen(),
          ),
          GoRoute(
            path: '/reading',
            builder: (_, state) => LibraryScreen(
              occurrenceId: state.uri.queryParameters['occurrence'],
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/practice/:type',
        builder: (context, state) {
          final type = activeExercises
              .where((t) => t.name == state.pathParameters['type'])
              .firstOrNull;
          if (type == null) return const PracticeScreen();
          return ExerciseScreen(
            type: type,
            practice: true,
            position: 1,
            total: 1,
            onDone: context.pop,
          );
        },
      ),
      GoRoute(
        path: '/workout',
        builder: (_, state) => WorkoutScreen(
          practice: state.uri.queryParameters['practice'] == 'true',
          occurrenceId: state.uri.queryParameters['occurrence'],
        ),
      ),
      GoRoute(path: '/music', builder: (_, __) => const MusicScreen()),
      GoRoute(path: '/piano', builder: (_, __) => const PianoScreen()),
      GoRoute(path: '/sing', builder: (_, __) => const SingScreen()),
      GoRoute(path: '/togyz', builder: (_, __) => const TogyzScreen()),
      GoRoute(path: '/connect', builder: (_, __) => const ConnectScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(
        path: '/accessibility-setup',
        builder: (_, __) => const AccessibilitySetupScreen(),
      ),
      GoRoute(path: '/account', builder: (_, __) => const AccountScreen()),
      GoRoute(
        path: '/reading/:id',
        builder: (_, state) =>
            readingLibrary.any((b) => b.id == state.pathParameters['id'])
            ? ReaderScreen(
                bookId: state.pathParameters['id']!,
                occurrenceId: state.uri.queryParameters['occurrence'],
              )
            : const LibraryScreen(),
      ),
      GoRoute(
        path: '/movement/:id',
        builder: (_, state) =>
            MovementScreen(occurrenceId: state.pathParameters['id']!),
      ),
    ],
  ),
);

class _LandingScreen extends ConsumerWidget {
  const _LandingScreen();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appStateProvider).requireValue.settings;
    return settings.onboardingComplete
        ? const HomeScreen()
        : const OnboardingScreen();
  }
}

class _MainNavigation extends ConsumerWidget {
  const _MainNavigation({required this.path, required this.child});
  final String path;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appStateProvider).requireValue.settings;
    if (!settings.onboardingComplete) return child;
    const paths = ['/', '/routines', '/reading', '/progress'];
    final l = settings.language;
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: paths
            .indexOf(path == '/practice' ? '/routines' : path)
            .clamp(0, paths.length - 1),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) => context.go(paths[index]),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.today_outlined),
            selectedIcon: const Icon(Icons.today),
            label: localized(l, 'Today', 'Бүгін', 'Сегодня'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.event_repeat_outlined),
            label: localized(l, 'Activities', 'Әрекеттер', 'Занятия'),
          ),
          NavigationDestination(
            icon: const OmirIcon(OmirDirection.read, size: 28),
            label: localized(l, 'Library', 'Кітапхана', 'Библиотека'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            label: localized(l, 'Progress', 'Ілгерілеу', 'Прогресс'),
          ),
        ],
      ),
    );
  }
}
