import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/movie.dart';
import '../models/watch_history_entry.dart';
import '../providers/playlist_providers.dart';
import '../providers/watch_history_providers.dart';
import '../widgets/content_card.dart';
import 'player_screen.dart';
import 'series_detail_screen.dart';

class HomeDashboardScreen extends ConsumerWidget {
  final ValueChanged<int> onSectionSelected;
  const HomeDashboardScreen({super.key, required this.onSectionSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channels = ref.watch(allChannelsProvider);
    final movies = ref.watch(allMoviesProvider);
    final series = ref.watch(allSeriesProvider);
    final history = ref.watch(watchHistoryProvider);
    final filmList = movies.valueOrNull ?? const <Movie>[];
    final featured = filmList.isEmpty ? null : filmList.first;
    final continuing = (history.valueOrNull ?? const <WatchHistoryEntry>[])
        .where(
          (e) =>
              e.contentType != WatchableType.channel &&
              e.positionSeconds > 0 &&
              e.progressFraction < .95,
        )
        .take(12)
        .toList();
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final inset = constraints.maxWidth < 600 ? 16.0 : 32.0;
        return ListView(
          key: const PageStorageKey('home-discover'),
          padding: EdgeInsets.fromLTRB(inset, 20, inset, 32),
          children: [
            _FeaturedBanner(
              movie: featured,
              onPlay: () {
                if (featured != null) {
                  _playMovie(context, featured);
                } else {
                  onSectionSelected(7);
                }
              },
              onBrowse: () => onSectionSelected(2),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, box) {
                final width = box.maxWidth < 560
                    ? box.maxWidth
                    : (box.maxWidth - 24) / 3;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _QuickAccess(
                      key: const ValueKey('live-tv-card'),
                      width: width,
                      icon: Icons.live_tv_rounded,
                      title: 'TV ao vivo',
                      caption: _count(channels, 'canais'),
                      onTap: () => onSectionSelected(1),
                    ),
                    _QuickAccess(
                      key: const ValueKey('movies-card'),
                      width: width,
                      icon: Icons.movie_outlined,
                      title: 'Filmes',
                      caption: _count(movies, 'filmes'),
                      onTap: () => onSectionSelected(2),
                    ),
                    _QuickAccess(
                      key: const ValueKey('series-card'),
                      width: width,
                      icon: Icons.video_library_outlined,
                      title: 'Séries',
                      caption: _count(series, 'séries'),
                      onTap: () => onSectionSelected(3),
                    ),
                  ],
                );
              },
            ),
            if (continuing.isNotEmpty)
              _Shelf(
                title: 'Continue assistindo',
                caption: 'Sua próxima cena está aqui.',
                onSeeAll: () => onSectionSelected(5),
                count: continuing.length,
                builder: (context, i) {
                  final entry = continuing[i];
                  return ContentCard(
                    title: entry.title,
                    imageUrl: entry.posterUrl,
                    progress: entry.progressFraction,
                    subtitle:
                        '${Duration(seconds: entry.positionSeconds).inMinutes} min assistidos',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PlayerScreen(
                          title: entry.title,
                          streamUrl: entry.streamUrl,
                          contentId: entry.contentId,
                          contentType: entry.contentType,
                          posterUrl: entry.posterUrl,
                          startPositionSeconds: entry.positionSeconds,
                        ),
                      ),
                    ),
                  );
                },
              ),
            if (filmList.isNotEmpty)
              _Shelf(
                title: 'Uma boa sessão começa aqui',
                caption: 'Explore os filmes da sua biblioteca.',
                onSeeAll: () => onSectionSelected(2),
                count: filmList.take(16).length,
                builder: (context, i) => ContentCard(
                  title: filmList[i].title,
                  imageUrl: filmList[i].posterUrl,
                  subtitle: filmList[i].category ?? 'Filme',
                  onTap: () => _playMovie(context, filmList[i]),
                ),
              ),
            if (series.valueOrNull?.isNotEmpty ?? false)
              _Shelf(
                title: 'Encontre sua próxima série',
                caption: 'Histórias para acompanhar no seu ritmo.',
                onSeeAll: () => onSectionSelected(3),
                count: series.valueOrNull!.take(16).length,
                builder: (context, i) {
                  final item = series.valueOrNull![i];
                  return ContentCard(
                    title: item.title,
                    imageUrl: item.posterUrl,
                    subtitle: item.category ?? 'Série',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SeriesDetailScreen(series: item),
                      ),
                    ),
                  );
                },
              ),
            if (channels.valueOrNull?.isNotEmpty ?? false)
              _Shelf(
                title: 'Sintonize agora',
                caption: 'Seus canais, a um toque de distância.',
                onSeeAll: () => onSectionSelected(1),
                count: channels.valueOrNull!.take(16).length,
                height: 190,
                width: 220,
                builder: (context, i) {
                  final channel = channels.valueOrNull![i];
                  return ContentCard(
                    title: channel.name,
                    imageUrl: channel.logoUrl,
                    subtitle: 'AO VIVO',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PlayerScreen(
                          title: channel.name,
                          streamUrl: channel.streamUrl,
                          contentId: channel.id,
                          contentType: WatchableType.channel,
                          posterUrl: channel.logoUrl,
                        ),
                      ),
                    ),
                  );
                },
              ),
            if (movies.isLoading || channels.isLoading || series.isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: LinearProgressIndicator(),
              ),
            if (movies.hasError || channels.hasError || series.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  'Parte da biblioteca não pôde ser carregada. Confira suas listas.',
                  style: TextStyle(color: colors.error),
                ),
              ),
            const SizedBox(height: 28),
            Text(
              'SUA BIBLIOTECA. SEU MOMENTO.',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 11,
                letterSpacing: 2,
              ),
            ),
          ],
        );
      },
    );
  }

  static String _count<T>(AsyncValue<List<T>> value, String label) =>
      value.when(
        data: (items) => '${items.length} ${items.length == 1 ? (label == 'canais' ? 'canal' : label.substring(0, label.length - 1)) : label}',
        loading: () => 'Carregando…',
        error: (_, _) => 'Indisponível',
      );

  static void _playMovie(BuildContext context, Movie movie) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlayerScreen(
          title: movie.title,
          streamUrl: movie.streamUrl,
          contentId: movie.id,
          contentType: WatchableType.movie,
          posterUrl: movie.posterUrl,
        ),
      ),
    );
  }
}

