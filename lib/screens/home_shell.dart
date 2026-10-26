import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/playlist_providers.dart';
import 'add_playlist_screen.dart';
import 'downloads_screen.dart';
import 'favorites_screen.dart';
import 'home_dashboard_screen.dart';
import 'live_tv_screen.dart';
import 'movies_screen.dart';
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

  static const _destinations = [
    NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: Text('Inicio')),
    NavigationRailDestination(
      icon: Icon(Icons.live_tv_outlined),
      selectedIcon: Icon(Icons.live_tv),
      label: Text('TV ao vivo'),
    ),
    NavigationRailDestination(icon: Icon(Icons.movie_outlined), selectedIcon: Icon(Icons.movie), label: Text('Filmes')),
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
      MoviesScreen(onShowMovies: () => _selectSection(2), onShowSeries: () => _selectSection(3)),
      SeriesScreen(onShowMovies: () => _selectSection(2), onShowSeries: () => _selectSection(3)),
      const FavoritesScreen(),
      const WatchHistoryScreen(),
      const DownloadsScreen(),
      PlaylistsScreen(onConnected: () => _selectSection(0)),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('IPTV Jotac'),
        bottom: syncStatuses.isEmpty ? null : _SyncProgressBar(statuses: syncStatuses.values.toList()),
        actions: [
          playlistsAsync.when(
            data: (playlists) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButton<String?>(
                value: selectedPlaylistId,
                hint: const Text('Todas as listas'),
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Todas as listas')),
                  for (final playlist in playlists)
                    DropdownMenuItem<String?>(value: playlist.id, child: Text(playlist.name)),
                ],
                onChanged: (value) => ref.read(selectedPlaylistIdProvider.notifier).state = value,
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar lista',
            onPressed: () => showDialog<void>(context: context, builder: (_) => const AddPlaylistScreen()),
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
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: KeyedSubtree(key: ValueKey(_index), child: screens[_index]),
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
