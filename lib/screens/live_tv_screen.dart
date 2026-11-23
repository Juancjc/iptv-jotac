import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../models/channel.dart';
import '../models/watch_history_entry.dart';
import '../providers/database_provider.dart';
import '../providers/epg_providers.dart';
import '../providers/playlist_providers.dart';
import '../services/epg_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/remote_content_action.dart';
import 'player_screen.dart';

class LiveTvScreen extends ConsumerStatefulWidget {
  const LiveTvScreen({super.key});

  @override
  ConsumerState<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends ConsumerState<LiveTvScreen> {
  String _search = '';
  String? _selectedCategory;
  bool _favoritesOnly = false;
  Channel? _selectedChannel;

  /// True while the channel plays in the fullscreen [PlayerScreen]; the
  /// inline player is removed meanwhile so only one stream/decoder is open
  /// (TV boxes often can't run two).
  bool _fullscreenOpen = false;
  Future<void>? _inlineDisposal;

  /// The sidebar shows one list at a time: the categories, or (once one is
  /// opened) only that category's channels. `_selectedCategory == null`
  /// with this set means "Todos os canais" is open.
  bool _categoryOpen = false;

  /// Remote-control focus targets: the "back to all lists" entry at the top
  /// of an open category, and the category tile the user came from.
  final _backToAllFocus = FocusNode(debugLabel: 'backToAllCategories');
  final _lastCategoryFocus = FocusNode(debugLabel: 'lastCategory');

  @override
  void dispose() {
    _backToAllFocus.dispose();
    _lastCategoryFocus.dispose();
    super.dispose();
  }

  /// Opens a category (`null` = all channels), replacing the category list
  /// with its channels; focus lands on the "back" entry at the top.
  void _openCategory(String? category) {
    setState(() {
      _selectedCategory = category;
      _categoryOpen = true;
    });
    _focusAfterBuild(_backToAllFocus);
  }

  /// Returns to the category list with focus on the category just left.
  /// `_selectedCategory` is kept so its tile can be found and highlighted.
  void _backToAllCategories() {
    setState(() => _categoryOpen = false);
    _focusAfterBuild(_lastCategoryFocus);
  }

  void _focusAfterBuild(FocusNode target) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && target.context != null) target.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(allChannelsProvider);

