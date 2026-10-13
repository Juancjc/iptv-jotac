import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/movie.dart';
import '../models/series.dart' as domain;
import '../models/watch_history_entry.dart';
import '../providers/database_provider.dart';
import '../providers/playlist_providers.dart';
import '../providers/watch_history_providers.dart';
import '../widgets/content_card.dart';
import 'player_screen.dart';
import 'series_detail_screen.dart';

/// Brings together saved titles and resumable VOD playback in one place.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moviesAsync = ref.watch(allMoviesProvider);
    final seriesAsync = ref.watch(allSeriesProvider);
    final historyAsync = ref.watch(watchHistoryProvider);

    final favoriteMovies = (moviesAsync.valueOrNull ?? const <Movie>[]).where((movie) => movie.isFavorite).toList();
    final favoriteSeries = (seriesAsync.valueOrNull ?? const <domain.Series>[])
        .where((series) => series.isFavorite)
        .toList();
    final vodHistory = (historyAsync.valueOrNull ?? const <WatchHistoryEntry>[])
        .where((entry) => entry.contentType != WatchableType.channel && entry.positionSeconds > 0)
        .toList();
    final recent = vodHistory.take(12).toList();
    final historyByContentId = <String, WatchHistoryEntry>{for (final entry in vodHistory) entry.contentId: entry};
    final historyByStreamUrl = <String, WatchHistoryEntry>{for (final entry in vodHistory) entry.streamUrl: entry};

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text('Favoritos', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
          'Seus filmes e series salvos e o ponto onde voce parou.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 28),
        _ContentSection(
          icon: Icons.play_circle_outline,
          title: 'Ultimos assistidos',
          emptyMessage: 'Comece a assistir a um filme ou episodio para ele aparecer aqui.',
          isLoading: historyAsync.isLoading && !historyAsync.hasValue,
          error: historyAsync.error,
          children: [
            for (final entry in recent)
              ContentCard(
                title: entry.title,
                imageUrl: entry.posterUrl,
                subtitle: _progressLabel(entry),
                progress: _progress(entry),
                onTap: () => _openHistoryEntry(context, entry),
              ),
          ],
        ),
        const SizedBox(height: 32),
        _ContentSection(
          icon: Icons.movie_outlined,
          title: 'Filmes favoritos',
          emptyMessage: 'Use o coracao em um filme para salva-lo aqui.',
          isLoading: moviesAsync.isLoading && !moviesAsync.hasValue,
          error: moviesAsync.error,
          children: favoriteMovies.map((movie) {
            final history = historyByContentId[movie.id] ?? historyByStreamUrl[movie.streamUrl];
            return ContentCard(
              title: movie.title,
              imageUrl: movie.posterUrl,
              subtitle: history == null ? null : _progressLabel(history),
              progress: history == null ? null : _progress(history),
              isFavorite: true,
              onToggleFavorite: () => ref.read(playlistRepositoryProvider).toggleMovieFavorite(movie.id, false),
              onTap: () => _openMovie(context, movie, history),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        _ContentSection(
          icon: Icons.video_library_outlined,
          title: 'Series favoritas',
          emptyMessage: 'Use o coracao em uma serie para salva-la aqui.',
          isLoading: seriesAsync.isLoading && !seriesAsync.hasValue,
          error: seriesAsync.error,
          children: [
            for (final series in favoriteSeries)
              ContentCard(
                title: series.title,
                imageUrl: series.posterUrl,
                isFavorite: true,
                onToggleFavorite: () => ref.read(playlistRepositoryProvider).toggleSeriesFavorite(series.id, false),
                onTap: () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SeriesDetailScreen(series: series))),
              ),
          ],
        ),
      ],
    );
  }

  static void _openMovie(BuildContext context, Movie movie, WatchHistoryEntry? history) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          title: movie.title,
          streamUrl: movie.streamUrl,
          contentId: movie.id,
          contentType: WatchableType.movie,
          posterUrl: movie.posterUrl,
          startPositionSeconds: history == null ? 0 : _resumePosition(history),
        ),
      ),
    );
  }

  static void _openHistoryEntry(BuildContext context, WatchHistoryEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          title: entry.title,
          streamUrl: entry.streamUrl,
          contentId: entry.contentId,
          contentType: entry.contentType,
          posterUrl: entry.posterUrl,
          startPositionSeconds: _resumePosition(entry),
        ),
      ),
    );
  }

  static int _resumePosition(WatchHistoryEntry entry) {
    final duration = entry.durationSeconds;
    if (duration != null && duration > 0 && entry.positionSeconds / duration >= .95) {
      return 0;
    }
    return entry.positionSeconds;
  }

  static double? _progress(WatchHistoryEntry entry) {
    final duration = entry.durationSeconds;
    if (duration == null || duration <= 0) return null;
    return (entry.positionSeconds / duration).clamp(0.0, 1.0);
  }

  static String _progressLabel(WatchHistoryEntry entry) {
    final duration = entry.durationSeconds;
    if (duration != null && duration > 0) {
      final progress = entry.positionSeconds / duration;
      if (progress >= .95) return 'Assistido';
      return 'Parou em ${_formatDuration(entry.positionSeconds)} de ${_formatDuration(duration)}';
    }
    return 'Parou em ${_formatDuration(entry.positionSeconds)}';
  }

  static String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}

class _ContentSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String emptyMessage;
  final bool isLoading;
  final Object? error;
  final List<Widget> children;

  const _ContentSection({
    required this.icon,
    required this.title,
    required this.emptyMessage,
    required this.isLoading,
    required this.error,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, color: colors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            ),
            if (children.isNotEmpty)
              Text(
                '${children.length}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: colors.onSurfaceVariant),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (isLoading)
          const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
        else if (error != null)
          _SectionMessage(icon: Icons.error_outline, message: 'Nao foi possivel carregar esta secao.')
        else if (children.isEmpty)
          _SectionMessage(icon: Icons.inbox_outlined, message: emptyMessage)
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 190,
              childAspectRatio: .62,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: children.length,
            itemBuilder: (_, index) => children[index],
          ),
      ],
    );
  }
}

class _SectionMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _SectionMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: colors.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}
