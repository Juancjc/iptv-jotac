import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final maxConcurrent = ref.watch(maxConcurrentDownloadsProvider);
    final subtitleFontSize = ref.watch(subtitleFontSizeProvider);
    final subtitleTextColor = ref.watch(subtitleTextColorProvider);
    final subtitleBackgroundColor = ref.watch(subtitleBackgroundColorProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Aparencia', style: Theme.of(context).textTheme.titleMedium),
        RadioGroup<ThemeMode>(
          groupValue: themeMode,
          onChanged: (value) =>
              ref.read(themeModeProvider.notifier).state = value!,
          child: const Column(
            children: [
              RadioListTile<ThemeMode>(
                title: Text('Escuro'),
                value: ThemeMode.dark,
              ),
              RadioListTile<ThemeMode>(
                title: Text('Claro'),
                value: ThemeMode.light,
              ),
              RadioListTile<ThemeMode>(
                title: Text('Seguir o sistema'),
                value: ThemeMode.system,
              ),
            ],
          ),
        ),
        const Divider(height: 32),
        Text('Downloads', style: Theme.of(context).textTheme.titleMedium),
        ListTile(
          title: const Text('Downloads simultaneos'),
          subtitle: Slider(
            value: maxConcurrent.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: '$maxConcurrent',
            onChanged: (value) =>
                ref.read(maxConcurrentDownloadsProvider.notifier).state = value
                    .round(),
          ),
          trailing: Text('$maxConcurrent'),
        ),
        const Divider(height: 32),
        Text('Legendas', style: Theme.of(context).textTheme.titleMedium),
        ListTile(
          title: const Text('Tamanho do texto'),
          subtitle: Slider(
            value: subtitleFontSize,
            min: 16,
            max: 44,
            divisions: 14,
            label: subtitleFontSize.round().toString(),
            onChanged: (value) =>
                ref.read(subtitleFontSizeProvider.notifier).state = value,
          ),
          trailing: Text(subtitleFontSize.round().toString()),
        ),
        _ColorOptionTile(
          title: 'Cor do texto',
          options: subtitleTextColorOptions,
          selected: subtitleTextColor,
          onSelected: (color) =>
              ref.read(subtitleTextColorProvider.notifier).state = color,
        ),
        _ColorOptionTile(
          title: 'Fundo da legenda',
          options: subtitleBackgroundColorOptions,
          selected: subtitleBackgroundColor,
          onSelected: (color) =>
              ref.read(subtitleBackgroundColorProvider.notifier).state = color,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _SubtitlePreview(
            fontSize: subtitleFontSize,
            textColor: subtitleTextColor,
            backgroundColor: subtitleBackgroundColor,
          ),
        ),
      ],
    );
  }
}

class _ColorOptionTile extends StatelessWidget {
  final String title;
  final Map<String, Color> options;
  final Color selected;
  final ValueChanged<Color> onSelected;

  const _ColorOptionTile({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(title),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Wrap(
          spacing: 10,
          children: [
            for (final entry in options.entries)
              ChoiceChip(
                label: Text(entry.key),
                selected: selected.toARGB32() == entry.value.toARGB32(),
                onSelected: (_) => onSelected(entry.value),
                avatar: CircleAvatar(
                  backgroundColor: entry.value.a == 0
                      ? theme.colorScheme.surfaceContainerHighest
                      : entry.value,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SubtitlePreview extends StatelessWidget {
  final double fontSize;
  final Color textColor;
  final Color backgroundColor;

  const _SubtitlePreview({
    required this.fontSize,
    required this.textColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        'Assim vai ficar a legenda',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          color: textColor,
          fontWeight: FontWeight.w600,
          backgroundColor: backgroundColor,
          height: 1.4,
        ),
      ),
    );
  }
}
