import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/remote_control_providers.dart';
import '../providers/settings_providers.dart';
import '../widgets/remote_control_dialog.dart';
import 'playlists_screen.dart';

/// Whether the phone remote is on, with a button to show its QR code.
class _RemoteControlStatus extends ConsumerWidget {
  const _RemoteControlStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remote = ref.watch(remoteControlProvider);
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        remote.active ? Icons.phonelink : Icons.phonelink_off,
        color: remote.active ? colors.primary : colors.onSurfaceVariant,
      ),
      title: Text(remote.active ? 'Ativo' : 'Desligado'),
      subtitle: remote.active ? Text(remote.url.toString()) : null,
      trailing: OutlinedButton(
        onPressed: () async {
          if (!remote.active) {
            await ref.read(remoteControlProvider.notifier).enable();
          }
          if (context.mounted) {
            await showDialog<void>(
              context: context,
              builder: (_) => const RemoteControlDialog(),
            );
          }
        },
        child: Text(remote.active ? 'Mostrar QR code' : 'Ligar'),
      ),
    );
  }
}

class _SettingsSection extends ConsumerWidget {
  final int section;
  const _SettingsSection(this.section);

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
        if (section == 0) ...[
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
        ],
        if (section == 1) ...[
          Text(
            'Controle pelo celular',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const _RemoteControlStatus(),
          const RemoteControlOptions(),
        ],
        if (section == 2) ...[
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
                  ref.read(maxConcurrentDownloadsProvider.notifier).state =
                      value.round(),
            ),
            trailing: Text('$maxConcurrent'),
          ),
        ],
        if (section == 3) ...[
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
                ref.read(subtitleBackgroundColorProvider.notifier).state =
                    color,
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

class SettingsScreen extends StatelessWidget {
  final VoidCallback? onPlaylists;
  const SettingsScreen({super.key, this.onPlaylists});

  @override
  Widget build(BuildContext context) {
    const sections = [
      (
        'Design e cores',
        'Tema claro, escuro ou do sistema',
        Icons.palette_outlined,
        Color(0xFFD9AC50),
      ),
      (
        'Controle pelo celular',
        'Conexão, QR code e inicialização',
        Icons.phonelink,
        Color(0xFF70C97A),
      ),
      (
        'Downloads',
        'Limite de downloads simultâneos',
        Icons.download_outlined,
        Color(0xFF57BEB1),
      ),
      (
        'Áudio e legendas',
        'Estilo das legendas • áudio no player',
        Icons.subtitles_outlined,
        Color(0xFF64B4DC),
      ),
      (
        'Playlists',
        'Gerenciar e atualizar suas listas',
        Icons.playlist_play,
        Color(0xFFA08AE6),
      ),
    ];
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth >= 1100
            ? 3
            : box.maxWidth >= 650
            ? 2
            : 1;
        final inset = box.maxWidth < 650 ? 20.0 : 40.0;
        final width = (box.maxWidth - inset * 2 - (columns - 1) * 16) / columns;
        return ListView(
          padding: EdgeInsets.fromLTRB(inset, 26, inset, 32),
          children: [
            Text(
              'Configurações',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tudo sobre aparência, reprodução e suas listas.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (var i = 0; i < sections.length; i++)
                  SizedBox(
                    width: width,
                    child: Material(
                      color: Colors.transparent,
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: sections[i].$4.withValues(alpha: .45),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              sections[i].$4.withValues(alpha: .25),
                              sections[i].$4.withValues(alpha: .06),
                            ],
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            if (i == 4) {
                              if (onPlaylists != null) {
                                onPlaylists!();
                              } else {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => Scaffold(
                                      appBar: AppBar(
                                        title: const Text('Playlists'),
                                      ),
                                      body: const PlaylistsScreen(),
                                    ),
                                  ),
                                );
                              }
                              return;
                            }
                            showDialog<void>(
                              context: context,
                              builder: (_) => Dialog(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 600,
                                    maxHeight: 620,
                                  ),
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          24,
                                          12,
                                          12,
                                          4,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                sections[i].$1,
                                                style:
                                                    theme.textTheme.titleLarge,
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: 'Fechar',
                                              icon: const Icon(Icons.close),
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(child: _SettingsSection(i)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: sections[i].$4.withValues(
                                    alpha: .2,
                                  ),
                                  child: Icon(
                                    sections[i].$3,
                                    color: sections[i].$4,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sections[i].$1,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        sections[i].$2,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.offline_bolt_outlined),
              title: Text('Sua biblioteca abre com os dados salvos'),
              subtitle: Text(
                'As listas não são baixadas ao abrir o app. Use Atualizar listas no topo ou Atualizar todas em Playlists quando quiser buscar novidades.',
              ),
            ),
          ],
        );
      },
    );
  }
}
