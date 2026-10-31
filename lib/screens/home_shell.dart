import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../navigation.dart';

import '../providers/database_provider.dart';
import '../providers/playlist_providers.dart';
import '../providers/remote_control_providers.dart';
import 'add_playlist_screen.dart';
import 'downloads_screen.dart';
import 'favorites_screen.dart';
import 'home_dashboard_screen.dart';
import 'live_tv_screen.dart';
import 'movies_screen.dart';
import 'player_screen.dart';
import 'playlists_screen.dart';
import 'series_screen.dart';
import 'settings_screen.dart';
import 'watch_history_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;
  StreamSubscription<RemoteCommand>? _remoteCommands;

  @override
  void initState() {
    super.initState();
    _remoteCommands = ref
        .read(remoteCommandsProvider)
        .stream
        .listen(_onRemoteCommand);
    // Lists change often on the provider side, so they are downloaded again
    // every time the app opens. The cached content stays usable meanwhile.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncAllPlaylists());
  }

  @override
  void dispose() {
    _remoteCommands?.cancel();
    super.dispose();
  }

  bool _openingFromRemote = false;

  /// Runs what the phone asked for: close whatever is open (player, dialogs)
  /// and either go home or play the chosen content.
  Future<void> _onRemoteCommand(RemoteCommand command) async {
    if (_openingFromRemote) return;
    _openingFromRemote = true;
    try {
      final navigator = rootNavigatorKey.currentState;
      if (navigator == null) return;
      var closedSomething = false;
      navigator.popUntil((route) {
        if (route.isFirst) return true;
        closedSomething = true;
        return false;
      });
      // The live TV tab keeps a preview player; leaving it releases that
      // decoder, which TV boxes need before opening another stream.
      final leftLiveTv = _index == 1;
      if (_index != 0) _selectSection(0);
      if (closedSomething || leftLiveTv) {
        await Future<void>.delayed(const Duration(milliseconds: 600));
      }
      if (!mounted || command is! RemotePlay) return;
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => PlayerScreen(
              title: command.title,
              streamUrl: command.streamUrl,
              contentId: command.contentId,
              contentType: command.contentType,
              posterUrl: command.posterUrl,
            ),
          ),
        ),
      );
    } finally {
      _openingFromRemote = false;
    }
  }

  Future<void> _toggleRemoteControl() async {
    final notifier = ref.read(remoteControlProvider.notifier);
    if (!ref.read(remoteControlProvider).active) {
      unawaited(notifier.enable());
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => const _RemoteControlDialog(),
    );
  }

  Future<void> _syncAllPlaylists() async {
    final playlists = await ref
        .read(playlistRepositoryProvider)
        .watchPlaylists()
        .first;
    final controller = ref.read(playlistSyncControllerProvider);
    // One at a time: TV boxes have little memory for parsing big lists.
    for (final playlist in playlists) {
      if (!mounted) return;
      if (ref.read(syncingPlaylistIdsProvider).contains(playlist.id)) continue;
      try {
        await controller.sync(playlist);
      } catch (_) {
        // Recorded in playlistSyncErrorsProvider and shown on the Listas tab;
        // the previously downloaded content keeps working.
      }
    }
  }

  static const _destinations = [
    NavigationRailDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: Text('Inicio'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.live_tv_outlined),
      selectedIcon: Icon(Icons.live_tv),
      label: Text('TV ao vivo'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.movie_outlined),
      selectedIcon: Icon(Icons.movie),
      label: Text('Filmes'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.video_library_outlined),
      selectedIcon: Icon(Icons.video_library),
      label: Text('Series'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.favorite_outline),
      selectedIcon: Icon(Icons.favorite),
      label: Text('Favoritos'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.history_outlined),
      selectedIcon: Icon(Icons.history),
      label: Text('Assistidos'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.download_outlined),
      selectedIcon: Icon(Icons.download),
      label: Text('Downloads'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.playlist_play_outlined),
      selectedIcon: Icon(Icons.playlist_play),
      label: Text('Listas'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: Text('Configuracoes'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final playlistsAsync = ref.watch(playlistsProvider);
    final selectedPlaylistId = ref.watch(selectedPlaylistIdProvider);
    final syncStatuses = ref.watch(playlistSyncStatusProvider);
    final screens = [
      HomeDashboardScreen(onSectionSelected: _selectSection),
      const LiveTvScreen(),
      MoviesScreen(
        onShowMovies: () => _selectSection(2),
        onShowSeries: () => _selectSection(3),
      ),
      SeriesScreen(
        onShowMovies: () => _selectSection(2),
        onShowSeries: () => _selectSection(3),
      ),
      const FavoritesScreen(),
      const WatchHistoryScreen(),
      const DownloadsScreen(),
      PlaylistsScreen(onConnected: () => _selectSection(0)),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('IPTV Jotac'),
        bottom: syncStatuses.isEmpty
            ? null
            : _SyncProgressBar(statuses: syncStatuses.values.toList()),
        actions: [
          playlistsAsync.when(
            data: (playlists) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButton<String?>(
                value: selectedPlaylistId,
                hint: const Text('Todas as listas'),
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Todas as listas'),
                  ),
                  for (final playlist in playlists)
                    DropdownMenuItem<String?>(
                      value: playlist.id,
                      child: Text(playlist.name),
                    ),
                ],
                onChanged: (value) =>
                    ref.read(selectedPlaylistIdProvider.notifier).state = value,
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar lista',
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const AddPlaylistScreen(),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Scrollable so every section stays reachable on short screens
          // (e.g. Fire TV renders at ~540dp tall).
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: NavigationRail(
                    selectedIndex: _index,
                    onDestinationSelected: _selectSection,
                    labelType: NavigationRailLabelType.all,
                    destinations: _destinations,
                    trailing: _RemoteControlRailButton(
                      onPressed: _toggleRemoteControl,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: KeyedSubtree(
                key: ValueKey(_index),
                child: screens[_index],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectSection(int index) {
    if (_index == index) return;
    ref.read(searchQueryProvider.notifier).state = '';
    setState(() => _index = index);
  }
}

/// Thin bar under the app bar shown on every tab while a playlist is being
/// loaded, so a big list taking minutes doesn't look like a frozen app.
class _SyncProgressBar extends StatelessWidget implements PreferredSizeWidget {
  final List<PlaylistSyncStatus> statuses;

  const _SyncProgressBar({required this.statuses});

  @override
  Size get preferredSize => const Size.fromHeight(26);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = statuses.first;
    final extra = statuses.length > 1 ? ' (+${statuses.length - 1})' : '';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Row(
            children: [
              Icon(Icons.sync, size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Carregando "${first.playlistName}"$extra: ${first.message}',
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        LinearProgressIndicator(value: first.progress, minHeight: 2),
      ],
    );
  }
}

/// Sidebar button that turns the phone remote control on/off.
class _RemoteControlRailButton extends ConsumerWidget {
  final VoidCallback onPressed;

  const _RemoteControlRailButton({required this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remote = ref.watch(remoteControlProvider);
    final colors = Theme.of(context).colorScheme;
    final color = remote.active ? colors.primary : colors.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              remote.starting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      remote.active ? Icons.phonelink : Icons.phonelink_off,
                      color: color,
                    ),
              const SizedBox(height: 4),
              Text(
                remote.active ? 'Controle ON' : 'Controle',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: remote.active ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the QR code / address for the phone and lets the user turn the
/// remote control off.
class _RemoteControlDialog extends ConsumerWidget {
  const _RemoteControlDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remote = ref.watch(remoteControlProvider);
    final theme = Theme.of(context);
    final url = remote.url;

    Widget content;
    if (remote.error != null) {
      content = Text(
        remote.error!,
        style: TextStyle(color: theme.colorScheme.error),
      );
    } else if (url == null) {
      content = const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fixed size: AlertDialog measures intrinsic widths, which the QR
          // widget (built on LayoutBuilder) can't answer.
          SizedBox(
            width: 186,
            height: 186,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8),
              child: QrImageView(data: url.toString(), size: 170),
            ),
          ),
          const SizedBox(width: 20),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Leia o QR code com o celular (mesma rede Wi-Fi) ou abra no navegador:',
                ),
                const SizedBox(height: 8),
                SelectableText(
                  url.toString(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'No celular, escolha entre usar so o controle (setas e OK) '
                  'ou escolher direto o que assistir: listas, canais, filmes '
                  'e series, com busca.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Controle pelo celular'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(child: content),
      ),
      actions: [
        if (remote.active)
          TextButton(
            onPressed: () {
              ref.read(remoteControlProvider.notifier).disable();
              Navigator.of(context).pop();
            },
            child: const Text('Desativar'),
          ),
        FilledButton(
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(remote.active ? 'Manter ativo' : 'Fechar'),
        ),
      ],
    );
  }
}
