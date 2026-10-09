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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 74,
          child: Row(
            children: [
              Expanded(
                child: _CatalogTab(
                  icon: Icons.movie_creation_outlined,
                  label: 'Filmes ($movieCount)',
                  selected: showingMovies,
                  onTap: onShowMovies,
                ),
              ),
              Expanded(
                child: _CatalogTab(
                  icon: Icons.video_library_outlined,
                  label: 'Series ($seriesCount)',
                  selected: !showingMovies,
                  onTap: onShowSeries,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: TextField(
                onChanged: onSearchChanged,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar...',
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 66,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = index == 0 ? null : categories[index - 1];
              final selected = selectedCategory == category;
              return FilterChip(
                selected: selected,
                showCheckmark: selected,
                label: Text(category ?? 'Todos'),
                onSelected: (_) => onCategorySelected(category),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CatalogTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CatalogTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? colors.primary : colors.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            Container(
              width: 94,
              height: 3,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    );
  }
}
