import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

final maxConcurrentDownloadsProvider = StateProvider<int>((ref) => 2);

/// Subtitle appearance, applied to every playback session. Kept simple
/// (text color + background + size) to match what TV remotes can reasonably
/// let someone tweak.
final subtitleFontSizeProvider = StateProvider<double>((ref) => 26);

final subtitleTextColorProvider = StateProvider<Color>((ref) => Colors.white);

final subtitleBackgroundColorProvider = StateProvider<Color>((ref) => const Color(0x99000000));

/// Named presets shown in the settings screen and on the pre-playback sheet.
const subtitleTextColorOptions = <String, Color>{
  'Branco': Colors.white,
  'Amarelo': Color(0xFFFFEB3B),
  'Ciano': Color(0xFF18FFFF),
};

const subtitleBackgroundColorOptions = <String, Color>{
  'Translucido': Color(0x99000000),
  'Solido': Color(0xFF000000),
  'Sem fundo': Color(0x00000000),
};
