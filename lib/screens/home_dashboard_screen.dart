import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/watch_history_entry.dart';
import '../providers/watch_history_providers.dart';
import '../widgets/empty_state.dart';
import 'player_screen.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(watchHistoryProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Continuar assistindo', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        historyAsync.when(
          data: (entries) {
            if (entries.isEmpty) {
              return const EmptyState(
                icon: Icons.history,
                title: 'Nada assistido ainda',
                message: 'O que voce assistir vai aparecer aqui para continuar depois de onde parou.',
              );
            }
            return SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: entries.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _ContinueWatchingCard(entry: entries[index]),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('Erro ao carregar historico: $error'),
        ),
      ],
    );
  }
}

class _ContinueWatchingCard extends StatelessWidget {
  final WatchHistoryEntry entry;
  const _ContinueWatchingCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PlayerScreen(
              title: entry.title,
              streamUrl: entry.streamUrl,
              contentId: entry.contentId,
              contentType: entry.contentType,
              posterUrl: entry.posterUrl,
              startPositionSeconds: entry.positionSeconds,
            ),
          )),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: entry.posterUrl != null
                    ? Image.network(entry.posterUrl!, fit: BoxFit.cover)
                    : const ColoredBox(color: Colors.black26, child: Icon(Icons.movie_outlined, size: 36)),
              ),
              LinearProgressIndicator(value: entry.progressFraction, minHeight: 3),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