    // The remote's Back key leaves an open category before leaving the tab.
    return PopScope(
      canPop: !_categoryOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToAllCategories();
      },
      child: _buildContent(channelsAsync),
    );
  }

  Widget _buildContent(AsyncValue<List<Channel>> channelsAsync) {
    return channelsAsync.when(
      data: (channels) {
        final categoryCounts = <String, int>{};
        for (final channel in channels) {
          final category = _categoryOf(channel);
          categoryCounts.update(
            category,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
        }
        final categories = categoryCounts.keys.toList()
          ..sort((a, b) => a.compareTo(b));
        final visibleChannels = channels.where((channel) {
          final matchesSearch =
              _search.isEmpty || channel.name.toLowerCase().contains(_search);
          // Search and favorites look across every category unless one is open.
          final matchesCategory =
              !_categoryOpen ||
              _selectedCategory == null ||
              _categoryOf(channel) == _selectedCategory;
          final matchesFavorite = !_favoritesOnly || channel.isFavorite;
          return matchesSearch && matchesCategory && matchesFavorite;
        }).toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 760;
            final sidebar = _ChannelSidebar(
              channels: visibleChannels,
              totalChannelCount: channels.length,
              categories: categories,
              categoryCounts: categoryCounts,
              selectedCategory: _selectedCategory,
              categoryOpen: _categoryOpen,
              showChannels:
                  _categoryOpen || _search.isNotEmpty || _favoritesOnly,
              selectedChannelId: _selectedChannel?.id,
              favoritesOnly: _favoritesOnly,
              onSearchChanged: (value) =>
                  setState(() => _search = value.trim().toLowerCase()),
              onFavoritesChanged: (value) =>
                  setState(() => _favoritesOnly = value),
              onCategorySelected: _openCategory,
              onBackToAll: _backToAllCategories,
              lastCategoryFocus: _lastCategoryFocus,
              backToAllFocus: _backToAllFocus,
              // Wide layout: first click plays inline, clicking the playing
              // channel again (double click) expands it to fullscreen.
              onChannelSelected: (channel) {
                if (desktop && _selectedChannel?.id != channel.id) {
                  setState(() => _selectedChannel = channel);
                } else {
                  _openFullscreen(channel);
                }
              },
              onToggleFavorite: (channel) => ref
                  .read(playlistRepositoryProvider)
                  .toggleChannelFavorite(channel.id, !channel.isFavorite),
            );

            if (!desktop) return sidebar;
            return Row(
              children: [
                SizedBox(width: 310, child: sidebar),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _selectedChannel == null
                      ? const _ChannelPlaceholder()
                      : _fullscreenOpen
                      ? const ColoredBox(color: Colors.black)
                      : _InlineChannelPlayer(
                          key: ValueKey(_selectedChannel!.id),
                          channel: _selectedChannel!,
                          onFullscreen: () =>
                              _openFullscreen(_selectedChannel!),
                          onDisposed: (disposal) => _inlineDisposal = disposal,
                        ),
                ),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Erro ao carregar canais',
        message: error.toString(),
      ),
    );
  }

  Future<void> _openFullscreen(Channel channel) async {
    if (_fullscreenOpen) return;
    setState(() => _fullscreenOpen = true);
    try {
      // Remove the preview and release its decoder before opening another
      // player. Android TV boxes may only support one hardware decoder.
      await WidgetsBinding.instance.endOfFrame;
      await _inlineDisposal;
      if (!mounted) return;
      Future<void>? fullscreenDisposal;
      final route = MaterialPageRoute<void>(
        builder: (_) => PlayerScreen(
          title: channel.name,
          streamUrl: channel.streamUrl,
          contentId: channel.id,
          contentType: WatchableType.channel,
          posterUrl: channel.logoUrl,
          onDisposed: (disposal) => fullscreenDisposal = disposal,
        ),
      );
      await Navigator.of(context, rootNavigator: true).push(route);
      // push completes at pop time, before the exit transition disposes Video.
      await route.completed;
      await fullscreenDisposal;
    } finally {
      if (mounted) setState(() => _fullscreenOpen = false);
    }
  }

  String _categoryOf(Channel channel) {
    final category = channel.category?.trim();
    return category == null || category.isEmpty ? 'Sem categoria' : category;
  }
}

class _ChannelSidebar extends StatelessWidget {
  final List<Channel> channels;
  final int totalChannelCount;
  final List<String> categories;
  final Map<String, int> categoryCounts;
  final String? selectedCategory;
  final bool categoryOpen;

  /// Whether the single list shows channels (open category, search or
  /// favorites) instead of the categories.
  final bool showChannels;
  final String? selectedChannelId;
  final bool favoritesOnly;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<bool> onFavoritesChanged;
  final ValueChanged<String?> onCategorySelected;
  final VoidCallback onBackToAll;
  final FocusNode lastCategoryFocus;
  final FocusNode backToAllFocus;
  final ValueChanged<Channel> onChannelSelected;
  final ValueChanged<Channel> onToggleFavorite;

  const _ChannelSidebar({
    required this.channels,
    required this.totalChannelCount,
    required this.categories,
    required this.categoryCounts,
    required this.selectedCategory,
    required this.categoryOpen,
    required this.showChannels,
    required this.selectedChannelId,
    required this.favoritesOnly,
    required this.onSearchChanged,
    required this.onFavoritesChanged,
    required this.onCategorySelected,
    required this.onBackToAll,
    required this.lastCategoryFocus,
    required this.backToAllFocus,
    required this.onChannelSelected,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: TextField(
              onChanged: onSearchChanged,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, size: 20),
                hintText: 'Buscar canal...',
                isDense: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 2),
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.check, size: 17),
                  label: Text('Todos'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.star, size: 17),
                  label: Text('Favoritos'),
                ),
              ],
              selected: {favoritesOnly},
              onSelectionChanged: (selection) =>
                  onFavoritesChanged(selection.first),
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Text(
              'Segure OK ou pressione Menu para favoritar',
              style: TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 5),
          if (showChannels)
            ..._buildChannelList(colors)
          else
            ..._buildCategoryList(colors),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryList(ColorScheme colors) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.category_outlined, size: 16),
            const SizedBox(width: 7),
            Text(
              'Categorias',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: ListView.builder(
          // Keeps the scroll position when coming back from a category.
          key: const PageStorageKey('live-tv-categories'),
          padding: const EdgeInsets.symmetric(horizontal: 7),
          itemCount: categories.length + 1,
          itemBuilder: (context, index) {
            final category = index == 0 ? null : categories[index - 1];
            final selected = selectedCategory == category;
            return _CategoryTile(
              label: category ?? 'Todos os canais',
              count: category == null
                  ? totalChannelCount
                  : categoryCounts[category] ?? 0,
              selected: selected,
              focusNode: selected ? lastCategoryFocus : null,
              onTap: () => onCategorySelected(category),
            );
          },
        ),
      ),
    ];
  }

  List<Widget> _buildChannelList(ColorScheme colors) {
    return [
      if (categoryOpen)
        _BackToAllTile(
          focusNode: backToAllFocus,
          category: selectedCategory ?? 'Todos os canais',
          onTap: onBackToAll,
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
        child: Text(
          '${channels.length} ${channels.length == 1 ? 'canal' : 'canais'}',
          style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
        ),
      ),
      Expanded(
        child: channels.isEmpty
            ? Center(
                child: Text(
                  'Nenhum canal encontrado',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              )
            : ListView.builder(
                itemCount: channels.length,
                itemExtent: 48,
                itemBuilder: (context, index) {
                  final channel = channels[index];
                  final selected = channel.id == selectedChannelId;
                  return _ChannelTile(
                    key: ValueKey(channel.id),
                    channel: channel,
                    selected: selected,
                    onTap: () => onChannelSelected(channel),
                    onToggleFavorite: () => onToggleFavorite(channel),
                  );
                },
              ),
      ),
    ];
  }
}

