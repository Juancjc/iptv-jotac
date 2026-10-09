import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/settings_providers.dart';
import 'screens/home_shell.dart';

class IptvJotacApp extends ConsumerWidget {
  const IptvJotacApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'IPTV Jotac',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, brightness: Brightness.light, useMaterial3: true),
      darkTheme: ThemeData(colorSchemeSeed: Colors.indigo, brightness: Brightness.dark, useMaterial3: true),
      home: const HomeShell(),
    );
  }
}
