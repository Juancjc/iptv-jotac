import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/download_item.dart';
import '../models/watch_history_entry.dart';
import '../providers/database_provider.dart';
import '../providers/download_providers.dart';
import '../providers/playlist_providers.dart';
import '../widgets/content_card.dart';
import '../widgets/empty_state.dart';
import 'player_screen.dart';

class MoviesScreen extends ConsumerWidget {
  const MoviesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moviesAsync = ref.watch(moviesProvider);

    return moviesAsync.when(
      data: (movies) {
        if (movies.isEmpty) {
          return const EmptyState(
            icon: Icons.movie_outlined,
            title: 'Nenhum filme encontrado',
            message: 'Adicione uma lista com conteudo VOD para ver filmes aqui.',
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            mainAxisExtent: 260,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: movies.length,
          itemBuilder: (context, index) {
            final movie = movies[index];
            return ContentCard(
              title: movie.title,
              subtitle: movie.category,
              imageUrl: movie.posterUrl,
              isFavorite: movie.isFavorite,
              onToggleFavorite: () =>
                  ref.read(playlistRepositoryProvider).toggleMovieFavorite(movie.id, !movie.isFavorite),
              onDownload: () {
                ref.read(downloadsProvider.notifier).enqueue(
                      sourceUrl: movie.streamUrl,
                      title: movie.title,
                      contentType: DownloadContentType.movie,
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"${movie.title}" adicionado a fila de downloads')),
                );
              },
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PlayerScreen(
                  title: movie.title,
                  streamUrl: movie.streamUrl,
                  contentId: movie.id,
                  contentType: WatchableType.movie,
                  posterUrl: movie.posterUrl,
                ),
              )),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          EmptyState(icon: Icons.error_outline, title: 'Erro ao carregar filmes', message: error.toString()),
    );
  }
}
