import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navigation.dart';

import '../providers/database_provider.dart';
import '../widgets/library_search.dart';
import '../providers/playlist_providers.dart';
import '../providers/remote_control_providers.dart';
import '../widgets/remote_control_dialog.dart';
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
    // Turns the phone remote control on by itself when the user chose
    // "ligar sempre ao abrir o app".
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(remoteControlProvider.notifier).initialize(),
    );
    // Open the local library immediately. Network refresh is explicit.
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
      builder: (_) => const RemoteControlDialog(),
    );
  }

  Future<void> _syncAllPlaylists() async {
    final playlists = await ref
        .read(playlistRepositoryProvider)
        .watchPlaylists()
        .first;
    if (!mounted) return;
    var failed = 0;
    final controller = ref.read(playlistSyncControllerProvider);
    // One at a time: TV boxes have little memory for parsing big lists.
    for (final playlist in playlists) {
      if (!mounted) return;
      if (ref.read(syncingPlaylistIdsProvider).contains(playlist.id)) continue;
      try {
        await controller.sync(playlist);
      } catch (_) {
        failed++;
        // Recorded in playlistSyncErrorsProvider and shown on the Listas tab;
        // the previously downloaded content keeps working.
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failed == 0
                ? 'Listas atualizadas'
                : 'Falha em $failed lista(s). Veja os detalhes em Listas.',
          ),
        ),
      );
    }
  }

  static const _destinations = [
    NavigationRailDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: Text('Início'),
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
      label: Text('Séries'),
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
      label: Text('Configurações'),
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
      SettingsScreen(onPlaylists: () => _selectSection(7)),
    ];

    final compact = MediaQuery.sizeOf(context).width < 700;

    Widget navigation({bool drawer = false}) => SafeArea(
      child: SizedBox(
        width: drawer ? 220 : 76,
        child: Column(
          children: [
            if (!drawer)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Image.asset(
                  "assets/images/icone.png",
                  width: 36,
                  height: 36,
                ),
              ),
            if (drawer)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: Row(
                  children: [
                    Icon(
                      Icons.play_circle_filled,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'JOTAC',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                children: [
                  for (var i = 0; i < _destinations.length; i++) ...[
                    if (i == 4 || i == 7)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Tooltip(
                        message: (_destinations[i].label as Text).data!,
                        child: Material(
                          color: i == _index
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: .16)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              if (drawer) Navigator.of(context).pop();
                              _selectSection(i);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              child: Row(
                                mainAxisAlignment: drawer
                                    ? MainAxisAlignment.start
                                    : MainAxisAlignment.center,
                                children: [
                                  IconTheme(
                                    data: IconThemeData(
                                      size: 22,
                                      color: i == _index
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                    ),
                                    child: i == _index
                                        ? _destinations[i].selectedIcon
                                        : _destinations[i].icon,
                                  ),
                                  if (drawer) ...[
                                    const SizedBox(width: 14),
                                    DefaultTextStyle(
                                      style: TextStyle(
                                        color: i == _index
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                        fontWeight: i == _index
                                            ? FontWeight.w800
                                            : FontWeight.w500,
                                      ),
                                      child: _destinations[i].label,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  _RemoteControlRailButton(onPressed: _toggleRemoteControl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return Scaffold(
      drawer: compact ? Drawer(child: navigation(drawer: true)) : null,
      appBar: AppBar(
        title: compact
            ? const Text('Jotac', style: TextStyle(fontWeight: FontWeight.w800))
            : ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                  ),
                  icon: const Icon(Icons.search, size: 20),
                  label: const Text(
                    'Buscar canais, filmes e séries…',
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: () => showLibrarySearch(context),
                ),
              ),
        titleSpacing: 24,
        bottom: syncStatuses.isEmpty
            ? null
            : _SyncProgressBar(statuses: syncStatuses.values.toList()),
        actions: [
          if (compact)
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Buscar na biblioteca',
              onPressed: () => showLibrarySearch(context),
            ),
          if (MediaQuery.sizeOf(context).width >= 1100) const _HeaderClock(),
          if (!compact)
            playlistsAsync.when(
              data: (playlists) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  width: compact ? 180 : 220,
                  child: DropdownButton<String?>(
                    isExpanded: true,
                    value: playlists.any((p) => p.id == selectedPlaylistId)
                        ? selectedPlaylistId
                        : null,
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
                          child: Text(
                            playlist.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) =>
                        ref.read(selectedPlaylistIdProvider.notifier).state =
                            value,
                  ),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Atualizar listas',
            onPressed:
                syncStatuses.isNotEmpty ||
                    !(playlistsAsync.valueOrNull?.isNotEmpty ?? false)
                ? null
                : _syncAllPlaylists,
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
          if (!compact) ...[
            navigation(),
            VerticalDivider(
              width: 1,
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: .4),
            ),
          ],
          Expanded(
            child: KeyedSubtree(key: ValueKey(_index), child: screens[_index]),
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
      child: Tooltip(
        message: remote.active
            ? "Controle pelo celular ativo"
            : "Controle pelo celular",
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderClock extends StatefulWidget {
  const _HeaderClock();
  @override
  State<_HeaderClock> createState() => _HeaderClockState();
}

class _HeaderClockState extends State<_HeaderClock> {
  late final Timer _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          Text(
            '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
