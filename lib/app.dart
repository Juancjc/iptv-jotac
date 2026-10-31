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
          surface: const Color(0xFF121014),
          surfaceContainer: const Color(0xFF29262C),
          surfaceContainerHigh: const Color(0xFF332E34),
          surfaceContainerHighest: const Color(0xFF3D373E),
          outline: const Color(0xFF8F858F),
          outlineVariant: const Color(0xFF494149),
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
        scaffoldBackgroundColor: const Color(0xFF100E12),
        cardTheme: CardThemeData(
          color: darkScheme.surfaceContainer,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: darkScheme.outlineVariant),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121014),
          surfaceTintColor: Colors.transparent,
        ),
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: const Color(0xFF121014),
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
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(color: darkScheme.primary, width: 1.4),
          ),
        ),
        dividerColor: darkScheme.outlineVariant,
      ),
      home: const HomeShell(),
    );
  }
}
