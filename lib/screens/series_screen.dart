import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/series.dart' as domain;
import '../providers/database_provider.dart';
import '../providers/playlist_providers.dart';
import '../widgets/catalog_toolbar.dart';
import '../widgets/content_card.dart';
import '../widgets/empty_state.dart';
import 'series_detail_screen.dart';

class SeriesScreen extends ConsumerStatefulWidget {
  final VoidCallback onShowMovies;
  final VoidCallback onShowSeries;

  const SeriesScreen({
    super.key,
    required this.onShowMovies,
    required this.onShowSeries,
  });

  @override
  ConsumerState<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends ConsumerState<SeriesScreen> {
  String _search = '';
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final seriesAsync = ref.watch(allSeriesProvider);
    final moviesAsync = ref.watch(allMoviesProvider);

    return seriesAsync.when(
      data: (seriesList) {
        final categories = _categoriesFor(seriesList);
        final filtered = seriesList.where((series) {
          final matchesSearch =
              _search.isEmpty || series.title.toLowerCase().contains(_search);
          final matchesCategory =
              _selectedCategory == null ||
              _categoryOf(series) == _selectedCategory;
          return matchesSearch && matchesCategory;
        }).toList();

        return Column(
          children: [
            CatalogToolbar(
              showingMovies: false,
              movieCount: moviesAsync.valueOrNull?.length ?? 0,
              seriesCount: seriesList.length,
              onShowMovies: widget.onShowMovies,
              onShowSeries: widget.onShowSeries,
              onSearchChanged: (value) =>
                  setState(() => _search = value.trim().toLowerCase()),
              categories: categories,
              selectedCategory: _selectedCategory,
              onCategorySelected: (value) =>
                  setState(() => _selectedCategory = value),
            ),
            Expanded(child: _buildGrid(filtered)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Erro ao carregar series',
        message: error.toString(),
      ),
    );
  }

  Widget _buildGrid(List<domain.Series> seriesList) {
    if (seriesList.isEmpty) {
      return const EmptyState(
        icon: Icons.video_library_outlined,
        title: 'Nenhuma serie encontrada',
        message: 'Tente mudar a busca ou a categoria selecionada.',
      );
    }

    return GridView.builder(
      key: const PageStorageKey('series-grid'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 190,
        childAspectRatio: .62,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: seriesList.length,
      itemBuilder: (context, index) {
        final series = seriesList[index];
        return ContentCard(
          key: ValueKey(series.id),
          title: series.title,
          imageUrl: series.posterUrl,
          isFavorite: series.isFavorite,
          onToggleFavorite: () => ref
              .read(playlistRepositoryProvider)
              .toggleSeriesFavorite(series.id, !series.isFavorite),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SeriesDetailScreen(series: series),
            ),
          ),
        );
      },
    );
  }

  List<String> _categoriesFor(List<domain.Series> seriesList) {
    final categories = seriesList.map(_categoryOf).toSet().toList()
      ..sort((a, b) => a.compareTo(b));
    return categories;
  }

  String _categoryOf(domain.Series series) {
    final category = series.category?.trim();
    return category == null || category.isEmpty ? 'Sem categoria' : category;
  }
}