class _FeaturedBanner extends StatelessWidget {
  final Movie? movie;
  final VoidCallback onPlay;
  final VoidCallback onBrowse;
  const _FeaturedBanner({
    required this.movie,
    required this.onPlay,
    required this.onBrowse,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colors.surfaceContainerHigh,
                        colors.surface,
                        colors.primary.withValues(alpha: .22),
                      ],
                    ),
                  ),
                ),
              ),
              if (movie?.posterUrl?.isNotEmpty ?? false)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: compact ? 1 : .55,
                      child: Image.network(
                        movie!.posterUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors.surface,
                        colors.surface.withValues(alpha: compact ? .9 : .85),
                        colors.surface.withValues(alpha: .25),
                      ],
                      stops: const [0, .45, 1],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(compact ? 24 : 40),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: compact ? double.infinity : 580,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.play_circle_fill_rounded,
                            size: 16,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            movie == null
                                ? 'BEM-VINDO AO JOTAC'
                                : 'NA SUA BIBLIOTECA',
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text(
                        movie?.title ?? 'Seu cinema.\nDo seu jeito.',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontSize: compact ? 30 : 42,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        movie == null
                            ? 'Reúna suas listas e descubra filmes, séries e TV ao vivo em um só lugar.'
                            : (movie!.category ??
                                  'Prepare a pipoca e aproveite sua próxima sessão.'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: onPlay,
                            icon: Icon(
                              movie == null
                                  ? Icons.add
                                  : Icons.play_arrow_rounded,
                            ),
                            label: Text(
                              movie == null
                                  ? 'Conectar lista'
                                  : 'Assistir agora',
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: onBrowse,
                            icon: const Icon(Icons.grid_view_rounded, size: 18),
                            label: const Text('Explorar filmes'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickAccess extends StatelessWidget {
  final double width;
  final IconData icon;
  final String title;
  final String caption;
  final VoidCallback onTap;
  const _QuickAccess({
    super.key,
    required this.width,
    required this.icon,
    required this.title,
    required this.caption,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Icon(icon, color: colors.primary, size: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        caption,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Shelf extends StatelessWidget {
  final String title;
  final String caption;
  final VoidCallback onSeeAll;
  final int count;
  final IndexedWidgetBuilder builder;
  final double height;
  final double width;
  const _Shelf({
    required this.title,
    required this.caption,
    required this.onSeeAll,
    required this.count,
    required this.builder,
    this.height = 274,
    this.width = 164,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 30),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(onPressed: onSeeAll, child: const Text('Ver tudo')),
          ],
        ),
        Text(
          caption,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: height,
          child: ListView.separated(
            key: PageStorageKey(title),
            scrollDirection: Axis.horizontal,
            itemCount: count,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) =>
                SizedBox(width: width, child: builder(context, index)),
          ),
        ),
      ],
    ),
  );
}
