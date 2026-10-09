import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/database_provider.dart';
import '../providers/playlist_providers.dart';
import '../widgets/content_card.dart';
import '../widgets/empty_state.dart';
import 'series_detail_screen.dart';

class SeriesScreen extends ConsumerWidget {
  const SeriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesAsync = ref.watch(seriesProvider);

    return seriesAsync.when(
      data: (seriesList) {
        if (seriesList.isEmpty) {
          return const EmptyState(
            icon: Icons.video_library_outlined,
            title: 'Nenhuma serie encontrada',
            message: 'Adicione uma lista com conteudo de series para ve-las aqui.',
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
          itemCount: seriesList.length,
          itemBuilder: (context, index) {
            final series = seriesList[index];
            return ContentCard(
              title: series.title,
              subtitle: series.category,
              imageUrl: series.posterUrl,
              isFavorite: series.isFavorite,
              onToggleFavorite: () =>
                  ref.read(playlistRepositoryProvider).toggleSeriesFavorite(series.id, !series.isFavorite),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => SeriesDetailScreen(series: series),
              )),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          EmptyState(icon: Icons.error_outline, title: 'Erro ao carregar series', message: error.toString()),
    );
  }
}
