import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/watch_history_entry.dart';
import '../providers/watch_history_providers.dart';
import '../widgets/content_card.dart';
import '../widgets/empty_state.dart';
import 'player_screen.dart';

class WatchHistoryScreen extends ConsumerWidget {
  const WatchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(watchHistoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ultimos assistidos',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Continue seus filmes e episodios exatamente de onde parou.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Expanded(
          child: historyAsync.when(
            data: (history) {
              final entries = history
                  .where((entry) => entry.contentType != WatchableType.channel && entry.positionSeconds > 0)
                  .toList();
              if (entries.isEmpty) {
                return const EmptyState(
                  icon: Icons.history_outlined,
                  title: 'Nenhum titulo assistido',
                  message: 'Comece a assistir a um filme ou episodio para ele aparecer aqui.',
                );
              }
              return GridView.builder(
                key: const PageStorageKey('watch-history-grid'),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 190,
                  childAspectRatio: .62,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return ContentCard(
                    title: entry.title,
                    imageUrl: entry.posterUrl,
                    subtitle: _progressLabel(entry),
                    progress: _progress(entry),
                    onTap: () => _openEntry(context, entry),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                EmptyState(icon: Icons.error_outline, title: 'Erro ao carregar historico', message: error.toString()),
          ),
        ),
      ],
    );
  }

  static void _openEntry(BuildContext context, WatchHistoryEntry entry) {
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
    if (duration != null && duration > 0 && entry.positionSeconds / duration >= .95) return 0;
    return entry.positionSeconds;
  }

  static double? _progress(WatchHistoryEntry entry) {
    final duration = entry.durationSeconds;
    if (duration == null || duration <= 0) return null;
    return entry.progressFraction;
  }

  static String _progressLabel(WatchHistoryEntry entry) {
    final duration = entry.durationSeconds;
    if (duration != null && duration > 0) {
      if (entry.progressFraction >= .95) return 'Assistido';
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
