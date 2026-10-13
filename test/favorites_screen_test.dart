import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_jotac/models/movie.dart';
import 'package:iptv_jotac/models/series.dart' as domain;
import 'package:iptv_jotac/models/watch_history_entry.dart';
import 'package:iptv_jotac/providers/playlist_providers.dart';
import 'package:iptv_jotac/providers/watch_history_providers.dart';
import 'package:iptv_jotac/screens/favorites_screen.dart';

void main() {
  testWidgets('shows favorite movies, favorite series and saved playback position', (tester) async {
    const favoriteMovie = Movie(
      id: 'movie-favorite',
      playlistId: 'playlist',
      title: 'Filme favorito',
      streamUrl: 'https://example.com/favorite.mp4',
      isFavorite: true,
    );
    const regularMovie = Movie(
      id: 'movie-regular',
      playlistId: 'playlist',
      title: 'Filme comum',
      streamUrl: 'https://example.com/regular.mp4',
    );
    const favoriteSeries = domain.Series(
      id: 'series-favorite',
      playlistId: 'playlist',
      title: 'Serie favorita',
      isFavorite: true,
    );
    final history = WatchHistoryEntry(
      id: 'history',
      contentId: 'episode-4',
      contentType: WatchableType.episode,
      title: 'Serie exemplo - S1E4',
      streamUrl: 'https://example.com/episode-4.mp4',
      positionSeconds: 2535,
      durationSeconds: 6000,
      lastWatchedAt: DateTime(2026, 10, 12),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allMoviesProvider.overrideWith((ref) => Stream.value([favoriteMovie, regularMovie])),
          allSeriesProvider.overrideWith((ref) => Stream.value([favoriteSeries])),
          watchHistoryProvider.overrideWith((ref) => Stream.value([history])),
        ],
        child: const MaterialApp(home: Scaffold(body: FavoritesScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ultimos assistidos'), findsOneWidget);
    expect(find.text('Serie exemplo - S1E4'), findsOneWidget);
    expect(find.text('Parou em 42:15 de 1:40:00'), findsOneWidget);
    expect(find.text('Filme favorito'), findsOneWidget);
    expect(find.text('Filme comum'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    expect(find.text('Serie favorita'), findsOneWidget);
  });
}
