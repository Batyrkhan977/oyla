import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_state.dart';
import 'models.dart';
import 'router.dart';
import 'localization.dart';

MediaQueryData accessibilityMediaQuery(
  MediaQueryData platform,
  UserSettings settings,
) => platform.copyWith(
  disableAnimations: platform.disableAnimations || settings.reducedMotion,
);

class OylaApp extends ConsumerWidget {
  const OylaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    return state.when(
      loading: () => const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (error, _) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              OylaLocalizations(switch (WidgetsBinding
                  .instance
                  .platformDispatcher
                  .locale
                  .languageCode) {
                'kk' => AppLanguage.kazakh,
                'ru' => AppLanguage.russian,
                _ => AppLanguage.english,
              }).text('startError'),
            ),
          ),
        ),
      ),
      data: (data) {
        final scheme = ColorScheme.fromSeed(
          seedColor: const Color(0xff0E7C7B),
          brightness: data.settings.highContrast
              ? Brightness.dark
              : Brightness.light,
          contrastLevel: data.settings.highContrast ? 1 : 0.3,
        );
        final baseTheme = ThemeData(colorScheme: scheme, useMaterial3: true);
        return MaterialApp.router(
          title: 'ÖmirAI',
          locale: Locale(switch (data.settings.language) {
            AppLanguage.english => 'en',
            AppLanguage.kazakh => 'kk',
            AppLanguage.russian => 'ru',
          }),
          debugShowCheckedModeBanner: false,
          supportedLocales: const [Locale('en'), Locale('kk'), Locale('ru')],
          localizationsDelegates: const [
            OylaLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            final mediaQuery = accessibilityMediaQuery(
              MediaQuery.of(context),
              data.settings,
            );
            return OylaLanguageScope(
              language: data.settings.language,
              child: MediaQuery(
                data: mediaQuery,
                child: data.settings.largeText
                    ? Builder(
                        builder: (context) => MediaQuery.withClampedTextScaling(
                          minScaleFactor:
                              data.settings.textSize == TextSize.largest
                              ? 1.4
                              : 1.18,
                          child: child!,
                        ),
                      )
                    : child!,
              ),
            );
          },
          theme: baseTheme.copyWith(
            textTheme: baseTheme.textTheme
                .apply(fontSizeFactor: 1.0)
                .copyWith(
                  bodyLarge: TextStyle(
                    fontSize: 18,
                    height: 1.4,
                    color: scheme.onSurface,
                  ),
                  bodyMedium: TextStyle(
                    fontSize: 18,
                    height: 1.4,
                    color: scheme.onSurface,
                  ),
                  bodySmall: TextStyle(
                    fontSize: 18,
                    height: 1.4,
                    color: scheme.onSurface,
                  ),
                  titleMedium: TextStyle(fontSize: 20, color: scheme.onSurface),
                  titleSmall: TextStyle(fontSize: 18, color: scheme.onSurface),
                  labelLarge: TextStyle(fontSize: 18, color: scheme.onSurface),
                ),
            scaffoldBackgroundColor: data.settings.highContrast
                ? scheme.surface
                : const Color(0xffFBF8F3),
            cardTheme: CardThemeData(
              elevation: 0,
              color: scheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            chipTheme: baseTheme.chipTheme.copyWith(
              side: BorderSide.none,
              selectedColor: scheme.secondaryContainer,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: data.settings.highContrast
                  ? scheme.surface
                  : const Color(0xffFBF8F3),
              scrolledUnderElevation: 0,
            ),
            materialTapTargetSize: MaterialTapTargetSize.padded,
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                minimumSize: const Size(64, 56),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          routerConfig: ref.watch(routerProvider),
        );
      },
    );
  }
}
