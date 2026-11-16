import 'package:flutter/material.dart';

class CatalogToolbar extends StatelessWidget {
  final bool showingMovies;
  final int movieCount;
  final int seriesCount;
  final VoidCallback onShowMovies;
  final VoidCallback onShowSeries;
  final ValueChanged<String> onSearchChanged;
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  const CatalogToolbar({
    super.key,
    required this.showingMovies,
    required this.movieCount,
    required this.seriesCount,
    required this.onShowMovies,
    required this.onShowSeries,
    required this.onSearchChanged,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SUA BIBLIOTECA',
            style: TextStyle(
              color: colors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  showingMovies ? 'Filmes' : 'Séries',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${showingMovies ? movieCount : seriesCount} títulos',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final search = TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: showingMovies
                      ? 'Buscar filmes…'
                      : 'Buscar séries…',
                ),
              );
              final category = DropdownButtonFormField<String>(
                key: ValueKey(
                  categories.contains(selectedCategory)
                      ? selectedCategory
                      : null,
                ),
                initialValue: categories.contains(selectedCategory)
                    ? selectedCategory
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.tune_rounded),
                ),
                hint: const Text('Todas as categorias'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todas as categorias'),
                  ),
                  for (final category in categories)
                    DropdownMenuItem(
                      value: category,
                      child: Text(category, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: onCategorySelected,
              );
              if (constraints.maxWidth < 560) {
                return Column(
                  children: [search, const SizedBox(height: 10), category],
                );
              }
              return Row(
                children: [
                  Expanded(child: search),
                  const SizedBox(width: 16),
                  SizedBox(width: 260, child: category),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text('Filmes ($movieCount)'),
                selected: showingMovies,
                onSelected: (_) => onShowMovies(),
              ),
              ChoiceChip(
                label: Text('Séries ($seriesCount)'),
                selected: !showingMovies,
                onSelected: (_) => onShowSeries(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
