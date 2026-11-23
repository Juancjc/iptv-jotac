import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'navigation.dart';
import 'providers/settings_providers.dart';
import 'screens/home_shell.dart';

class IptvJotacApp extends ConsumerWidget {
  const IptvJotacApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    final darkScheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFFB71C1C),
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFFE04848),
          onPrimary: Colors.white,
          secondary: const Color(0xFFC5323A),
          surface: const Color(0xFF0A0D14),
          surfaceContainer: const Color(0xFF171D29),
          surfaceContainerHigh: const Color(0xFF202837),
          surfaceContainerHighest: const Color(0xFF2B3444),
          outline: const Color(0xFF8F858F),
          outlineVariant: const Color(0xFF364052),
          error: const Color(0xFFFF5A5F),
          errorContainer: const Color(0xFF5C171B),
        );

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'IPTV Jotac',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFB71C1C),
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: darkScheme,
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        cardTheme: CardThemeData(
          color: darkScheme.surfaceContainer,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: darkScheme.outlineVariant),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0D14),
          surfaceTintColor: Colors.transparent,
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: const Color(0xFF0A0D14),
          indicatorColor: darkScheme.primary.withValues(alpha: .2),
          selectedIconTheme: IconThemeData(color: darkScheme.primary),
          selectedLabelTextStyle: TextStyle(
            color: darkScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkScheme.surfaceContainer,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: darkScheme.primary, width: 1.4),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: darkScheme.onSurface,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            side: BorderSide(color: darkScheme.outlineVariant),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          side: BorderSide(color: darkScheme.outlineVariant),
          selectedColor: darkScheme.primary.withValues(alpha: .18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        focusColor: darkScheme.primary.withValues(alpha: .25),
        dividerColor: darkScheme.outlineVariant,
      ),
      home: const HomeShell(),
    );
  }
}
