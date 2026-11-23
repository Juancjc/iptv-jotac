import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/download_item.dart';
import '../models/movie.dart';
import '../models/watch_history_entry.dart';
import '../providers/database_provider.dart';
import '../providers/download_providers.dart';
import '../providers/playlist_providers.dart';
import '../widgets/catalog_toolbar.dart';
import '../widgets/content_card.dart';
import '../widgets/empty_state.dart';
import 'player_screen.dart';

class MoviesScreen extends ConsumerStatefulWidget {
  final VoidCallback onShowMovies;
  final VoidCallback onShowSeries;

  const MoviesScreen({
    super.key,
    required this.onShowMovies,
    required this.onShowSeries,
  });

  @override
  ConsumerState<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends ConsumerState<MoviesScreen> {
  String _search = '';
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final moviesAsync = ref.watch(allMoviesProvider);
    final seriesAsync = ref.watch(allSeriesProvider);

    return moviesAsync.when(
      data: (movies) {
        final categories = _categoriesFor(movies);
        final filtered = movies.where((movie) {
          final matchesSearch =
              _search.isEmpty || movie.title.toLowerCase().contains(_search);
          final matchesCategory =
              _selectedCategory == null ||
              _categoryOf(movie) == _selectedCategory;
          return matchesSearch && matchesCategory;
        }).toList();

        return Column(
          children: [
            CatalogToolbar(
              showingMovies: true,
              movieCount: movies.length,
              seriesCount: seriesAsync.valueOrNull?.length ?? 0,
              onShowMovies: widget.onShowMovies,
              onShowSeries: widget.onShowSeries,
              onSearchChanged: (value) =>
                  setState(() => _search = value.trim().toLowerCase()),
              categories: categories,
              selectedCategory: _selectedCategory,
              onCategorySelected: (value) =>
                  setState(() => _selectedCategory = value),
            ),
            Expanded(child: _buildGrid(context, filtered)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Erro ao carregar filmes',
        message: error.toString(),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<Movie> movies) {
    if (movies.isEmpty) {
      return const EmptyState(
        icon: Icons.movie_outlined,
        title: 'Nenhum filme encontrado',
        message: 'Tente mudar a busca ou a categoria selecionada.',
      );
    }

    return GridView.builder(
      key: const PageStorageKey('movies-grid'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 190,
        childAspectRatio: .62,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        return ContentCard(
          key: ValueKey(movie.id),
          title: movie.title,
          imageUrl: movie.posterUrl,
          isFavorite: movie.isFavorite,
          onToggleFavorite: () => ref
              .read(playlistRepositoryProvider)
              .toggleMovieFavorite(movie.id, !movie.isFavorite),
          onDownload: () {
            ref
                .read(downloadsProvider.notifier)
                .enqueue(
                  sourceUrl: movie.streamUrl,
                  title: movie.title,
                  contentType: DownloadContentType.movie,
                );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '"${movie.title}" adicionado a fila de downloads',
                ),
              ),
            );
          },
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PlayerScreen(
                title: movie.title,
                streamUrl: movie.streamUrl,
                contentId: movie.id,
                contentType: WatchableType.movie,
                posterUrl: movie.posterUrl,
              ),
            ),
          ),
        );
      },
    );
  }

  List<String> _categoriesFor(List<Movie> movies) {
    final categories = movies.map(_categoryOf).toSet().toList()
      ..sort((a, b) => a.compareTo(b));
    return categories;
  }

  String _categoryOf(Movie movie) {
    final category = movie.category?.trim();
    return category == null || category.isEmpty ? 'Sem categoria' : category;
  }
}
