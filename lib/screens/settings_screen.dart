import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/playlist.dart';
import '../providers/database_provider.dart';
import '../providers/playlist_providers.dart';
import '../providers/settings_providers.dart';
import '../widgets/insecure_connection_banner.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);
    final syncingIds = ref.watch(syncingPlaylistIdsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final maxConcurrent = ref.watch(maxConcurrentDownloadsProvider);
    final subtitleFontSize = ref.watch(subtitleFontSizeProvider);
    final subtitleTextColor = ref.watch(subtitleTextColorProvider);
    final subtitleBackgroundColor = ref.watch(subtitleBackgroundColorProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Listas cadastradas',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        playlistsAsync.when(
          data: (playlists) {
            if (playlists.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Nenhuma lista cadastrada ainda.'),
              );
            }
            return Column(
              children: [
                for (final (index, playlist) in playlists.indexed)
                  _PlaylistTile(
                    playlist: playlist,
                    syncing: syncingIds.contains(playlist.id),
                    autofocusRefresh: index == 0,
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('Erro ao carregar listas: $error'),
        ),
        const Divider(height: 32),
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
                  backgroundColor: entry.value.a == 0 ? theme.colorScheme.surfaceContainerHighest : entry.value,
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

class _PlaylistTile extends ConsumerStatefulWidget {
  final Playlist playlist;
  final bool syncing;
  final bool autofocusRefresh;

  const _PlaylistTile({
    required this.playlist,
    required this.syncing,
    this.autofocusRefresh = false,
  });

  @override
  ConsumerState<_PlaylistTile> createState() => _PlaylistTileState();
}

class _PlaylistTileState extends ConsumerState<_PlaylistTile> {
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final playlist = widget.playlist;
    final busy = widget.syncing || _deleting;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (playlist.isInsecure) const InsecureConnectionBanner(),
            Row(
              children: [
                Icon(
                  playlist.type == PlaylistType.m3u
                      ? Icons.link
                      : Icons.dns_outlined,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        playlist.type == PlaylistType.m3u
                            ? playlist.m3uUrl ?? ''
                            : playlist.xtreamHost ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (playlist.lastSyncedAt != null)
                        Text(
                          'Ultima atualizacao: ${playlist.lastSyncedAt}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                if (busy)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Atualizar lista',
                    autofocus: widget.autofocusRefresh,
                    onPressed: () =>
                        ref.read(playlistSyncControllerProvider).sync(playlist),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Theme.of(context).colorScheme.error,
                  tooltip: 'Excluir lista',
                  onPressed: busy ? null : _confirmRemove,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRemove() async {
    final playlist = widget.playlist;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.delete_forever_outlined,
          color: Theme.of(context).colorScheme.error,
        ),
        title: const Text('Excluir lista?'),
        content: Text(
          'A lista "${playlist.name}" e todo o conteudo associado serao excluidos deste dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(playlistRepositoryProvider).removePlaylist(playlist.id);
      if (ref.read(selectedPlaylistIdProvider) == playlist.id) {
        ref.read(selectedPlaylistIdProvider.notifier).state = null;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lista "${playlist.name}" excluida')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nao foi possivel excluir a lista: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }
}
