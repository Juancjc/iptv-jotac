import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/download_item.dart';
import '../models/series.dart';
import '../models/watch_history_entry.dart';
import '../providers/database_provider.dart';
import '../providers/download_providers.dart';
import '../providers/playlist_providers.dart';
import '../widgets/empty_state.dart';
import 'player_screen.dart';

class SeriesDetailScreen extends ConsumerWidget {
  final Series series;

  const SeriesDetailScreen({super.key, required this.series});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodesFuture = ref.watch(_episodesFutureProvider(series.id));

    return Scaffold(
      appBar: AppBar(title: Text(series.title)),
      body: episodesFuture.when(
        data: (episodes) {
          if (episodes.isEmpty) {
            return const EmptyState(
              icon: Icons.video_library_outlined,
              title: 'Nenhum episodio encontrado',
            );
          }
          final bySeason = <int, List<Episode>>{};
          for (final ep in episodes) {
            bySeason.putIfAbsent(ep.seasonNumber, () => []).add(ep);
          }
          final seasons = bySeason.keys.toList()..sort();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final season in seasons) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Temporada $season',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                for (final episode
                    in bySeason[season]!..sort(
                      (a, b) => a.episodeNumber.compareTo(b.episodeNumber),
                    ))
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text('${episode.episodeNumber}'),
                      ),
                      title: Text(episode.title),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.download_outlined),
                            tooltip: 'Baixar episodio',
                            onPressed: () {
                              ref
                                  .read(downloadsProvider.notifier)
                                  .enqueue(
                                    sourceUrl: episode.streamUrl,
                                    title:
                                        '${series.title} - S${episode.seasonNumber}E${episode.episodeNumber}',
                                    contentType: DownloadContentType.episode,
                                  );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Episodio adicionado a fila de downloads',
                                  ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.play_arrow),
                            tooltip: 'Assistir',
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PlayerScreen(
                                  title:
                                      '${series.title} - S${episode.seasonNumber}E${episode.episodeNumber}',
                                  streamUrl: episode.streamUrl,
                                  contentId: episode.id,
                                  contentType: WatchableType.episode,
                                  posterUrl: series.posterUrl,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Erro ao carregar episodios',
          message: error.toString(),
        ),
      ),
    );
  }
}

final _episodesFutureProvider = FutureProvider.family<List<Episode>, String>((
  ref,
  seriesId,
) async {
  final repo = ref.watch(playlistRepositoryProvider);
  final seriesList = await ref.watch(seriesProvider.future);
  final series = seriesList.firstWhere((s) => s.id == seriesId);
  return repo.ensureEpisodesLoaded(series);
});
