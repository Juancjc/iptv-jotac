import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../models/channel.dart';
import '../models/watch_history_entry.dart';
import '../providers/database_provider.dart';
import '../providers/playlist_providers.dart';
import '../widgets/empty_state.dart';
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

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(allChannelsProvider);

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
          final matchesCategory =
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
              selectedChannelId: _selectedChannel?.id,
              favoritesOnly: _favoritesOnly,
              onSearchChanged: (value) =>
                  setState(() => _search = value.trim().toLowerCase()),
              onFavoritesChanged: (value) =>
                  setState(() => _favoritesOnly = value),
              onCategorySelected: (value) =>
                  setState(() => _selectedCategory = value),
              onChannelSelected: (channel) {
                if (desktop) {
                  setState(() => _selectedChannel = channel);
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PlayerScreen(
                        title: channel.name,
                        streamUrl: channel.streamUrl,
                        contentId: channel.id,
                        contentType: WatchableType.channel,
                        posterUrl: channel.logoUrl,
                      ),
                    ),
                  );
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
                      : _InlineChannelPlayer(
                          key: ValueKey(_selectedChannel!.id),
                          channel: _selectedChannel!,
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
  final String? selectedChannelId;
  final bool favoritesOnly;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<bool> onFavoritesChanged;
  final ValueChanged<String?> onCategorySelected;
  final ValueChanged<Channel> onChannelSelected;
  final ValueChanged<Channel> onToggleFavorite;

  const _ChannelSidebar({
    required this.channels,
    required this.totalChannelCount,
    required this.categories,
    required this.categoryCounts,
    required this.selectedCategory,
    required this.selectedChannelId,
    required this.favoritesOnly,
    required this.onSearchChanged,
    required this.onFavoritesChanged,
    required this.onCategorySelected,
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
          const SizedBox(height: 5),
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
          Flexible(
            flex: 4,
            child: ListView.builder(
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
                  onTap: () => onCategorySelected(category),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: Text(
              '${channels.length} ${channels.length == 1 ? 'canal' : 'canais'}',
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            ),
          ),
          Expanded(
            flex: 5,
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
                        channel: channel,
                        selected: selected,
                        onTap: () => onChannelSelected(channel),
                        onToggleFavorite: () => onToggleFavorite(channel),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
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
      child: InkWell(
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
        ],
      ),
    );
  }
}

class _InlineChannelPlayer extends StatefulWidget {
  final Channel channel;

  const _InlineChannelPlayer({super.key, required this.channel});

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
    _player.dispose();
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              widget.channel.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(child: Video(controller: _controller)),
        ],
      ),
    );
  }
}
