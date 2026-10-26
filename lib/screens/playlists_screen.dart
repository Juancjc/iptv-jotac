import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/playlist.dart';
import '../providers/database_provider.dart';
import '../providers/playlist_providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/insecure_connection_banner.dart';
import 'add_playlist_screen.dart';

/// Lists every registered playlist and lets the user connect to one (make it
/// the active source), fetch its content again, edit or remove it.
class PlaylistsScreen extends ConsumerWidget {
  /// Called after the user connects to a playlist, so the shell can jump to
  /// a content section.
  final VoidCallback? onConnected;

  const PlaylistsScreen({super.key, this.onConnected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);
    final syncingIds = ref.watch(syncingPlaylistIdsProvider);
    final selectedId = ref.watch(selectedPlaylistIdProvider);

    return playlistsAsync.when(
      data: (playlists) {
        final header = Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Minhas listas', style: Theme.of(context).textTheme.titleLarge),
              FilledButton.icon(
                autofocus: playlists.isEmpty,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar lista'),
                onPressed: () => showDialog<void>(context: context, builder: (_) => const AddPlaylistScreen()),
              ),
              if (playlists.length > 1)
                OutlinedButton.icon(
                  icon: const Icon(Icons.sync),
                  label: const Text('Atualizar todas'),
                  onPressed: syncingIds.isNotEmpty ? null : () => _syncAll(context, ref, playlists),
                ),
            ],
          ),
        );

        if (playlists.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const Expanded(
                child: EmptyState(
                  icon: Icons.playlist_add,
                  title: 'Nenhuma lista cadastrada',
                  message: 'Adicione uma lista M3U ou Xtream Codes para comecar.',
                ),
              ),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            header,
            for (final (index, playlist) in playlists.indexed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: PlaylistCard(
                  playlist: playlist,
                  syncing: syncingIds.contains(playlist.id),
                  connected: selectedId == playlist.id,
                  autofocus: index == 0,
                  onConnected: onConnected,
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Erro ao carregar listas: $error')),
    );
  }

  Future<void> _syncAll(BuildContext context, WidgetRef ref, List<Playlist> playlists) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final controller = ref.read(playlistSyncControllerProvider);
    final failed = <String>[];
    for (final playlist in playlists) {
      try {
        await controller.sync(playlist);
      } catch (_) {
        failed.add(playlist.name);
      }
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          failed.isEmpty ? 'Todas as listas foram atualizadas' : 'Falha ao atualizar: ${failed.join(', ')}',
        ),
        backgroundColor: failed.isEmpty ? null : errorColor,
      ),
    );
  }
}

class PlaylistCard extends ConsumerStatefulWidget {
  final Playlist playlist;
  final bool syncing;
  final bool connected;
  final bool autofocus;
  final VoidCallback? onConnected;

  const PlaylistCard({
    super.key,
    required this.playlist,
    required this.syncing,
    required this.connected,
    this.autofocus = false,
    this.onConnected,
  });

  @override
  ConsumerState<PlaylistCard> createState() => _PlaylistCardState();
}

class _PlaylistCardState extends ConsumerState<PlaylistCard> {
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playlist = widget.playlist;
    final busy = widget.syncing || _deleting;
    final source = playlist.type == PlaylistType.m3u ? playlist.m3uUrl ?? '' : playlist.xtreamHost ?? '';
    final status = ref.watch(playlistSyncStatusProvider.select((map) => map[playlist.id]));
    final syncError = ref.watch(playlistSyncErrorsProvider.select((map) => map[playlist.id]));

    return Card(
      shape: widget.connected
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: theme.colorScheme.primary, width: 1.6),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (playlist.isInsecure) const InsecureConnectionBanner(),
            Row(
              children: [
                Icon(playlist.type == PlaylistType.m3u ? Icons.link : Icons.dns_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(playlist.name, style: theme.textTheme.titleSmall, overflow: TextOverflow.ellipsis),
                          ),
                          if (widget.connected) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Conectada',
                              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        playlist.type == PlaylistType.m3u ? 'M3U · $source' : 'Xtream · $source',
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.syncing
                            ? status?.message ?? 'Atualizando conteudo...'
                            : playlist.lastSyncedAt == null
                            ? 'Ainda nao atualizada'
                            : 'Ultima atualizacao: ${_formatDate(playlist.lastSyncedAt!)}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ),
                if (busy)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
              ],
            ),
            if (widget.syncing)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(value: status?.progress),
              ),
            if (syncError != null && !widget.syncing)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Falha na ultima atualizacao: $syncError',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                FilledButton.tonalIcon(
                  autofocus: widget.autofocus,
                  icon: Icon(widget.connected ? Icons.check_circle : Icons.power_settings_new),
                  label: Text(widget.connected ? 'Conectada' : 'Conectar'),
                  onPressed: busy ? null : _connect,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Atualizar'),
                  onPressed: busy ? null : _sync,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                  onPressed: busy ? null : _edit,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Excluir'),
                  style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                  onPressed: busy ? null : _confirmRemove,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} ${two(date.hour)}:${two(date.minute)}';
  }

  /// Makes this playlist the active source. A playlist that was never synced
  /// has no content yet, so it is fetched right away.
  Future<void> _connect() async {
    final playlist = widget.playlist;
    ref.read(selectedPlaylistIdProvider.notifier).state = playlist.id;
    if (playlist.lastSyncedAt == null) {
      final ok = await _sync();
      if (!ok) return;
    }
    widget.onConnected?.call();
  }

  Future<bool> _sync() async {
    final playlist = widget.playlist;
    try {
      await ref.read(playlistSyncControllerProvider).sync(playlist);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lista "${playlist.name}" atualizada')));
      }
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nao foi possivel atualizar "${playlist.name}": $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return false;
    }
  }

  Future<void> _edit() async {
    await showDialog<void>(context: context, builder: (_) => AddPlaylistScreen(playlist: widget.playlist));
  }

  Future<void> _confirmRemove() async {
    final playlist = widget.playlist;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.delete_forever_outlined, color: Theme.of(context).colorScheme.error),
        title: const Text('Excluir lista?'),
        content: Text('A lista "${playlist.name}" e todo o conteudo associado serao excluidos deste dispositivo.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lista "${playlist.name}" excluida')));
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
