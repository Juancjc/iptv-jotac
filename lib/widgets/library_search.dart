import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/watch_history_entry.dart';
import '../providers/database_provider.dart';
import '../providers/playlist_providers.dart';
import '../screens/player_screen.dart';
import '../screens/series_detail_screen.dart';

void showLibrarySearch(BuildContext context) {
  showDialog<void>(context: context, builder: (_) => const _LibrarySearch());
}

class _LibrarySearch extends ConsumerStatefulWidget {
  const _LibrarySearch();
  @override
  ConsumerState<_LibrarySearch> createState() => _LibrarySearchState();
}

class _LibrarySearchState extends ConsumerState<_LibrarySearch> {
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(playlistRepositoryProvider);
    final playlistId = ref.watch(selectedPlaylistIdProvider);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 650),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Buscar canais, filmes e séries…',
                      ),
                      onChanged: (value) {
                        _debounce?.cancel();
                        _debounce = Timer(
                          const Duration(milliseconds: 350),
                          () {
                            if (mounted) setState(() => _query = value.trim());
                          },
                        );
                      },
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _query.length < 2
                  ? const Center(child: Text('Digite pelo menos 2 caracteres.'))
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        const Text(
                          'Até 20 resultados por categoria • biblioteca salva',
                        ),
                        _Results(
                          title: 'Canais',
                          stream: repo.watchChannels(
                            playlistId: playlistId,
                            searchQuery: _query,
                            limit: 20,
                          ),
                          tile: (item) => ListTile(
                            leading: const Icon(Icons.live_tv),
                            title: Text(item.name),
                            onTap: () => _play(
                              item.name,
                              item.id,
                              item.streamUrl,
                              WatchableType.channel,
                            ),
                          ),
                        ),
                        _Results(
                          title: 'Filmes',
                          stream: repo.watchMovies(
                            playlistId: playlistId,
                            searchQuery: _query,
                            limit: 20,
                          ),
                          tile: (item) => ListTile(
                            leading: const Icon(Icons.movie_outlined),
                            title: Text(item.title),
                            onTap: () => _play(
                              item.title,
                              item.id,
                              item.streamUrl,
                              WatchableType.movie,
                            ),
                          ),
                        ),
                        _Results(
                          title: 'Séries',
                          stream: repo.watchSeries(
                            playlistId: playlistId,
                            searchQuery: _query,
                            limit: 20,
                          ),
                          tile: (item) => ListTile(
                            leading: const Icon(Icons.video_library_outlined),
                            title: Text(item.title),
                            onTap: () {
                              final navigator = Navigator.of(context);
                              navigator.pop();
                              navigator.push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      SeriesDetailScreen(series: item),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _play(String title, String id, String url, WatchableType type) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => PlayerScreen(
          title: title,
          contentId: id,
          streamUrl: url,
          contentType: type,
        ),
      ),
    );
  }
}

class _Results<T> extends StatelessWidget {
  final String title;
  final Stream<List<T>> stream;
  final Widget Function(T) tile;
  const _Results({
    required this.title,
    required this.stream,
    required this.tile,
  });

  @override
  Widget build(BuildContext context) => StreamBuilder<List<T>>(
    stream: stream,
    builder: (context, snapshot) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (snapshot.hasError)
          const Text('Não foi possível consultar a biblioteca.')
        else if (!snapshot.hasData)
          const LinearProgressIndicator()
        else if (snapshot.data!.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Nenhum resultado.'),
          )
        else
          ...snapshot.data!.map(tile),
      ],
    ),
  );
}