/// First entry of an open category: goes back to the category list.
class _BackToAllTile extends StatelessWidget {
  final FocusNode focusNode;
  final String category;
  final VoidCallback onTap;

  const _BackToAllTile({
    required this.focusNode,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainer,
      child: InkWell(
        focusNode: focusNode,
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(Icons.arrow_back, size: 18, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Voltar para todas as listas',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final FocusNode? focusNode;

  const _CategoryTile({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: selected
            ? colors.primary.withValues(alpha: .22)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          focusNode: focusNode,
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: SizedBox(
            height: 30,
            child: Row(
              children: [
                const SizedBox(width: 9),
                if (selected) ...[
                  Icon(Icons.check, size: 15, color: colors.primary),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? colors.primary : colors.onSurface,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  final Channel channel;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const _ChannelTile({
    super.key,
    required this.channel,
    required this.selected,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? colors.primary.withValues(alpha: .14)
          : Colors.transparent,
      child: RemoteContentAction(
        onToggleFavorite: onToggleFavorite,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                height: 30,
                child: _ChannelLogo(url: channel.logoUrl),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  channel.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
              IconButton(
                tooltip: channel.isFavorite
                    ? 'Remover dos favoritos'
                    : 'Adicionar aos favoritos',
                visualDensity: VisualDensity.compact,
                iconSize: 19,
                color: channel.isFavorite
                    ? colors.primary
                    : colors.onSurfaceVariant,
                icon: Icon(channel.isFavorite ? Icons.star : Icons.star_border),
                onPressed: onToggleFavorite,
              ),
              const SizedBox(width: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelLogo extends StatelessWidget {
  final String? url;

  const _ChannelLogo({this.url});

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).colorScheme.surfaceContainer;
    if (url == null || url!.isEmpty) {
      return ColoredBox(
        color: background,
        child: const Icon(Icons.live_tv_outlined, size: 18),
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => ColoredBox(
        color: background,
        child: const Icon(Icons.live_tv_outlined, size: 18),
      ),
    );
  }
}

class _ChannelPlaceholder extends StatelessWidget {
  const _ChannelPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.live_tv_outlined,
            size: 72,
            color: colors.onSurfaceVariant.withValues(alpha: .72),
          ),
          const SizedBox(height: 20),
          Text(
            'Selecione um canal para assistir',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            'Clique duas vezes no canal para ver em tela cheia',
            style: TextStyle(
              fontSize: 12,
              color: colors.onSurfaceVariant.withValues(alpha: .8),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineChannelPlayer extends StatefulWidget {
  final Channel channel;
  final VoidCallback onFullscreen;
  final ValueChanged<Future<void>> onDisposed;

  const _InlineChannelPlayer({
    super.key,
    required this.channel,
    required this.onFullscreen,
    required this.onDisposed,
  });

  @override
  State<_InlineChannelPlayer> createState() => _InlineChannelPlayerState();
}

class _InlineChannelPlayerState extends State<_InlineChannelPlayer> {
  late final Player _player;
  late final VideoController _controller;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _player.open(Media(widget.channel.streamUrl));
  }

  @override
  void dispose() {
    widget.onDisposed(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.channel.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Discreet hint: the remote has no way to reach the video's
                // own fullscreen control on Android.
                Flexible(
                  child: Text(
                    'Clique 2x no canal para tela cheia · Voltar retorna',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: .55),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Tela cheia',
                  icon: const Icon(Icons.fullscreen, color: Colors.white),
                  onPressed: widget.onFullscreen,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: GestureDetector(
              onDoubleTap: widget.onFullscreen,
              // Android/Fire TV: the built-in controls aren't reachable with a
              // remote and would swallow the double tap.
              child: Video(
                controller: _controller,
                controls: Platform.isAndroid
                    ? NoVideoControls
                    : AdaptiveVideoControls,
              ),
            ),
          ),
          Expanded(flex: 2, child: _ChannelEpgPanel(channel: widget.channel)),
        ],
      ),
    );
  }
}

/// Program guide under the preview: the channel name and its schedule, with
/// the program on air highlighted.
class _ChannelEpgPanel extends ConsumerStatefulWidget {
  final Channel channel;

  const _ChannelEpgPanel({required this.channel});

  @override
  ConsumerState<_ChannelEpgPanel> createState() => _ChannelEpgPanelState();
}

class _ChannelEpgPanelState extends ConsumerState<_ChannelEpgPanel> {
  static const _onAirColor = Color(0xFFFFD54F);

  /// Moves the "on air" highlight along as programs end.
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final key = widget.channel.epgKey;
    final epgAsync = ref.watch(channelEpgProvider(key));
    final now = DateTime.now();
    final muted = Colors.white.withValues(alpha: .6);

    Widget body = epgAsync.when(
      loading: () => _message('Carregando programacao...', muted),
      error: (_, _) => _message('Programacao indisponivel', muted),
      data: (programs) {
        final upcoming = programs.where((p) => p.end.isAfter(now)).toList();
        if (upcoming.isEmpty) {
          // Short guides run out after a few hours; fetch the next batch.
          if (programs.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) ref.invalidate(channelEpgProvider(key));
            });
          }
          return _message('Programacao indisponivel', muted);
        }
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: upcoming.length,
          itemBuilder: (context, index) => _programLine(upcoming[index], now),
        );
      },
    );

    return Container(
      width: double.infinity,
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.channel.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _programLine(EpgProgram program, DateTime now) {
    final onAir = program.isLiveAt(now);
    final color = onAir ? _onAirColor : Colors.white.withValues(alpha: .85);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '${_time(program.start)} ~ ${_time(program.end)}   ${program.title}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: onAir ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }

  Widget _message(String text, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: TextStyle(color: color, fontSize: 13)),
    );
  }

  static String _time(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}';
  }
}
