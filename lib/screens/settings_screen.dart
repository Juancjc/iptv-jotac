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
                for (final playlist in playlists)
                  _PlaylistTile(
                    playlist: playlist,
                    syncing: syncingIds.contains(playlist.id),
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
      ],
    );
  }
}

class _PlaylistTile extends ConsumerStatefulWidget {
  final Playlist playlist;
  final bool syncing;

  const _PlaylistTile({required this.playlist, required this.syncing});

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
