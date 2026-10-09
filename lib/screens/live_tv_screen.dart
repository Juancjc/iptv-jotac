import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/watch_history_entry.dart';
import '../providers/database_provider.dart';
import '../providers/playlist_providers.dart';
import '../widgets/content_card.dart';
import '../widgets/empty_state.dart';
import 'player_screen.dart';

class LiveTvScreen extends ConsumerWidget {
  const LiveTvScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(channelsProvider);

    return channelsAsync.when(
      data: (channels) {
        if (channels.isEmpty) {
          return const EmptyState(
            icon: Icons.live_tv_outlined,
            title: 'Nenhum canal encontrado',
            message: 'Adicione uma lista M3U ou Xtream Codes para ver canais ao vivo aqui.',
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            mainAxisExtent: 160,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: channels.length,
          itemBuilder: (context, index) {
            final channel = channels[index];
            return ContentCard(
              title: channel.name,
              subtitle: channel.category,
              imageUrl: channel.logoUrl,
              isFavorite: channel.isFavorite,
              onToggleFavorite: () =>
                  ref.read(playlistRepositoryProvider).toggleChannelFavorite(channel.id, !channel.isFavorite),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PlayerScreen(
                  title: channel.name,
                  streamUrl: channel.streamUrl,
                  contentId: channel.id,
                  contentType: WatchableType.channel,
                  posterUrl: channel.logoUrl,
                ),
              )),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          EmptyState(icon: Icons.error_outline, title: 'Erro ao carregar canais', message: error.toString()),
    );
  }
}
